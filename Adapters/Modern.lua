local _, addon = ...

local adapter = { id = "modern" }

adapter.ui = {}
function adapter.ui:CreateFrame(frame_type, name, parent, template)
    return CreateFrame(frame_type, name, parent, template)
end
function adapter.ui:CreateContextMenu(owner, initializer)
    return MenuUtil.CreateContextMenu(owner, initializer)
end
function adapter.ui:SupportsKeyboardPropagation()
    return true
end
function adapter.ui:GetMouseFocus()
    if GetMouseFoci then return GetMouseFoci() end
    if GetMouseFocus then return GetMouseFocus() end
end

adapter.timers = {}
function adapter.timers:After(delay, callback)
    return C_Timer.After(delay, callback)
end
function adapter.timers:NewTicker(interval, callback)
    return C_Timer.NewTicker(interval, callback)
end

adapter.events = {}
function adapter.events:Register(frame, event_name)
    if not frame or not event_name then return false end
    return pcall(frame.RegisterEvent, frame, event_name)
end

adapter.addons = {}
function adapter.addons:IsLoaded(addon_name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local _, loaded = C_AddOns.IsAddOnLoaded(addon_name)
        return loaded == true
    end
    return IsAddOnLoaded and IsAddOnLoaded(addon_name) or false
end

adapter.lifecycle = {}
function adapter.lifecycle:OnLoaded(addon_name, callback)
    if EventUtil and EventUtil.ContinueOnAddOnLoaded then
        EventUtil.ContinueOnAddOnLoaded(addon_name, callback)
        return
    end

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
    if addon.settingsCategory and addon.settingsCategory.GetID and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(addon.settingsCategory:GetID())
        return true
    end
    return false
end

adapter.spells = {}
function adapter.spells:VisitSpellbook(visitor)
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
        for tab_index = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local tab = C_SpellBook.GetSpellBookSkillLineInfo(tab_index)
            if tab and tab.name then
                visitor("tab", tab.name)
                for slot = tab.itemIndexOffset + 1, tab.itemIndexOffset + tab.numSpellBookItems do
                    local info = C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank.Player)
                    if info and info.name and not info.isPassive then
                        visitor("spell", tab.name, info.name, info.spellID)
                    end
                end
            end
        end
        return true
    end
    return false
end
function adapter.spells:GetInfo(identifier)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(identifier)
        if info then return info.name, info.iconID, info.spellID end
    end
    local name, _, icon, _, _, _, spell_id = GetSpellInfo(identifier)
    return name, icon, spell_id
end
function adapter.spells:IsKnown(spell_id)
    if C_SpellBook and C_SpellBook.IsSpellKnown then return C_SpellBook.IsSpellKnown(spell_id) end
    return IsSpellKnown and IsSpellKnown(spell_id) or false
end
function adapter.spells:Pickup(spell_id, _, spell_name)
    if C_Spell and C_Spell.PickupSpell then return C_Spell.PickupSpell(spell_id) end
    if PickupSpell then return PickupSpell(spell_id or spell_name) end
end

adapter.actions = {}
function adapter.actions:GetSpell(slot)
    if C_ActionBar and C_ActionBar.GetSpell then return C_ActionBar.GetSpell(slot) end
    local action_type, action_id = GetActionInfo(slot)
    if action_type == "spell" then return action_id end
end
function adapter.actions:VisitBindings(visitor)
    for index = 1, GetNumBindings() do
        local command, category = GetBinding(index)
        if command and category and not command:find("^PREFACE_") and not command:find("HEADER_BLANK") then
            visitor(category, command, _G["BINDING_NAME_" .. command] or command)
        end
    end
end
function adapter.actions:GetCursorBinding()
    local cursor_type, data = GetCursorInfo()
    if cursor_type == "spell" and data then
        local name, icon = addon.ports.spells:GetInfo(data)
        if name then return "SPELL " .. name, name, icon end
    elseif cursor_type == "macro" and data then
        local name, icon = GetMacroInfo(data)
        if name then return "MACRO " .. name, name, icon end
    end
end

addon.adapters = addon.adapters or {}
addon.adapters.modern = adapter
