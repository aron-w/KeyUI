local _, addon = ...

-- The modern Settings API does not exist in the 3.3.5 client. Keep the
-- application-facing entry point and provide a small legacy adapter panel.
if not Settings or not Settings.RegisterVerticalLayoutCategory then
    local initialized = false

    local function create_checkbox(parent, label, setting_key, y)
        local checkbox = addon.ports.ui:CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 20, y)
        local text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
        text:SetText(label)
        checkbox:SetScript("OnShow", function(self)
            self:SetChecked(keyui_settings and keyui_settings[setting_key] == true)
        end)
        checkbox:SetScript("OnClick", function(self)
            keyui_settings[setting_key] = not not self:GetChecked()
        end)
        return checkbox, text
    end

    local function InitializeSettingsPanel()
        if initialized then return end
        initialized = true

        local panel = addon.ports.ui:CreateFrame("Frame", "KeyUILegacySettingsPanel", UIParent)
        panel.name = "KeyUI"
        addon.settingsPanel = panel

        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("KeyUI")

        local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        subtitle:SetText("Ascension / WotLK 3.3.5a settings")

        create_checkbox(panel, "Show keyboard", "show_keyboard", -62)
        create_checkbox(panel, "Show mouse", "show_mouse", -92)
        create_checkbox(panel, "Show controller", "show_controller", -122)
        local keypress_checkbox, keypress_text = create_checkbox(panel, "Show keypress highlight", "show_keypress_highlight", -152)
        if not addon.ports.ui:SupportsKeyboardPropagation() then
            keyui_settings.show_keypress_highlight = false
            keypress_checkbox:SetChecked(false)
            keypress_checkbox:Disable()
            keypress_text:SetText("Show keypress highlight (unavailable on the 3.3.5 client)")
        end

        local hotkey_help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        hotkey_help:SetPoint("TOPLEFT", 20, -200)
        hotkey_help:SetWidth(560)
        hotkey_help:SetJustifyH("LEFT")
        hotkey_help:SetText("Configure hotkeys: open KeyUI, then right-click a key on the keyboard, mouse, or controller display. Choose Spells, Macro, Interface, or Unbind.")

        InterfaceOptions_AddCategory(panel)
    end

    addon.InitializeSettingsPanel = InitializeSettingsPanel
    return
end

-- Register Settings category
local category, layout = Settings.RegisterVerticalLayoutCategory("KeyUI")
addon.settingsCategory = category

local function InitializeSettingsPanel()
    -- Minimap Button Setting
    local function GetMinimapValue()
        return not keyui_settings.minimap.hide
    end

    local function SetMinimapValue(value)
        keyui_settings.minimap.hide = not value
        local LibDBIcon = LibStub("LibDBIcon-1.0")
        if value then
            LibDBIcon:Show("KeyUI")
            print("KeyUI: Minimap button enabled")
        else
            LibDBIcon:Hide("KeyUI")
            print("KeyUI: Minimap button disabled")
        end
    end

    local minimapSetting = Settings.RegisterProxySetting(
        category,
        "KEYUI_MINIMAP_BUTTON",
        Settings.VarType.Boolean,
        "Minimap Button",
        Settings.Default.True,
        GetMinimapValue,
        SetMinimapValue
    )
    Settings.CreateCheckbox(category, minimapSetting, "Show or hide the minimap button")

    -- Show Keyboard Setting
    local showKeyboardSetting = Settings.RegisterAddOnSetting(
        category,
        "KEYUI_SHOW_KEYBOARD",
        "show_keyboard",
        keyui_settings,
        Settings.VarType.Boolean,
        "Show Keyboard",
        Settings.Default.False
    )
    Settings.CreateCheckbox(category, showKeyboardSetting, "Show or hide the keyboard frame")

    -- Show Mouse Setting
    local showMouseSetting = Settings.RegisterAddOnSetting(
        category,
        "KEYUI_SHOW_MOUSE",
        "show_mouse",
        keyui_settings,
        Settings.VarType.Boolean,
        "Show Mouse",
        Settings.Default.False
    )
    Settings.CreateCheckbox(category, showMouseSetting, "Show or hide the mouse frame")

    -- Show Controller Setting
    local showControllerSetting = Settings.RegisterAddOnSetting(
        category,
        "KEYUI_SHOW_CONTROLLER",
        "show_controller",
        keyui_settings,
        Settings.VarType.Boolean,
        "Show Controller",
        Settings.Default.False
    )
    Settings.CreateCheckbox(category, showControllerSetting, "Show or hide the controller frame")

    -- Font Header + Settings
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Font"))

    -- Font Face Dropdown
    local function GetFontFace()
        return keyui_settings.font_face
    end

    local function SetFontFace(value)
        keyui_settings.font_face = value
        addon:RefreshAllFonts()
    end

    local function GetFontFaceOptions()
        local container = Settings.CreateControlTextContainer()
        for _, fontName in ipairs(addon.FONT_OPTIONS_ORDER) do
            container:Add(fontName, fontName)
        end
        return container:GetData()
    end

    local fontFaceSetting = Settings.RegisterProxySetting(
        category,
        "KEYUI_FONT_FACE",
        Settings.VarType.String,
        "Font",
        "Expressway",
        GetFontFace,
        SetFontFace
    )
    Settings.CreateDropdown(category, fontFaceSetting, GetFontFaceOptions, "Select the font used throughout KeyUI")

    -- Font Base Size Slider
    local function GetFontSize()
        return keyui_settings.font_base_size
    end

    local function SetFontSize(value)
        keyui_settings.font_base_size = value
        addon:RefreshAllFonts()
    end

    local fontSizeSetting = Settings.RegisterProxySetting(
        category,
        "KEYUI_FONT_SIZE",
        Settings.VarType.Number,
        "Font Size",
        16,
        GetFontSize,
        SetFontSize
    )

    local fontSizeOptions = Settings.CreateSliderOptions(10, 24, 1)
    fontSizeOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(category, fontSizeSetting, fontSizeOptions, "Adjust the base font size for all KeyUI text")

    -- Profiles Header + Buttons
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Profiles"))

    -- Export Profile Button
    local exportButton = CreateSettingsButtonInitializer(
        "Export Profile",
        "Export Profile",
        function()
            addon:ShowProfileExportPopup()
        end,
        "Copy your current KeyUI configuration as a sharable string",
        true
    )
    layout:AddInitializer(exportButton)

    -- Import Profile Button
    local importButton = CreateSettingsButtonInitializer(
        "Import Profile",
        "Import Profile",
        function()
            addon:ShowProfileImportPopup()
        end,
        "Paste a profile string to apply someone else's configuration",
        true
    )
    layout:AddInitializer(importButton)

    -- Reset Settings Button (with confirmation dialog)
    local resetButton = CreateSettingsButtonInitializer(
        "Full Reset",
        "Full Reset",
        function()
            StaticPopupDialogs["KEYUI_CONFIRM_RESET"] = {
                text = "Are you sure you want to reset ALL KeyUI data (settings, layouts, positions, keybinds) to default?",
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    addon:ResetAddonSettings()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("KEYUI_CONFIRM_RESET")
        end,
        "Completely resets all KeyUI data: settings, custom layouts, frame positions, and keybind configurations",
        true
    )
    layout:AddInitializer(resetButton)

    -- Register category
    Settings.RegisterAddOnCategory(category)
end

addon.InitializeSettingsPanel = InitializeSettingsPanel
