local _, addon = ...

local adapter = { id = "wotlk-3.3.5a-ascension" }

-- 3.3.5 has native backdrops but no BackdropTemplate. Other substitutions
-- keep factories on the oldest templates with equivalent behavior.
local template_aliases = {
    BackdropTemplate = false,
    GlowBoxTemplate = false,
    UICheckButtonArtTemplate = "UICheckButtonTemplate",
    MinimalSliderTemplate = "OptionsSliderTemplate",
}

local function normalize_templates(templates)
    if type(templates) ~= "string" or templates == "" then return templates end
    local result = {}
    for template in templates:gmatch("[^,%s]+") do
        local replacement = template_aliases[template]
        if replacement == nil then
            table.insert(result, template)
        elseif replacement then
            table.insert(result, replacement)
        end
    end
    if #result == 0 then return nil end
    return table.concat(result, ",")
end

local function create_menu_node(label, callback)
    local node = { text = label, func = callback, children = {} }
    function node:CreateButton(text, func)
        local child = create_menu_node(text, func)
        table.insert(self.children, child)
        return child
    end
    function node:CreateTitle(text)
        table.insert(self.children, { text = text, isTitle = true, notCheckable = true })
    end
    function node:CreateCheckbox(text, is_checked, func)
        local child = create_menu_node(text, func)
        child.isNotRadio = true
        child.checked = is_checked
        table.insert(self.children, child)
        return child
    end
    function node:AddInitializer() return self end
    function node:SetTooltip() return self end
    function node:DeactivateSubmenu() return self end
    function node:CreateDivider()
        table.insert(self.children, { text = " ", disabled = true, notCheckable = true })
    end
    return node
end

local function to_legacy_menu(nodes)
    local menu = {}
    for _, node in ipairs(nodes) do
        local entry = {
            text = node.text,
            func = node.func,
            isTitle = node.isTitle,
            disabled = node.disabled,
            notCheckable = true,
        }
        if node.checked then
            entry.notCheckable = false
            entry.isNotRadio = true
            if type(node.checked) == "function" then
                local ok, checked = pcall(node.checked)
                entry.checked = ok and checked or false
            else
                entry.checked = node.checked
            end
        end
        if node.children and #node.children > 0 then
            entry.hasArrow = true
            entry.menuList = to_legacy_menu(node.children)
        end
        table.insert(menu, entry)
    end
    return menu
end

local function create_legacy_dropdown(name, parent)
    adapter.dropdown_count = (adapter.dropdown_count or 0) + 1
    name = name or ("KeyUILegacyDropdown" .. adapter.dropdown_count)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dropdown:SetWidth(190)

    function dropdown:SetDefaultText(text)
        UIDropDownMenu_SetText(self, text or "")
    end
    function dropdown:SetupMenu(initializer)
        local button = _G[self:GetName() .. "Button"]
        if button then button:SetScript("OnClick", function()
            local root = create_menu_node(nil, nil)
            initializer(self, root)
            EasyMenu(to_legacy_menu(root.children), self, self, 0, 0, "MENU")
        end) end
    end
    return dropdown
end

adapter.ui = {}
function adapter.ui:CreateFrame(frame_type, name, parent, template)
    if frame_type == "DropdownButton" or template == "WowStyle1DropdownTemplate" then
        return create_legacy_dropdown(name, parent)
    end
    if frame_type == "Slider" and not name then
        adapter.slider_count = (adapter.slider_count or 0) + 1
        name = "KeyUILegacySlider" .. adapter.slider_count
    end
    local frame = CreateFrame(frame_type, name, parent, normalize_templates(template))
    local noop = function() end
    if not frame.EnableGamePadButton then frame.EnableGamePadButton = noop end
    if not frame.SetPropagateKeyboardInput then frame.SetPropagateKeyboardInput = noop end
    if not frame.SetClipsChildren then frame.SetClipsChildren = noop end
    if frame_type == "Cooldown" then
        if frame.SetCooldown then
            local set_cooldown = frame.SetCooldown
            frame.SetCooldown = function(self, start_time, duration)
                return set_cooldown(self, start_time, duration)
            end
        end
        if not frame.SetDrawBling then frame.SetDrawBling = noop end
        if not frame.SetDrawEdge then frame.SetDrawEdge = noop end
        if not frame.SetDrawSwipe then frame.SetDrawSwipe = noop end
        if not frame.SetSwipeColor then frame.SetSwipeColor = noop end
        if not frame.SetHideCountdownNumbers then frame.SetHideCountdownNumbers = noop end
    end
    return frame
end
function adapter.ui:CreateContextMenu(owner, initializer)
    local root = create_menu_node(nil, nil)
    initializer(owner, root)
    if not adapter.context_menu then
        adapter.context_menu = CreateFrame("Frame", "KeyUILegacyContextMenu", UIParent, "UIDropDownMenuTemplate")
    end
    EasyMenu(to_legacy_menu(root.children), adapter.context_menu, owner, 0, 0, "MENU")
    return nil
end
function adapter.ui:SupportsKeyboardPropagation()
    return false
end
function adapter.ui:GetMouseFocus()
    return GetMouseFocus and GetMouseFocus() or nil
end

adapter.timers = {}
function adapter.timers:After(delay, callback)
    local elapsed_total = 0
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        elapsed_total = elapsed_total + elapsed
        if elapsed_total >= delay then
            self:SetScript("OnUpdate", nil)
            callback()
        end
    end)
end
function adapter.timers:NewTicker(interval, callback)
    local elapsed_total = 0
    local ticker = { cancelled = false }
    local frame = CreateFrame("Frame")
    function ticker:Cancel()
        self.cancelled = true
        frame:SetScript("OnUpdate", nil)
    end
    frame:SetScript("OnUpdate", function(_, elapsed)
        elapsed_total = elapsed_total + elapsed
        if elapsed_total >= interval then
            elapsed_total = elapsed_total - interval
            callback()
        end
    end)
    return ticker
end

adapter.events = {}
function adapter.events:Register(frame, event_name)
    if not frame or not event_name then return false end
    return pcall(frame.RegisterEvent, frame, event_name)
end

adapter.addons = {}
function adapter.addons:IsLoaded(addon_name)
    return IsAddOnLoaded and IsAddOnLoaded(addon_name) or false
end

adapter.lifecycle = {}
function adapter.lifecycle:OnLoaded(addon_name, callback)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, _, loaded_name)
        if loaded_name == addon_name then
            self:UnregisterEvent("ADDON_LOADED")
            callback()
        end
    end)
end

adapter.settings = {}
function adapter.settings:RegisterPanel()
    if addon.InitializeSettingsPanel then addon.InitializeSettingsPanel() end
end
function adapter.settings:Open()
    if addon.settingsPanel and InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(addon.settingsPanel)
        InterfaceOptionsFrame_OpenToCategory(addon.settingsPanel)
        return true
    end
    return false
end

adapter.spells = {}
function adapter.spells:VisitSpellbook(visitor)
    if not GetNumSpellTabs or not GetSpellTabInfo then return false end
    for tab_index = 1, GetNumSpellTabs() do
        local tab_name, _, offset, spell_count = GetSpellTabInfo(tab_index)
        if tab_name then
            visitor("tab", tab_name)
            for slot = offset + 1, offset + spell_count do
                local spell_type, spell_id = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL or "spell")
                if spell_type == "SPELL" or spell_type == "FUTURESPELL" then
                    local spell_name
                    if spell_id then
                        spell_name = GetSpellInfo(spell_id)
                    else
                        spell_name = GetSpellInfo(slot, BOOKTYPE_SPELL or "spell")
                    end
                    local passive = IsPassiveSpell and IsPassiveSpell(slot, BOOKTYPE_SPELL or "spell")
                    if spell_name and not passive then visitor("spell", tab_name, spell_name, spell_id, slot) end
                end
            end
        end
    end
    return true
end
function adapter.spells:GetInfo(identifier)
    local name, _, icon, _, _, _, spell_id = GetSpellInfo(identifier)
    return name, icon, spell_id
end
function adapter.spells:IsKnown(spell_id)
    if IsSpellKnown then return IsSpellKnown(spell_id) end
    return GetSpellInfo(spell_id) ~= nil
end
function adapter.spells:Pickup(spell_id, book_slot, spell_name)
    if PickupSpellBookItem and book_slot then
        return PickupSpellBookItem(book_slot, BOOKTYPE_SPELL or "spell")
    end
    if PickupSpell then return PickupSpell(spell_name or spell_id) end
end

adapter.actions = {}
function adapter.actions:GetSpell(slot)
    local action_type, action_id = GetActionInfo(slot)
    if action_type == "spell" then return action_id end
end
function adapter.actions:VisitBindings(visitor)
    local category = _G.MISCELLANEOUS or "Other"
    for index = 1, GetNumBindings() do
        local command = GetBinding(index)
        if command then
            local header = command:match("^HEADER_(.+)$")
            if header then
                category = _G["BINDING_HEADER_" .. header] or _G[command] or header
            elseif not command:find("^PREFACE_") and not command:find("HEADER_BLANK") then
                visitor(category, command, _G["BINDING_NAME_" .. command] or command)
            end
        end
    end
end

addon.adapters = addon.adapters or {}
addon.adapters.wotlk_ascension = adapter
