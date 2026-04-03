-- gredauto_cl_spawnmenu.lua
-- Adds a spawnmenu category: "Autonomous Emplacements"
-- Each button spawns the base gredwitch emplacement entity.
-- The server-side spawner (gredauto_sv_spawner.lua) automatically
-- attaches a ghost soldier and activates AI on it.

if not CLIENT then return end

-- ─────────────────────────────────────────────────────────────────────────────
-- Full entity list grouped by category.
-- Format: { class = "gred_emp_XXXX", name = "Display Name", icon = "path" }
-- Icons fall back to the shared gredwitch icon if a specific one is missing.
-- ─────────────────────────────────────────────────────────────────────────────
local FALLBACK_ICON = "entities/gred_emp_mg42.png"

local function EI(class, name)
    return {
        class = class,
        name  = name,
        icon  = "entities/" .. class .. ".png",
    }
end

local CATEGORIES = {
    {
        name = "Machine Guns",
        entries = {
            EI("gred_emp_bar",      "BAR"),
            EI("gred_emp_bren",     "Bren"),
            EI("gred_emp_dshk",     "DShK"),
            EI("gred_emp_fnmag",    "FN MAG"),
            EI("gred_emp_gau19",    "GAU-19"),
            EI("gred_emp_kord",     "Kord"),
            EI("gred_emp_m134",     "M134 Minigun"),
            EI("gred_emp_m1919",    "M1919"),
            EI("gred_emp_m2",       "M2 Browning"),
            EI("gred_emp_m2_low",   "M2 Browning (Low Mount)"),
            EI("gred_emp_m240b",    "M240B"),
            EI("gred_emp_m60",      "M60"),
            EI("gred_emp_mg15",     "MG 15"),
            EI("gred_emp_mg15_alt", "MG 15 (Alt)"),
            EI("gred_emp_mg3",      "MG3"),
            EI("gred_emp_mg34",     "MG 34"),
            EI("gred_emp_mg34_alt", "MG 34 (Alt Mount)"),
            EI("gred_emp_mg42",     "MG 42"),
            EI("gred_emp_mg42_alt", "MG 42 (Alt Mount)"),
            EI("gred_emp_mg81z",    "MG 81Z"),
            EI("gred_emp_rpk",      "RPK"),
            EI("gred_emp_vickers",  "Vickers"),
        },
    },
    {
        name = "Anti-Aircraft",
        entries = {
            EI("gred_emp_2a65",          "2A65"),
            EI("gred_emp_artemis30",     "Artemis 30mm"),
            EI("gred_emp_bofors",        "Bofors 40mm"),
            EI("gred_emp_breda35",       "Breda 35"),
            EI("gred_emp_flak36",        "Flak 36"),
            EI("gred_emp_flak37",        "Flak 37"),
            EI("gred_emp_flak38",        "Flak 38"),
            EI("gred_emp_flak40z",       "Flak 40 Zwilling"),
            EI("gred_emp_flakvierling38","Flakvierling 38"),
            EI("gred_emp_m2a1",          "M2A1 (AA)"),
            EI("gred_emp_m5",            "M5 (AA)"),
            EI("gred_emp_m61",           "M61 Vulcan"),
            EI("gred_emp_phalanx",       "Phalanx CIWS"),
            EI("gred_emp_zpu4_1931",     "ZPU-4 (1931)"),
            EI("gred_emp_zpu4_1949",     "ZPU-4 (1949)"),
            EI("gred_emp_zsu23",         "ZSU-23"),
        },
    },
    {
        name = "Anti-Tank / Cannons",
        entries = {
            EI("gred_emp_6pdr",   "QF 6-Pdr"),
            EI("gred_emp_kwk",    "KwK 40"),
            EI("gred_emp_pak38",  "PaK 38"),
            EI("gred_emp_pak40",  "PaK 40"),
            EI("gred_emp_pak43",  "PaK 43"),
            EI("gred_emp_zis2",   "ZiS-2"),
            EI("gred_emp_zis3",   "ZiS-3"),
        },
    },
    {
        name = "Artillery / Mortars",
        entries = {
            EI("gred_emp_3inchmortar",  "3-inch Mortar"),
            EI("gred_emp_gpf155",       "GPF 155mm"),
            EI("gred_emp_grw34",        "GrW 34 Mortar"),
            EI("gred_emp_lefh18",       "leFH 18"),
            EI("gred_emp_m1mortar",     "M1 Mortar"),
            EI("gred_emp_m777",         "M777 Howitzer"),
            EI("gred_emp_nebelwerfer",  "Nebelwerfer"),
            EI("gred_emp_pm41",         "PM-41 Mortar"),
        },
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Build the spawnmenu
-- ─────────────────────────────────────────────────────────────────────────────
hook.Add("PopulateContent", "gredauto_spawnmenu", function(pnlContent, tree, node)
    -- Root node in the tree
    local rootNode = node:AddNode("Autonomous Emplacements")
    rootNode:SetIcon("icon16/gun.png")

    for _, cat in ipairs(CATEGORIES) do
        local catNode = rootNode:AddNode(cat.name)
        catNode:SetIcon("icon16/folder.png")

        -- When user clicks the category node, populate the content panel
        catNode.OnNodeSelected = function(self)
            pnlContent:Clear()

            local pnlInfo = vgui.Create("ContentContainer", pnlContent)
            pnlInfo:SetVisible(true)
            pnlInfo:SetTall(32)

            for _, entry in ipairs(cat.entries) do
                local localEntry = entry  -- capture

                local icon = vgui.Create("SpawnIcon", pnlContent)
                icon:SetModel("")  -- no model preview

                -- Use entity icon if it exists, else fallback
                local mat = Material(localEntry.icon)
                if mat:IsError() then
                    mat = Material(FALLBACK_ICON)
                end

                icon:SetMaterial(mat:GetName())
                icon:SetToolTip(localEntry.name)
                icon:SetSize(64, 64)

                icon.DoClick = function()
                    RunConsoleCommand("gredauto_spawn", localEntry.class)
                end

                icon.DoRightClick = function()
                    -- Right click: show class name info
                    local menu = DermaMenu()
                    menu:AddOption("Class: " .. localEntry.class, function() end)
                    menu:AddOption("Copy class to clipboard", function()
                        SetClipboardText(localEntry.class)
                    end)
                    menu:Open()
                end

                pnlContent:Add(icon)
            end
        end
    end
end)
