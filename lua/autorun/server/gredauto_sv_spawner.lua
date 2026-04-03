-- gredauto_sv_spawner.lua
if not SERVER then return end

local GHOST_MODEL    = "models/combine_soldier.mdl"
local SCAN_RADIUS    = 2000
local ATTACK_PLAYERS = true

local function GetEntTable(ent)
    -- GMod entities are userdata; their custom fields live in :GetTable()
    if not IsValid(ent) then return nil end
    return ent:GetTable()
end

local function EmpGet(ent, key)
    local t = GetEntTable(ent)
    return t and t[key]
end

local function EmpSet(ent, key, val)
    local t = GetEntTable(ent)
    if t then t[key] = val end
end

local function IsGredEmp(ent)
    if not IsValid(ent) then return false end
    local stored = scripted_ents.GetStored(ent:GetClass())
    if not stored then return false end
    local base = stored.t
    while base do
        if base.IsGredWitchEmplacement then return true end
        local bn = scripted_ents.GetStored(base.Base or "")
        if not bn then break end
        base = bn.t
    end
    return string.sub(ent:GetClass(), 1, 8) == "gred_emp"
end

local function SpawnGhost(emp)
    if not IsValid(emp) then return end
    if IsValid(EmpGet(emp, "_gredAutoGhost")) then return end

    local ghost = ents.Create("npc_combine_s")
    if not IsValid(ghost) then
        MsgC(Color(255,150,50), "[GredAuto] Failed to create ghost NPC for ", emp:GetClass(), "\n")
        return
    end

    ghost:SetModel(GHOST_MODEL)
    ghost:SetPos(emp:GetPos() + Vector(0, 0, -2000))
    ghost:SetAngles(emp:GetAngles())
    ghost:SetKeyValue("squadname", "gredauto_ghost")
    ghost:SetKeyValue("spawnflags", "512")
    ghost:Spawn()
    ghost:Activate()

    ghost:SetNoDraw(true)
    ghost:SetNotSolid(true)
    ghost:SetCollisionGroup(COLLISION_GROUP_NONE)
    ghost:SetMoveType(MOVETYPE_NONE)
    ghost:SetPos(emp:GetPos() + Vector(0, 0, -2000))

    local phys = ghost:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end

    -- Store flags on the entity's Lua table, not via rawget on userdata
    local gt = ghost:GetTable()
    gt._gredAutoGhost    = true
    gt._gredFakeAttack   = false
    gt._gredEmp          = emp
    gt.ActiveEmplacement = emp

    ghost:SetHealth(999999)
    ghost:SetMaxHealth(999999)

    local et = emp:GetTable()
    et._gredAutoGhost     = ghost
    et._gredScanRadius    = SCAN_RADIUS
    et._gredAttackPlayers = ATTACK_PLAYERS

    emp:SetBotMode(false)
    emp:SetShooter(ghost)
    et.Owner           = ghost
    gt.ActiveEmplacement = emp

    emp:SetBotMode(true)
    et.ShouldSetAngles = true

    MsgC(Color(100,200,255), "[GredAuto] Ghost spawned for ", emp:GetClass(), " (", tostring(emp:EntIndex()), ")\n")
end

hook.Add("OnEntityCreated", "gredauto_emplacement_init", function(ent)
    if not IsValid(ent) then return end
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if not IsGredEmp(ent) then return end
        if EmpGet(ent, "_gredAutoGhost") then return end
        SpawnGhost(ent)
    end)
end)

hook.Add("EntityRemoved", "gredauto_ghost_cleanup", function(ent)
    if not IsValid(ent) then return end
    -- ent is userdata; get its Lua table safely
    local t = ent:GetTable()
    if not t then return end

    local ghost = t._gredAutoGhost
    if ghost and IsValid(ghost) then
        ghost:Remove()
    end

    if t._gredAutoGhost then
        local emp = t._gredEmp
        if IsValid(emp) then
            local et = emp:GetTable()
            if et then
                et._gredAutoGhost = nil
                emp:SetBotMode(false)
                emp:SetShooter(nil)
            end
        end
    end
end)

hook.Add("OnNPCKilled", "gredauto_ghost_respawn", function(npc)
    if not IsValid(npc) then return end
    local t = npc:GetTable()
    if not t or not t._gredAutoGhost then return end
    local emp = t._gredEmp
    timer.Simple(0.5, function()
        if not IsValid(emp) then return end
        local et = emp:GetTable()
        if et then et._gredAutoGhost = nil end
        SpawnGhost(emp)
    end)
end)
