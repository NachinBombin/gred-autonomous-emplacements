-- gredauto_sv_targeting.lua
if not SERVER then return end

hook.Add("Think", "gredauto_target_think", function()
    local ct = CurTime()

    for _, emp in ipairs(ents.GetAll()) do
        if not IsValid(emp) then continue end

        -- Always use :GetTable() for custom Lua fields on userdata entities
        local et = emp:GetTable()
        if not et then continue end

        local ghost = et._gredAutoGhost
        if not ghost or not IsValid(ghost) then continue end

        -- Reset fake attack flag each frame
        local gt = ghost:GetTable()
        if gt then gt._gredFakeAttack = false end

        -- Re-assert bot mode if base code disabled it
        if not emp:GetBotMode() then
            emp:SetBotMode(true)
            emp:SetShooter(ghost)
            et.Owner           = ghost
            et.ShouldSetAngles = true
        end

        if emp:GetShooter() ~= ghost then
            emp:SetShooter(ghost)
        end

        -- Clear dead targets
        local tgt = emp:GetTarget()
        if IsValid(tgt) then
            local alive = tgt.Alive and tgt:Alive()
            if alive == false then
                emp:SetTarget(nil)
            end
        end
    end
end)
