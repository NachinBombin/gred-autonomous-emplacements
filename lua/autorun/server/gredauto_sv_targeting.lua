-- gredauto_sv_targeting.lua
if not SERVER then return end

hook.Add("Think", "gredauto_target_think", function()
    -- Only iterate scripted entities with our prefix, not ALL entities
    -- ents.FindByClass is cheaper than ents.GetAll + class check
    for _, emp in ipairs(ents.FindByClass("gred_emp_*")) do
        if not IsValid(emp) then continue end

        local et = emp:GetTable()
        if not et then continue end

        local ghost = et._gredAutoGhost
        if not ghost or not IsValid(ghost) then continue end

        local gt = ghost:GetTable()
        if gt then gt._gredFakeAttack = false end

        if not emp:GetBotMode() then
            emp:SetBotMode(true)
            emp:SetShooter(ghost)
            et.Owner           = ghost
            et.ShouldSetAngles = true
        end

        if emp:GetShooter() ~= ghost then
            emp:SetShooter(ghost)
        end

        local tgt = emp:GetTarget()
        if IsValid(tgt) then
            if tgt.Alive and not tgt:Alive() then
                emp:SetTarget(nil)
            end
        end
    end
end)
