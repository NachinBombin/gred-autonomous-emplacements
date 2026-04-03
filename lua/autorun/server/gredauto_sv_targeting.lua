-- gredauto_sv_targeting.lua
-- Per-think target validity check and fakeAttack reset.
-- Runs independently so the main gred_emp_base Think doesn't need to know about us.

if not SERVER then return end

hook.Add("Think", "gredauto_target_think", function()
    local ct = CurTime()

    for _, emp in ipairs(ents.GetAll()) do
        local ghost = rawget(emp, "_gredAutoGhost")
        if not ghost or not IsValid(ghost) then continue end
        if not IsValid(emp) then continue end

        -- Reset fake attack flag each frame; FindBotTarget+Think will re-set it
        ghost._gredFakeAttack = false

        -- Keep bot mode on (it can get turned off by base code edge cases)
        if not emp:GetBotMode() then
            emp:SetBotMode(true)
            emp:SetShooter(ghost)
            emp.Owner = ghost
            emp.ShouldSetAngles = true
        end

        -- Keep shooter valid
        if emp:GetShooter() ~= ghost then
            emp:SetShooter(ghost)
        end

        -- If target is dead/gone, clear it so FindBotTarget rescans
        local tgt = emp:GetTarget()
        if IsValid(tgt) then
            if tgt:IsNPC() and not tgt:Alive() then
                emp:SetTarget(nil)
            elseif tgt:IsPlayer() and not tgt:Alive() then
                emp:SetTarget(nil)
            end
        end
    end
end)
