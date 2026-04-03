-- gredauto_sv_spawner.lua
-- Hooks into every gred_emp_base emplacement spawn.
-- Spawns a hidden ghost npc_combine_s, binds it to the emplacement,
-- enables bot mode, and manages cleanup.

if not SERVER then return end

local GHOST_MODEL   = "models/combine_soldier.mdl"
local SCAN_RADIUS   = 2000   -- how far the gun scans for enemies
local ATTACK_PLAYERS = true  -- set false to not shoot players

local function IsGredEmp(ent)
    if not IsValid(ent) then return false end
    local stored = scripted_ents.GetStored(ent:GetClass())
    if not stored then return false end
    -- Walk the inheritance chain looking for gred_emp_base
    local base = stored.t
    while base do
        if base.IsGredWitchEmplacement then return true end
        local bn = scripted_ents.GetStored(base.Base or "")
        if not bn then break end
        base = bn.t
    end
    -- Fallback: check class name prefix
    return string.sub(ent:GetClass(), 1, 8) == "gred_emp"
end

local function SpawnGhost(emp)
    if not IsValid(emp) then return end
    if IsValid(emp._gredAutoGhost) then return end  -- already has one

    local ghost = ents.Create("npc_combine_s")
    if not IsValid(ghost) then
        MsgC(Color(255,150,50), "[GredAuto] Failed to create ghost NPC for ", emp:GetClass(), "\n")
        return
    end

    ghost:SetModel(GHOST_MODEL)
    ghost:SetPos(emp:GetPos() + Vector(0, 0, -2000))  -- spawn underground, out of the way
    ghost:SetAngles(emp:GetAngles())
    ghost:SetKeyValue("squadname", "gredauto_ghost")  -- keep them in their own squad
    ghost:SetKeyValue("spawnflags", "512")            -- efficient
    ghost:Spawn()
    ghost:Activate()

    -- Hide and disable completely
    ghost:SetNoDraw(true)
    ghost:SetNotSolid(true)
    ghost:SetCollisionGroup(COLLISION_GROUP_NONE)
    ghost:SetMoveType(MOVETYPE_NONE)
    ghost:SetPos(emp:GetPos() + Vector(0, 0, -2000))

    -- Freeze physics
    local phys = ghost:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end

    -- Mark as our ghost
    ghost._gredAutoGhost     = true
    ghost._gredFakeAttack    = false
    ghost._gredEmp           = emp
    ghost.ActiveEmplacement  = emp  -- mirrors what player path sets

    -- Give it enough HP to never die in normal play
    ghost:SetHealth(999999)
    ghost:SetMaxHealth(999999)

    -- Link to emplacement
    emp._gredAutoGhost       = ghost
    emp._gredScanRadius      = SCAN_RADIUS
    emp._gredAttackPlayers   = ATTACK_PLAYERS

    -- Set the ghost as shooter and turn on bot mode
    -- GrabTurret sets shooter + Owner; we call it directly.
    -- botmode must already be false so GrabTurret's !botmode branch runs.
    emp:SetBotMode(false)
    emp:SetShooter(ghost)
    emp.Owner = ghost
    ghost.ActiveEmplacement = emp

    -- Now enable bot mode so Think uses FindBotTarget path
    emp:SetBotMode(true)
    emp.ShouldSetAngles = true

    MsgC(Color(100,200,255), "[GredAuto] Ghost spawned for ", emp:GetClass(), " (", tostring(emp:EntIndex()), ")\n")
end

hook.Add("OnEntityCreated", "gredauto_emplacement_init", function(ent)
    if not IsValid(ent) then return end
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if not IsGredEmp(ent) then return end
        if ent._gredAutoGhost then return end  -- already processed
        SpawnGhost(ent)
    end)
end)

hook.Add("EntityRemoved", "gredauto_ghost_cleanup", function(ent)
    if not IsValid(ent) then return end
    -- If an emplacement is removed, kill its ghost
    local ghost = rawget(ent, "_gredAutoGhost")
    if ghost and IsValid(ghost) then
        ghost:Remove()
    end
    -- If a ghost NPC is removed externally, clean up the emplacement ref
    if ent._gredAutoGhost and IsValid(ent._gredEmp) then
        ent._gredEmp._gredAutoGhost = nil
        ent._gredEmp:SetBotMode(false)
        ent._gredEmp:SetShooter(nil)
    end
end)

-- Respawn ghost if it somehow dies (e.g. map explosion)
hook.Add("OnNPCKilled", "gredauto_ghost_respawn", function(npc)
    if not npc._gredAutoGhost then return end
    local emp = npc._gredEmp
    timer.Simple(0.5, function()
        if not IsValid(emp) then return end
        emp._gredAutoGhost = nil
        SpawnGhost(emp)
    end)
end)
