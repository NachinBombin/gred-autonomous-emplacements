-- gredauto_cl_spawnmenu_legacy.lua
-- Spawnmenu tab using ContentIcon buttons inside a DScrollPanel.
-- Does NOT use ContentSidebar:AddCategory (that method does not exist in GMod).
if not CLIENT then return end

local ENTRIES = {
    -- Machine Guns
    { class="gred_emp_bar",            name="BAR",               cat="Machine Guns" },
    { class="gred_emp_bren",           name="Bren",              cat="Machine Guns" },
    { class="gred_emp_dshk",           name="DShK",              cat="Machine Guns" },
    { class="gred_emp_fnmag",          name="FN MAG",            cat="Machine Guns" },
    { class="gred_emp_gau19",          name="GAU-19",            cat="Machine Guns" },
    { class="gred_emp_kord",           name="Kord",              cat="Machine Guns" },
    { class="gred_emp_m134",           name="M134 Minigun",      cat="Machine Guns" },
    { class="gred_emp_m1919",          name="M1919",             cat="Machine Guns" },
    { class="gred_emp_m2",             name="M2 Browning",       cat="Machine Guns" },
    { class="gred_emp_m2_low",         name="M2 Browning Low",   cat="Machine Guns" },
    { class="gred_emp_m240b",          name="M240B",             cat="Machine Guns" },
    { class="gred_emp_m60",            name="M60",               cat="Machine Guns" },
    { class="gred_emp_mg15",           name="MG 15",             cat="Machine Guns" },
    { class="gred_emp_mg15_alt",       name="MG 15 (Alt)",       cat="Machine Guns" },
    { class="gred_emp_mg3",            name="MG3",               cat="Machine Guns" },
    { class="gred_emp_mg34",           name="MG 34",             cat="Machine Guns" },
    { class="gred_emp_mg34_alt",       name="MG 34 (Alt)",       cat="Machine Guns" },
    { class="gred_emp_mg42",           name="MG 42",             cat="Machine Guns" },
    { class="gred_emp_mg42_alt",       name="MG 42 (Alt)",       cat="Machine Guns" },
    { class="gred_emp_mg81z",          name="MG 81Z",            cat="Machine Guns" },
    { class="gred_emp_rpk",            name="RPK",               cat="Machine Guns" },
    { class="gred_emp_vickers",        name="Vickers",           cat="Machine Guns" },
    -- AA
    { class="gred_emp_2a65",           name="2A65",              cat="Anti-Aircraft" },
    { class="gred_emp_artemis30",      name="Artemis 30mm",      cat="Anti-Aircraft" },
    { class="gred_emp_bofors",         name="Bofors 40mm",       cat="Anti-Aircraft" },
    { class="gred_emp_breda35",        name="Breda 35",          cat="Anti-Aircraft" },
    { class="gred_emp_flak36",         name="Flak 36",           cat="Anti-Aircraft" },
    { class="gred_emp_flak37",         name="Flak 37",           cat="Anti-Aircraft" },
    { class="gred_emp_flak38",         name="Flak 38",           cat="Anti-Aircraft" },
    { class="gred_emp_flak40z",        name="Flak 40 Zwilling",  cat="Anti-Aircraft" },
    { class="gred_emp_flakvierling38", name="Flakvierling 38",   cat="Anti-Aircraft" },
    { class="gred_emp_m2a1",           name="M2A1 (AA)",         cat="Anti-Aircraft" },
    { class="gred_emp_m5",             name="M5 (AA)",           cat="Anti-Aircraft" },
    { class="gred_emp_m61",            name="M61 Vulcan",        cat="Anti-Aircraft" },
    { class="gred_emp_phalanx",        name="Phalanx CIWS",      cat="Anti-Aircraft" },
    { class="gred_emp_zpu4_1931",      name="ZPU-4 (1931)",      cat="Anti-Aircraft" },
    { class="gred_emp_zpu4_1949",      name="ZPU-4 (1949)",      cat="Anti-Aircraft" },
    { class="gred_emp_zsu23",          name="ZSU-23",            cat="Anti-Aircraft" },
    -- AT Cannons
    { class="gred_emp_6pdr",           name="QF 6-Pdr",          cat="Anti-Tank" },
    { class="gred_emp_kwk",            name="KwK 40",            cat="Anti-Tank" },
    { class="gred_emp_pak38",          name="PaK 38",            cat="Anti-Tank" },
    { class="gred_emp_pak40",          name="PaK 40",            cat="Anti-Tank" },
    { class="gred_emp_pak43",          name="PaK 43",            cat="Anti-Tank" },
    { class="gred_emp_zis2",           name="ZiS-2",             cat="Anti-Tank" },
    { class="gred_emp_zis3",           name="ZiS-3",             cat="Anti-Tank" },
    -- Artillery
    { class="gred_emp_3inchmortar",    name="3-inch Mortar",     cat="Artillery" },
    { class="gred_emp_gpf155",         name="GPF 155mm",         cat="Artillery" },
    { class="gred_emp_grw34",          name="GrW 34 Mortar",     cat="Artillery" },
    { class="gred_emp_lefh18",         name="leFH 18",           cat="Artillery" },
    { class="gred_emp_m1mortar",       name="M1 Mortar",         cat="Artillery" },
    { class="gred_emp_m777",           name="M777 Howitzer",     cat="Artillery" },
    { class="gred_emp_nebelwerfer",    name="Nebelwerfer",       cat="Artillery" },
    { class="gred_emp_pm41",           name="PM-41 Mortar",      cat="Artillery" },
}

local CAT_ORDER = { "Machine Guns", "Anti-Aircraft", "Anti-Tank", "Artillery" }
local FALLBACK  = "entities/gred_emp_mg42.png"

local function GetIcon(class)
    local path = "entities/" .. class .. ".png"
    local mat = Material(path)
    return (not mat:IsError()) and path or FALLBACK
end

spawnmenu.AddCreationTab("Auto Emplacements", function()
    -- Root scroll container
    local scroll = vgui.Create("DScrollPanel")
    scroll:Dock(FILL)

    -- Group entries by category in order
    local catMap = {}
    for _, e in ipairs(ENTRIES) do
        catMap[e.cat] = catMap[e.cat] or {}
        table.insert(catMap[e.cat], e)
    end

    for _, catName in ipairs(CAT_ORDER) do
        local entries = catMap[catName]
        if not entries then continue end

        -- Category header
        local hdr = vgui.Create("DLabel", scroll)
        hdr:SetText(" " .. catName)
        hdr:SetFont("DermaDefaultBold")
        hdr:SetColor(Color(220, 220, 220))
        hdr:SetBackgroundColor(Color(60, 60, 60))
        hdr:SetPaintBackground(true)
        hdr:SetTall(22)
        hdr:Dock(TOP)
        hdr:DockMargin(0, 4, 0, 2)
        scroll:Add(hdr)

        -- Icon grid using DIconLayout
        local grid = vgui.Create("DIconLayout", scroll)
        grid:SetSpaceX(4)
        grid:SetSpaceY(4)
        grid:DockMargin(4, 0, 4, 4)
        grid:Dock(TOP)

        for _, e in ipairs(entries) do
            local btn = vgui.Create("ContentIcon", grid)
            btn:SetContentType("entity")
            btn:SetName(e.name)
            btn:SetMaterial(GetIcon(e.class))
            btn:SetToolTip(e.name .. "\nClass: " .. e.class)
            btn:SetSize(64, 64)

            btn.DoClick = function()
                RunConsoleCommand("gredauto_spawn", e.class)
            end

            btn.DoRightClick = function()
                local menu = DermaMenu()
                menu:AddOption("Copy class: " .. e.class, function()
                    SetClipboardText(e.class)
                end)
                menu:Open()
            end

            grid:Add(btn)
        end

        -- Let DIconLayout size itself to content
        grid:SizeToContents()
        scroll:Add(grid)
    end

    return scroll
end, "icon16/gun.png", 9999)
