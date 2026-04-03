-- gredauto_sv_spawner.lua
if not SERVER then return end

local GHOST_MODEL    = "models/combine_soldier.mdl"
local SCAN_RADIUS    = 2000
local ATTACK_PLAYERS = true

-- Safe field access: only scripted entities have a Lua backing table
local function EntGet(ent, key)
    if not IsValid(ent) then return nil end
    local stored = scripted_ents.GetStored(ent:GetClass())
    if not stored then return nil end
    local t = ent:GetTable()
    return t and t[key]
end

local function EntSet(ent, key, val)
    if not IsValid(ent) then return end
    local stored = scripted_ents.GetStored(ent:GetClass())
    if not stored then return end
    local t = ent:GetTable()
    if t then t[key] = val end
end

local function IsGredEmp(ent)
    if not IsValid(ent) then return false end
    -- Fast path: class prefix check first (cheap)
    if string.sub(ent:GetClass(), 1, 8) ~= "gred_emp" then return false end
    return true
end

local function SpawnGhost(emp)
    if not IsValid(emp) then return end
    if IsValid(EntGet(emp, "_gredAutoGhost")) then return end

    local ghost = ents.Create("npc_combine_s")
    if not IsValid(ghost) then
        MsgC(Color(255,150,50), "[GredAuto] Failed to create ghost NPC\n")
        return
    end

    ghost:SetModel(GHOST_MODEL)
    ghost:SetPos(emp:GetPos() + Vector(0, 0, -4096))
    ghost:SetAngles(emp:GetAngles())
    ghost:SetKeyValue("squadname", "gredauto_ghost")
    ghost:SetKeyValue("spawnflags", "512")
    ghost:Spawn()
    ghost:Activate()

    ghost:SetNoDraw(true)
    ghost:SetNotSolid(true)
    ghost:SetCollisionGroup(COLLISION_GROUP_NONE)
    ghost:SetMoveType(MOVETYPE_NONE)
    ghost:SetPos(emp:GetPos() + Vector(0, 0, -4096))

    local phys = ghost:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end

    -- NPC entities always have a GetTable() since they are SENT-backed in GMod
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
    et.Owner              = ghost
    et.ShouldSetAngles    = true

    emp:SetBotMode(false)
    emp:SetShooter(ghost)
    emp:SetBotMode(true)

    MsgC(Color(100,200,255), "[GredAuto] Ghost ready: ", emp:GetClass(), "\n")
end

hook.Add("OnEntityCreated", "gredauto_emplacement_init", function(ent)
    if not IsValid(ent) then return end
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if not IsGredEmp(ent) then return end
        if IsValid(EntGet(emp, "_gredAutoGhost")) then return end
        SpawnGhost(ent)
    end)
end)

hook.Add("EntityRemoved", "gredauto_ghost_cleanup", function(ent)
    -- MUST guard: EntityRemoved fires for ALL entities (brushes, world, etc.)
    -- Only scripted emplacements and NPCs have our custom fields
    if not IsValid(ent) then return end
    local class = ent:GetClass()

    -- Case 1: a gred emplacement was removed -> kill its ghost
    if string.sub(class, 1, 8) == "gred_emp" then
        local t = ent:GetTable()
        if not t then return end
        local ghost = t._gredAutoGhost
        if IsValid(ghost) then ghost:Remove() end
        return
    end

    -- Case 2: our ghost NPC was removed -> clean up emplacement ref
    if class == "npc_combine_s" then
        local t = ent:GetTable()
        if not t or not t._gredAutoGhost then return end
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
    if npc:GetClass() ~= "npc_combine_s" then return end
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
