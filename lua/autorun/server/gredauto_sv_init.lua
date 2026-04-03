-- gredauto_sv_init.lua
-- Server bootstrap for Gredwitch Autonomous Emplacements
-- Ghost-soldier method: a hidden npc_combine_s acts as the shooter proxy.
-- We override the minimum gred_emp_base functions so all ply:KeyDown / ply:IsPlayer
-- calls are safely intercepted. The emplacement fully controls targeting and firing.

if not SERVER then return end

-- Wait for gred_emp_base to be registered before hooking
hook.Add("InitPostEntity", "gredauto_patch_base", function()
    -- Safety: gredwitch base must exist
    if not scripted_ents.GetStored("gred_emp_base") then
        MsgC(Color(255,100,100), "[GredAuto] gred_emp_base not found. Is Gredwitch Emplacement Pack installed?\n")
        return
    end

    local BASE = scripted_ents.GetStored("gred_emp_base").t
    if not BASE then return end

    -- ----------------------------------------------------------------
    -- Patch 1: ShooterStillValid
    -- Original only accepts players. We also accept the ghost soldier.
    -- ----------------------------------------------------------------
    local orig_SSV = BASE.ShooterStillValid
    function BASE:ShooterStillValid(ply, botmode)
        if not IsValid(ply) then return false end
        -- Our ghost soldier
        if ply:IsNPC() and ply._gredAutoGhost then return true end
        -- Normal player path (unchanged)
        if orig_SSV then return orig_SSV(self, ply, botmode) end
        if not ply:IsPlayer() then return false end
        return ply:Alive() and (
            not self.Seatable and
            ply:GetPos():DistToSqr(self:GetPos()) <= self.MaxUseDistance
            or self.Seatable
        )
    end

    -- ----------------------------------------------------------------
    -- Patch 2: CalcAmmoType
    -- Called with ply every Think tick. ply:KeyDown crashes on NPC.
    -- When ply is our ghost, just do nothing (auto-fire handled elsewhere).
    -- ----------------------------------------------------------------
    local orig_CAT = BASE.CalcAmmoType
    function BASE:CalcAmmoType(ammo, IsReloading, ct, ply)
        if IsValid(ply) and ply:IsNPC() and ply._gredAutoGhost then
            -- Auto-reload for cannons: trigger reload when ammo hits 0
            if ammo == 0 and self.EmplacementType == "Cannon" then
                if not self:GetIsReloading() then
                    self:PlayAnim()
                end
            end
            return
        end
        if orig_CAT then orig_CAT(self, ammo, IsReloading, ct, ply) end
    end

    -- ----------------------------------------------------------------
    -- Patch 3: FindBotTarget
    -- Cannon type hard-disables bot mode. We skip that block.
    -- MG type tries self:GrabTurret(self) — which sets shooter = emplacement
    -- and then ShooterStillValid fails (not IsPlayer). We instead ensure
    -- the ghost is always the shooter.
    -- ----------------------------------------------------------------
    function BASE:FindBotTarget(botmode, target, ct)
        -- Ensure ghost soldier is the shooter
        local ghost = self._gredAutoGhost
        if not IsValid(ghost) then return botmode, target end

        if self:GetShooter() ~= ghost then
            self:SetShooter(ghost)
            self.Owner = ghost
        end

        -- Scan for a target
        if not IsValid(target) then
            target = nil
            self._gredNextScan = self._gredNextScan or 0
            if self._gredNextScan <= ct then
                self._gredNextScan = ct + 0.2
                local pos = self:LocalToWorld(self.TurretMuzzles[1].Pos)

                -- Players
                if self._gredAttackPlayers then
                    for _, v in ipairs(player.GetAll()) do
                        if IsValid(v) and v:Alive() then
                            local ep = v:LocalToWorld(v:OBBCenter())
                            if self:TargetTraceValid(util.QuickTrace(pos, ep - pos, self.Entities), v) then
                                self:SetTarget(v)
                                target = v
                                break
                            end
                        end
                    end
                end

                -- NPCs (enemy to combine = rebels, zombies, etc.)
                if not target then
                    for _, v in ipairs(ents.FindInSphere(pos, self._gredScanRadius or 2000)) do
                        if IsValid(v) and v:IsNPC() and v:Alive() and not v._gredAutoGhost then
                            local ep = v:LocalToWorld(v:OBBCenter())
                            if self:TargetTraceValid(util.QuickTrace(pos, ep - pos, self.Entities), v) then
                                self:SetTarget(v)
                                target = v
                                break
                            end
                        end
                    end
                end
            end
        end

        return botmode, target
    end

    -- ----------------------------------------------------------------
    -- Patch 4: GetShootAngles — ply branch runs ply:IsPlayer() / ply:EyeAngles()
    -- The botmode=true path is fine. When botmode=false but ply is ghost, skip.
    -- Since we always have botmode=true when ghost is shooter this is a safety net.
    -- ----------------------------------------------------------------
    local orig_GSA = BASE.GetShootAngles
    function BASE:GetShootAngles(ply, botmode, target)
        if IsValid(ply) and ply:IsNPC() and ply._gredAutoGhost then
            botmode = true  -- force botmode path
        end
        return orig_GSA(self, ply, botmode, target)
    end

    -- ----------------------------------------------------------------
    -- Patch 5: Think — attacking = ply:KeyDown(IN_ATTACK)
    -- We hook OnTick to inject the attack key when ghost is shooter.
    -- The ply:KeyDown line is in Think before OnTick, so we override Think.
    -- ----------------------------------------------------------------
    local orig_Think = BASE.Think
    function BASE:Think()
        -- If our ghost is the shooter, fake KeyDown(IN_ATTACK) via a flag
        local ghost = self._gredAutoGhost
        if IsValid(ghost) and self:GetBotMode() then
            ghost._gredFakeAttack = true
        end
        orig_Think(self)
    end

    MsgC(Color(100,255,100), "[GredAuto] gred_emp_base patched successfully.\n")
end)

-- ----------------------------------------------------------------
-- KeyDown intercept: NPC entities don't have KeyDown.
-- We add it to the NPC metatable if missing, checking our flag.
-- ----------------------------------------------------------------
hook.Add("InitPostEntity", "gredauto_npc_keydown", function()
    local NPC_meta = FindMetaTable("NPC")
    if not NPC_meta then return end

    if not NPC_meta._gredOrigKeyDown then
        -- NPCs don't have KeyDown natively, so no original to save.
        -- We just add a safe stub.
        NPC_meta.KeyDown = function(self, key)
            if self._gredAutoGhost then
                if key == IN_ATTACK and self._gredFakeAttack then
                    return true
                end
                return false
            end
            return false
        end

        NPC_meta.IsPlayer = NPC_meta.IsPlayer or function() return false end
        NPC_meta.GetPreviousWeapon = NPC_meta.GetPreviousWeapon or function() return NULL end
        NPC_meta.GetActiveWeapon   = NPC_meta.GetActiveWeapon   or function() return NULL end
        NPC_meta.DrawViewModel     = NPC_meta.DrawViewModel     or function() end
        NPC_meta.SetActiveWeapon   = NPC_meta.SetActiveWeapon   or function() end
        NPC_meta.Give              = NPC_meta.Give              or function() return NULL end
        NPC_meta.SelectWeapon      = NPC_meta.SelectWeapon      or function() end
        NPC_meta.StripWeapon       = NPC_meta.StripWeapon       or function() end
        NPC_meta.EyeAngles         = NPC_meta.EyeAngles         or function(self) return self:GetAngles() end
        NPC_meta.GetEyeTrace       = NPC_meta.GetEyeTrace       or function(self)
            return util.QuickTrace(self:GetPos(), self:GetForward() * 4096, self)
        end
        NPC_meta.CrosshairEnable   = NPC_meta.CrosshairEnable   or function() end
        NPC_meta.EnterVehicle      = NPC_meta.EnterVehicle      or function() end
        NPC_meta.ExitVehicle       = NPC_meta.ExitVehicle       or function() end
        NPC_meta.StripWeapon       = NPC_meta.StripWeapon       or function() end

        -- ActiveEmplacement tracking (normally on player table)
        -- NPCs already support arbitrary key assignment, so no stub needed.
    end

    MsgC(Color(100,255,100), "[GredAuto] NPC metatable stubs added.\n")
end)
