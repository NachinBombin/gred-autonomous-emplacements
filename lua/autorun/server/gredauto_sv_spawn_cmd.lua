-- gredauto_sv_spawn_cmd.lua
-- Server-side console command handler for gredauto_spawn.
-- Called by the client spawnmenu when a player clicks an icon.

if not SERVER then return end

concommand.Add("gredauto_spawn", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        -- Allow all players to spawn (same as normal spawnmenu)
        -- If you want admin-only, uncomment the lines below:
        -- ply:ChatPrint("[GredAuto] You must be an admin to spawn emplacements.")
        -- return
    end

    local class = args[1]
    if not class or not string.StartWith(class, "gred_emp") then
        ply:ChatPrint("[GredAuto] Invalid emplacement class.")
        return
    end

    -- Verify the entity class is registered
    if not scripted_ents.GetStored(class) then
        ply:ChatPrint("[GredAuto] Entity '" .. class .. "' not found. Is Gredwitch Emplacement Pack installed?")
        return
    end

    -- Spawn at player eye trace hit position
    local trace = ply:GetEyeTrace()
    local pos   = trace.HitPos
    local ang   = Angle(0, ply:EyeAngles().y + 180, 0)

    local emp = ents.Create(class)
    if not IsValid(emp) then
        ply:ChatPrint("[GredAuto] Failed to create '" .. class .. "'.")
        return
    end

    emp:SetPos(pos)
    emp:SetAngles(ang)
    emp:Spawn()
    emp:Activate()

    -- Ownership for cleanup tools
    emp:SetCreator(ply)
    undo.Create("Autonomous Emplacement")
        undo.AddEntity(emp)
        undo.SetPlayer(ply)
    undo.Finish()

    -- gredauto_sv_spawner.lua OnEntityCreated hook fires automatically
    -- and attaches the ghost soldier + enables bot mode.

    ply:ChatPrint("[GredAuto] Spawned " .. class .. " — AI activating...")
end)
