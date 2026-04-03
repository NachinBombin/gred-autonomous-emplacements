AddCSLuaFile("shared.lua")
include("shared.lua")

local SCAN    = "SCAN"
local MOVE    = "MOVE"
local ACTIVE  = "ACTIVE"
local RELEASE = "RELEASE"

-- Resolve gred_emp_base explicitly once, never via self.BaseClass
-- (self.BaseClass from a child entity resolves to THIS table, causing infinite recursion)
local function GredBase()
    local reg = scripted_ents.GetStored("gred_emp_base")
    return reg and (reg.t or reg)
end

function ENT:ShooterStillValid(ply, botmode)
    if not IsValid(ply) then return false end
    if ply == self then return botmode end
    if ply:IsPlayer() then
        return ply:Alive() and (
            not self.Seatable and
            ply:GetPos():DistToSqr(self:GetPos()) <= self.MaxUseDistance
            or self.Seatable
        )
    end
    return false
end

function ENT:FindBotTarget(botmode, target, ct)
    if self:GetShooter() ~= self then
        self:SetShooter(self)
        self.Owner = self.Owner or self
    end

    if not IsValid(target) then
        target = nil
        self.NextFindBot = self.NextFindBot or 0
        if self.NextFindBot < ct then
            self.NextFindBot = ct + 0.2
            local pos = self:LocalToWorld(self.TurretMuzzles[1].Pos)

            for _, v in ipairs(ents.FindInSphere(pos, self._npcBotScanRadius or 2000)) do
                if not IsValid(v) then continue end
                if not v:IsNPC() then continue end
                if not v:Alive() then continue end
                if v == self._npcGunner then continue end
                local ep = v:LocalToWorld(v:OBBCenter())
                local tr = util.QuickTrace(pos, ep - pos, self.Entities)
                if self:TargetTraceValid(tr, v) then
                    self:SetTarget(v)
                    target = v
                    break
                end
            end

            if not target and self:GetAttackPlayers() then
                for _, v in ipairs(player.GetAll()) do
                    if not IsValid(v) or not v:Alive() then continue end
                    local ep = v:LocalToWorld(v:OBBCenter())
                    local tr = util.QuickTrace(pos, ep - pos, self.Entities)
                    if self:TargetTraceValid(tr, v) then
                        self:SetTarget(v)
                        target = v
                        break
                    end
                end
            end
        end
    end

    return botmode, target
end

function ENT:Initialize()
    -- Call gred_emp_base:Initialize directly by name — NOT self.BaseClass (recurses)
    local base = GredBase()
    if base and base.Initialize then base.Initialize(self) end

    self._npcState      = SCAN
    self._npcGunner     = NULL
    self._nextScanTime  = 0
    self._nextThinkTime = 0
end

function ENT:FindGunner()
    local myPos  = self:GetPos()
    local radius = self.NPC_SCAN_RADIUS
    local best, bestDist = NULL, radius * radius

    for _, npc in ipairs(ents.FindInSphere(myPos, radius)) do
        if not IsValid(npc)  then continue end
        if not npc:IsNPC()   then continue end
        if not npc:Alive()   then continue end
        if npc._gredActiveEmplacement and IsValid(npc._gredActiveEmplacement) then continue end
        local d = myPos:DistToSqr(npc:GetPos())
        if d < bestDist then bestDist = d; best = npc end
    end

    return best
end

function ENT:Think()
    -- Call gred_emp_base:Think directly — NOT self.BaseClass (recurses)
    local base = GredBase()
    if base and base.Think then base.Think(self) end

    local ct = CurTime()
    if ct < self._nextThinkTime then return end
    self._nextThinkTime = ct + 0.1

    local state = self._npcState
    local npc   = self._npcGunner

    if state == SCAN then
        if self:GetBotMode() then self:SetBotMode(false) end
        if ct < self._nextScanTime then return end
        self._nextScanTime = ct + self.NPC_SCAN_INTERVAL
        local found = self:FindGunner()
        if IsValid(found) then
            self._npcGunner              = found
            found._gredActiveEmplacement = self
            self._npcState               = MOVE
        end
        return
    end

    if not IsValid(npc) or not npc:Alive() then
        self._npcState = RELEASE
    end

    if state == MOVE then
        if not IsValid(npc) then self._npcState = SCAN; return end
        local dist = self:GetPos():Distance(npc:GetPos())
        if dist <= self.NPC_USE_DISTANCE then
            local ang = (self:GetPos() - npc:GetPos()):Angle()
            ang.p = 0
            npc:SetAngles(ang)
            npc:SetSchedule(SCHED_IDLE_STAND)
            self:SetBotMode(true)
            self._npcState = ACTIVE
        else
            if not self._nextMoveOrder or ct >= self._nextMoveOrder then
                self._nextMoveOrder = ct + 0.5
                npc:SetTarget(self)
                npc:SetLastPosition(self:GetPos())
                npc:SetSchedule(SCHED_MOVE_TO_GOALENT)
            end
        end
        return
    end

    if state == ACTIVE then
        if not IsValid(npc) or not npc:Alive() then
            self._npcState = RELEASE; return
        end
        local dist = self:GetPos():Distance(npc:GetPos())
        if dist > self.NPC_USE_DISTANCE * 2.5 then
            self:SetBotMode(false)
            self._npcState      = MOVE
            self._nextMoveOrder = 0
            return
        end
        npc:SetSchedule(SCHED_IDLE_STAND)
        local tgt = self:GetTarget()
        if IsValid(tgt) then
            local ang = (tgt:GetPos() - npc:GetPos()):Angle()
            ang.p = 0
            npc:SetAngles(ang)
        end
        return
    end

    if state == RELEASE then
        self:SetBotMode(false)
        if self:GetShooter() == self then self:SetShooter(nil) end
        if IsValid(npc) then
            npc._gredActiveEmplacement = nil
            npc:SetSchedule(SCHED_IDLE_WANDER)
        end
        self._npcGunner    = NULL
        self._npcState     = SCAN
        self._nextScanTime = ct + self.NPC_SCAN_INTERVAL
        return
    end
end

function ENT:OnRemove()
    local npc = self._npcGunner
    if IsValid(npc) then npc._gredActiveEmplacement = nil end
    if self:GetShooter() == self then self:SetShooter(nil) end
    local base = GredBase()
    if base and base.OnRemove then base.OnRemove(self) end
end
