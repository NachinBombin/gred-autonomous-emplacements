-- gredauto_cl_fix.lua
-- Guards cl_init KeyDown crash when shooter is not a player.
-- Deferred Think hook retries until gred_emp_base is fully registered.
if not CLIENT then return end

local function PatchBase()
    local reg = scripted_ents.GetStored("gred_emp_base")
    if not reg then return false end
    local ENT = reg.t or reg
    if not ENT or not ENT.Think then return false end
    if ENT._gredAutoPatched then return true end
    ENT._gredAutoPatched = true

    local origThink = ENT.Think
    ENT.Think = function(self)
        local ply = self:GetShooter()
        if IsValid(ply) and not ply:IsPlayer() then
            if not ply._gredCLStubsInjected then
                ply._gredCLStubsInjected = true
                function ply:KeyDown()       return false end
                function ply:IsPlayer()      return false end
                function ply:EyeAngles()     return self:GetAngles() end
                function ply:Alive()         return IsValid(self) end
                function ply:GetViewEntity() return self end
                function ply:GetEyeTrace()
                    return util.QuickTrace(self:GetPos(), self:GetForward() * 1000, {})
                end
            end
        end
        origThink(self)
    end
    return true
end

hook.Add("Think", "gredauto_patchbase_cl", function()
    if PatchBase() then hook.Remove("Think", "gredauto_patchbase_cl") end
end)
