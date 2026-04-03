-- gredauto_cl_spawnmenu_legacy.lua
-- Simpler fallback spawnmenu using spawnmenu.AddContentType + ContentSidebar.
-- This adds a proper "NPC"-style sidebar entry compatible with all GMod versions.

if not CLIENT then return end

local ENTRIES = {
    -- Machine Guns
    { class="gred_emp_bar",            name="BAR",                  cat="MG" },
    { class="gred_emp_bren",           name="Bren",                 cat="MG" },
    { class="gred_emp_dshk",           name="DShK",                 cat="MG" },
    { class="gred_emp_fnmag",          name="FN MAG",               cat="MG" },
    { class="gred_emp_gau19",          name="GAU-19",               cat="MG" },
    { class="gred_emp_kord",           name="Kord",                 cat="MG" },
    { class="gred_emp_m134",           name="M134 Minigun",         cat="MG" },
    { class="gred_emp_m1919",          name="M1919",                cat="MG" },
    { class="gred_emp_m2",             name="M2 Browning",          cat="MG" },
    { class="gred_emp_m2_low",         name="M2 Browning Low",      cat="MG" },
    { class="gred_emp_m240b",          name="M240B",                cat="MG" },
    { class="gred_emp_m60",            name="M60",                  cat="MG" },
    { class="gred_emp_mg15",           name="MG 15",                cat="MG" },
    { class="gred_emp_mg15_alt",       name="MG 15 (Alt)",          cat="MG" },
    { class="gred_emp_mg3",            name="MG3",                  cat="MG" },
    { class="gred_emp_mg34",           name="MG 34",                cat="MG" },
    { class="gred_emp_mg34_alt",       name="MG 34 (Alt)",          cat="MG" },
    { class="gred_emp_mg42",           name="MG 42",                cat="MG" },
    { class="gred_emp_mg42_alt",       name="MG 42 (Alt)",          cat="MG" },
    { class="gred_emp_mg81z",          name="MG 81Z",               cat="MG" },
    { class="gred_emp_rpk",            name="RPK",                  cat="MG" },
    { class="gred_emp_vickers",        name="Vickers",              cat="MG" },
    -- AA
    { class="gred_emp_2a65",           name="2A65",                 cat="AA" },
    { class="gred_emp_artemis30",      name="Artemis 30mm",         cat="AA" },
    { class="gred_emp_bofors",         name="Bofors 40mm",          cat="AA" },
    { class="gred_emp_breda35",        name="Breda 35",             cat="AA" },
    { class="gred_emp_flak36",         name="Flak 36",              cat="AA" },
    { class="gred_emp_flak37",         name="Flak 37",              cat="AA" },
    { class="gred_emp_flak38",         name="Flak 38",              cat="AA" },
    { class="gred_emp_flak40z",        name="Flak 40 Zwilling",     cat="AA" },
    { class="gred_emp_flakvierling38", name="Flakvierling 38",      cat="AA" },
    { class="gred_emp_m2a1",           name="M2A1 (AA)",            cat="AA" },
    { class="gred_emp_m5",             name="M5 (AA)",              cat="AA" },
    { class="gred_emp_m61",            name="M61 Vulcan",           cat="AA" },
    { class="gred_emp_phalanx",        name="Phalanx CIWS",         cat="AA" },
    { class="gred_emp_zpu4_1931",      name="ZPU-4 (1931)",         cat="AA" },
    { class="gred_emp_zpu4_1949",      name="ZPU-4 (1949)",         cat="AA" },
    { class="gred_emp_zsu23",          name="ZSU-23",               cat="AA" },
    -- AT Cannons
    { class="gred_emp_6pdr",           name="QF 6-Pdr",             cat="AT" },
    { class="gred_emp_kwk",            name="KwK 40",               cat="AT" },
    { class="gred_emp_pak38",          name="PaK 38",               cat="AT" },
    { class="gred_emp_pak40",          name="PaK 40",               cat="AT" },
    { class="gred_emp_pak43",          name="PaK 43",               cat="AT" },
    { class="gred_emp_zis2",           name="ZiS-2",                cat="AT" },
    { class="gred_emp_zis3",           name="ZiS-3",                cat="AT" },
    -- Artillery
    { class="gred_emp_3inchmortar",    name="3-inch Mortar",        cat="ART" },
    { class="gred_emp_gpf155",         name="GPF 155mm",            cat="ART" },
    { class="gred_emp_grw34",          name="GrW 34 Mortar",        cat="ART" },
    { class="gred_emp_lefh18",         name="leFH 18",              cat="ART" },
    { class="gred_emp_m1mortar",       name="M1 Mortar",            cat="ART" },
    { class="gred_emp_m777",           name="M777 Howitzer",        cat="ART" },
    { class="gred_emp_nebelwerfer",    name="Nebelwerfer",          cat="ART" },
    { class="gred_emp_pm41",           name="PM-41 Mortar",         cat="ART" },
}

local CAT_LABELS = {
    MG  = "Machine Guns",
    AA  = "Anti-Aircraft",
    AT  = "Anti-Tank",
    ART = "Artillery",
}

local FALLBACK_ICON = "entities/gred_emp_mg42.png"

local function GetIcon(class)
    local path = "entities/" .. class .. ".png"
    local mat = Material(path)
    return (not mat:IsError()) and path or FALLBACK_ICON
end

hook.Add("AddGamemodeMenuItems", "gredauto_sidebar", function()
end)

spawnmenu.AddCreationTab("Autonomous Emplacements", function()
    local ctrl = vgui.Create("ContentSidebar")
    if not IsValid(ctrl) then return vgui.Create("Panel") end

    local catMap = {}
    for _, e in ipairs(ENTRIES) do
        catMap[e.cat] = catMap[e.cat] or {}
        table.insert(catMap[e.cat], e)
    end

    local catOrder = { "MG", "AA", "AT", "ART" }
    for _, catKey in ipairs(catOrder) do
        local entries = catMap[catKey]
        if not entries then continue end

        ctrl:AddCategory(CAT_LABELS[catKey], function(container)
            for _, e in ipairs(entries) do
                local btn = vgui.Create("ContentIcon", container)
                btn:SetContentType("entity")
                btn:SetName(e.name)
                btn:SetMaterial(GetIcon(e.class))
                btn:SetToolTip(e.name .. "\n" .. e.class)
                btn.DoClick = function()
                    RunConsoleCommand("gredauto_spawn", e.class)
                end
                container:Add(btn)
            end
        end)
    end

    return ctrl
end, "icon16/gun.png", 9999)
