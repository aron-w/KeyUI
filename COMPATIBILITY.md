# KeyUI - WoW Version Compatibility Guide

## Overview

This repository is the **Project Ascension fork** of KeyUI. Its primary release and validation target is Ascension's WotLK 3.3.5a client. The upstream all-in-one runtime paths remain in the codebase for compatibility:

- **Project Ascension / WotLK 3.3.5a** - Interface 30300
- **Retail** (12.0.0+ Midnight) - Build 120000+
- **MoP Classic** (5.5.3) - Build 50503
- **Anniversary Edition** (2.5.5) - Build 20505
- **Classic Era** (1.15.8) - Build 11508

### Local API Snapshot Builds Used for Compatibility Validation

The repository includes Blizzard API dumps used as source-of-truth during compatibility audits:

- `API/12.0.5.67088` (Retail)
- `API/5.5.3.66509` (MoP Classic)
- `API/2.5.5.66765` (Anniversary)
- `API/1.15.8.65888` (Classic Era)

## Version Detection System

### VersionCompat.lua

All version detection is centralized in `VersionCompat.lua`. This module runs at addon load and provides the `addon.VERSION` table:

```lua
addon.VERSION = {
    build = 120000,              -- Raw build number
    isRetail = true,             -- Build >= 100000
    isClassic = false,           -- Build < 100000
    isVanilla = false,           -- Build 11500-20000
    isAnniversary = false,       -- Build 20500-30000
    isWotLK335 = false,           -- Build 30300-30399 (Ascension target)
    isMoP = false,               -- Build 50500-60000
    USE_ATLAS = true,            -- Atlas API available (Retail only)
    string = "Retail (Build 120000)"  -- Human-readable version
}
```

## Ports and Adapters

Game APIs are exposed to the addon through the ports in `Ports/Game.lua`.
`Ports/Bootstrap.lua` selects one of the client adapters at load time:

- `Adapters/Modern.lua` passes supported modern APIs through.
- `Adapters/WotLKAscension.lua` maps the 3.3.5a global API, legacy templates,
  Interface Options, dropdown menus, and OnUpdate-based timers onto the same
  contracts.

Application and frame code should call `addon.ports` instead of adding new
version checks. The currently defined boundaries are `actions`, `addons`,
`events`, `lifecycle`, `settings`, `spells`, `timers`, and `ui`.

The Ascension adapter intentionally degrades client features that do not exist
in 3.3.5a. Charge and loss-of-control rings, assisted combat, gamepad input,
atlas-backed proc animations, and keyboard propagation are no-ops or hidden;
the keyboard/mouse visualizer, binding inspection, spellbook, action slots,
cooldowns, legacy settings, and layout menus remain available.

### How to Use in Code

**Check for Retail vs Classic:**
```lua
if addon.VERSION.isRetail then
    -- Use modern Retail APIs
else
    -- Use Classic fallback
end
```

**Check for Atlas support (textures):**
```lua
local USE_ATLAS = addon.VERSION.USE_ATLAS

if USE_ATLAS then
    texture:SetAtlas("Interface/Atlas/Name")
else
    texture:SetTexture("Interface\\AddOns\\KeyUI\\Media\\Atlas\\name")
end
```

**Check for specific version:**
```lua
if addon.VERSION.isAnniversary then
    -- Anniversary-specific code
end
```

## API Compatibility Layer

### Core.lua - API_COMPAT

The `API_COMPAT` table in `Core.lua` detects available WoW APIs:

```lua
local API_COMPAT = {
    has_modern_spellbook = (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines ~= nil),
    has_legacy_spell_api = (_G.GetSpellBookItemInfo ~= nil and _G.GetNumSpellTabs ~= nil),
    has_assisted_combat = (C_AssistedCombat and C_AssistedCombat.IsAvailable ~= nil),
    has_actionbar_getspell = (C_ActionBar and C_ActionBar.GetSpell ~= nil),
}
```

### API Differences by Version

| Feature | Retail API | Classic API | Availability Flag |
|---------|------------|-------------|-------------------|
| **Spellbook** | `C_SpellBook.GetNumSpellBookSkillLines()` | `GetNumSpellTabs()` | `API_COMPAT.has_modern_spellbook` |
| **Spell Info** | `C_SpellBook.GetSpellBookItemInfo(i, bank)` | `GetSpellBookItemInfo(i, "spell")` | `API_COMPAT.has_legacy_spell_api` |
| **Spell Pickup** | `C_Spell.PickupSpell(spellID)` | `PickupSpell(spellID)` | `API_COMPAT.has_modern_spellbook` |
| **Actionbar GetSpell** | `C_ActionBar.GetSpell(slot)` | `GetActionInfo(slot)` fallback | `API_COMPAT.has_actionbar_getspell` |
| **Assisted Combat Action** | `C_ActionBar.IsAssistedCombatAction(slot)` | Availability depends on runtime APIs | Runtime guard (`C_AssistedCombat.IsAvailable()` + `C_ActionBar` checks) |
| **PutActionInSlot** | `C_ActionBar.PutActionInSlot(slot)` | N/A | Runtime guard (`C_ActionBar.PutActionInSlot`) |
| **Addon Check** | `C_AddOns.IsAddOnLoaded(name)` | `IsAddOnLoaded(name)` | Both versions |

### Feature Audit from Local API Dumps

Validated from the local `/API` snapshots:

- `BINDINGS_LOADED` exists in `2.5.5.66765` and `12.0.5.67088`, not in `1.15.8.65888`/`5.5.3.66509`.
- `C_ActionBar.PutActionInSlot` exists only in `12.0.5.67088`.
- `C_ActionBar.GetSpell` and `C_ActionBar.IsAssistedCombatAction` exist in `2.5.5.66765` and `12.0.5.67088`.
- `C_AssistedCombat.IsAvailable` exists in all four API dumps; actual availability is determined at runtime.

Developer note:

- Re-run API checks from the repository root before changing compatibility guards:
  - `rg -n "BINDINGS_LOADED" API/*/Blizzard_APIDocumentationGenerated/KeyBindingsDocumentation.lua`
  - `rg -n "Name = \"(PutActionInSlot|IsAssistedCombatAction|GetSpell)\"" API/*/Blizzard_APIDocumentationGenerated/ActionBarFrameDocumentation.lua`
  - `rg -n "Name = \"IsAvailable\"" API/*/Blizzard_APIDocumentationGenerated/AssistedCombatDocumentation.lua`

### Example: Spellbook Loading

```lua
if API_COMPAT.has_modern_spellbook then
    -- RETAIL: Modern API
    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local skillLineInfo = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
        local spellName = skillLineInfo.name
        local spellID = skillLineInfo.actionID
    end
elseif API_COMPAT.has_legacy_spell_api then
    -- CLASSIC: Legacy API
    for i = 1, GetNumSpellTabs() do
        local name, texture, offset, numSpells = GetSpellTabInfo(i)
        for j = offset + 1, offset + numSpells do
            local spellName, _, spellID = GetSpellBookItemInfo(j, BOOKTYPE_SPELL)
        end
    end
end
```

## Texture System

### Retail vs Classic Textures

**Retail (Build >= 100000):**
- Uses `SetAtlas(atlasName)` with Blizzard's internal atlas system
- Example: `texture:SetAtlas("Interface/TutorialFrame/UIFrameTutorialGlow")`

**Classic (Build < 100000):**
- Uses `SetTexture(filePath)` with extracted BLP files
- Example: `texture:SetTexture("Interface\\AddOns\\KeyUI\\Media\\Atlas\\uiframetutorialglow")`

### Texture Files in Media/Atlas/

These files are **extracted from Retail** and bundled for Classic compatibility:

| File | Size | Purpose |
|------|------|---------|
| `combatassistantsinglebutton.blp` | 8.1MB | Action bar button styling |
| `newplayerexperienceparts.blp` | 2.1MB | Tutorial pointer arrows |
| `dropdown.blp` | 66KB | Button dropdown styling |
| `128redbutton.blp` | 4.1MB | Exit, arrow, and menu button states |
| `redbutton2x.blp` | 130KB | Close button states |
| `uiframetabs.blp` | 66KB | Tab button textures |
| `uiframetutorialglow.blp` | 5.2KB | Glow border effects |
| `uiframetutorialglowvertical.blp` | 2.2KB | Vertical glow effects |
| `minimalsliderbar.blp` | 5.2KB | Slider controls |

### Example: Conditional Texture Loading

```lua
local USE_ATLAS = addon.VERSION.USE_ATLAS

local GLOW_TEXTURE = USE_ATLAS
    and "Interface/TutorialFrame/UIFrameTutorialGlow"
    or "Interface\\AddOns\\KeyUI\\Media\\Atlas\\uiframetutorialglow"

local texture = frame:CreateTexture(nil, "BORDER")
texture:SetTexture(GLOW_TEXTURE)
texture:SetTexCoord(0.03125, 0.53125, 0.570312, 0.695312)
```

## UI Templates

### Blizzard Templates Availability

| Template | Retail | Classic | Fallback |
|----------|--------|---------|----------|
| `PanelTabButtonTemplate` | ✅ | ❌ | `addon:CreateTabButton()` |
| `PanelTopTabButtonTemplate` | ✅ | ❌ | `addon:CreateTopTabButton()` |
| `Tutorial_PointerDown` | ✅ | ❌ | Manual texture construction |
| `Tutorial_PointerLeft` | ✅ | ❌ | Manual texture construction |

### Creating Version-Agnostic Buttons

```lua
local USE_ATLAS = addon.VERSION.USE_ATLAS

if USE_ATLAS then
    -- Retail: Use Blizzard template
    button = CreateFrame("Button", nil, parent, "PanelTabButtonTemplate")
else
    -- Classic: Use custom implementation
    button = addon:CreateTabButton(parent)
end
```

### Custom Implementations (UIHelpers.lua)

KeyUI provides custom fallback implementations for Classic:

- `addon:CreateTabButton(parent)` - Standard horizontal tabs
- `addon:CreateTopTabButton(parent)` - Vertical/top-anchored tabs (75% height, flipped TexCoords)
- `addon:CreateCloseButton(parent)` - Close button with 4 states
- `addon:CreateExitButton(parent)` - Exit button using 128redbutton atlas
- `addon:CreateArrowDownButton(parent)` - Arrow-down menu button using 128redbutton atlas
- `addon:create_glow_border(frame)` - Tutorial glow border effect
- `addon:CreateStyledButton(parent, options)` - Styled dropdown-style buttons

## Testing Checklist

Before an Ascension release, test the primary target first. If publishing the retained all-in-one build elsewhere, also run the upstream client checks below.

### Project Ascension / WotLK 3.3.5a (primary target)

- [ ] Existing KeyUI settings and Blizzard bindings survive `/reload` and opening/closing KeyUI
- [ ] Keyboard and mouse layouts show existing bindings, including `BUTTON4` and `BUTTON5`
- [ ] Right-click spell schools contain ranked spells with correct icons
- [ ] Direct spells, macros, Interface actions, and OPie rings can be assigned outside combat
- [ ] Direct spell and action-slot hover tooltips display correctly
- [ ] Spell/macro drops and KeyUI-to-KeyUI moves work
- [ ] Long binding menus remain on-screen through **More...** pagination
- [ ] Unbound labels are darker than bound labels and hover text has a readable background
- [ ] Legacy Interface Options panel opens and saved settings persist
- [ ] No Retail-only gamepad, Assisted Combat, atlas, charge, or loss-of-control API errors occur

### Retail (Build 120000, API dump 67088)
- [ ] Addon loads without Lua errors
- [ ] Atlas textures load correctly (no custom BLP files used)
- [ ] `C_SpellBook` API functions correctly
- [ ] Assisted Combat feature appears (if enabled in settings)
- [ ] Tab buttons use `PanelTabButtonTemplate`
- [ ] Tutorial arrows use `Tutorial_Pointer*` templates
- [ ] Settings panel appears in Interface options

### Anniversary (Build 20505, API dump 66765)
- [ ] Addon loads without Lua errors
- [ ] Custom BLP textures from `Media/Atlas/` load correctly
- [ ] Legacy spell API (`GetSpellTabInfo`, `GetSpellBookItemInfo`) works
- [ ] Assisted Combat appears only when `C_AssistedCombat.IsAvailable()` returns true; otherwise the entry/indicator stays hidden without errors
- [ ] Custom tab buttons (`CreateTabButton`) render correctly
- [ ] Custom tutorial arrows with manual textures work
- [ ] All frames render with correct textures

### MoP Classic (Build 50503, API dump 66509)
- [ ] Addon loads without Lua errors
- [ ] Custom BLP textures load correctly
- [ ] Legacy spell API works
- [ ] Keybind visualization works
- [ ] All UI elements render correctly

### Classic Era (Build 11508, API dump 65888)
- [ ] Addon loads without Lua errors
- [ ] Custom BLP textures load correctly
- [ ] Legacy spell API works
- [ ] All frames render correctly
- [ ] No Atlas-dependent code executes

### Addon Integration Regression Tests

ElvUI, BindPad, and Dominos have inherited compatibility code but are **not confirmed on Ascension**. The following remains an uncompleted regression checklist, not a support claim.

#### Dominos (unconfirmed on Ascension)
- [ ] Binding format `CLICK DominosActionButtonN:HOTKEY` resolves to a valid slot
- [ ] Binding format `CLICK DominosActionButtonNHotkey:HOTKEY` resolves to the same slot
- [ ] Binding format `CLICK MultiBarRightActionButtonNHotkey:HOTKEY` resolves to the expected slot
- [ ] Binding format `CLICK MultiBarLeftActionButtonNHotkey:HOTKEY` resolves to the expected slot
- [ ] Binding format `CLICK MultiBarBottomRightActionButtonNHotkey:HOTKEY` resolves to the expected slot
- [ ] Binding format `CLICK MultiBarBottomLeftActionButtonNHotkey:HOTKEY` resolves to the expected slot
- [ ] Binding format `CLICK MultiBar5ActionButtonNHotkey:HOTKEY` resolves to the expected slot
- [ ] Binding format `CLICK MultiBar6ActionButtonNHotkey:HOTKEY` resolves to the expected slot
- [ ] Binding format `CLICK MultiBar7ActionButtonNHotkey:HOTKEY` resolves to the expected slot
- [ ] Binding format `ACTIONBUTTONN` resolves to the live Dominos action slot for bar 1-12
- [ ] KeyUI shows the action icon for both Dominos binding formats
- [ ] Label regression: Dominos bar 1 (`DominosActionButton1-12`) shows `Dominos Action Button N` (not generic `Action Button N`)
- [ ] Drag & drop from KeyUI onto Dominos-bound keys works for both formats
- [ ] Repro test: pick up an action from a Dominos key and place it onto an empty Dominos key, icon appears on the real Dominos button immediately
- [ ] Repro test: pick up icon from a Dominos key and drop it back on the same key, icon remains visible and slot remains stable
- [ ] Fallback regression: when a CLICK binding cannot resolve via live frame attributes, fallback slot equals the frame-attribute slot for the same button
- [ ] Fallback regression: `frame_attr_chain` and numeric/MultiBar fallback produce the same final slot for equivalent Dominos bindings

### In-Game Test Commands

```lua
/reload                  -- Reload UI to test addon load
/keyui                   -- Open KeyUI
-- Test: Open Keyboard/Mouse/Controller frames
-- Test: Verify keybinds display correctly
-- Test: Drag & drop spells onto action bars
-- Test: Click through tutorial
-- Test: Change settings and verify persistence
```

## Adding New Features

### Checklist for New Code

When adding new features, consider version compatibility:

1. **Check if the API exists in all versions**
   - Use `API_COMPAT` flags for API feature detection
   - Example: Only call `C_AssistedCombat` if `API_COMPAT.has_assisted_combat`

2. **Use centralized version detection**
   - Always use `addon.VERSION.USE_ATLAS` instead of calling `GetBuildInfo()` directly
   - Refer to `addon.VERSION.isRetail` or `addon.VERSION.isClassic` for version checks

3. **Provide fallbacks for Classic**
   - If using Blizzard templates, provide custom implementations
   - If using Atlas textures, bundle extracted BLP files in `Media/Atlas/`

4. **Test on all versions**
   - Use the testing checklist above
   - Verify both Retail and Classic code paths execute correctly

### Example: Adding a New UI Element

```lua
local USE_ATLAS = addon.VERSION.USE_ATLAS

local button
if USE_ATLAS then
    -- Retail: Use Blizzard template
    button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
else
    -- Classic: Create custom styled button
    button = addon:CreateStyledButton(parent, {
        width = 120,
        height = 30,
        label = "Click Me"
    })
end
```

## Packaging for Distribution

### Multi-Version TOC

The `KeyUI.toc` file supports multiple WoW versions via a single multi-value interface entry:

```
## Interface: 30300, 120005, 50504, 20505, 11508
```

This retains a single package layout, with Project Ascension / 30300 as this fork's primary target.

### Building with BigWigsMods/packager

The packager automatically detects multi-version TOCs and creates a single package:

```bash
# Install packager
curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash

# Produces a local package; choose fork-owned release destinations explicitly
```

The fork deliberately does not contain the original CurseForge, Wago, or WoWInterface project IDs. Do not publish fork builds through upstream KeyUI release identifiers.

## Version History

### Ascension Fork Strategy (Current)

- Ascension WotLK 3.3.5a is the primary release target
- Upstream modern-client paths remain in the same codebase
- Runtime version detection via `addon.VERSION`
- Ports-and-adapters boundary for client-specific APIs
- Custom fallback implementations for Classic

### Why retain the upstream paths?

1. **Maintainability**: Bug fixes apply to all versions instantly
2. **No code duplication**: DRY principle maintained
3. **Incremental validation**: Other clients can be regression-tested without rebuilding the architecture
4. **Ascension isolation**: Client differences stay in the WotLK adapter instead of spreading through UI code

## Troubleshooting

### Common Issues

**"attempt to index field 'VERSION' (a nil value)"**
- Cause: `VersionCompat.lua` not loaded before other files
- Fix: Ensure `VersionCompat.lua` is listed in TOC before `UIHelpers.lua`

**Textures not loading on Classic**
- Cause: Missing BLP files in `Media/Atlas/`
- Fix: Ensure all 8 texture files are committed to git and included in package

**Lua error on Retail with "SetTexture"**
- Cause: Wrong texture path (Classic path used on Retail)
- Fix: Check `USE_ATLAS` conditional is correct

**Tab buttons look wrong**
- Cause: Wrong button template or custom implementation
- Fix: Verify `USE_ATLAS` check and correct template/fallback used

## Further Reading

- [TOC Format - Warcraft Wiki](https://warcraft.wiki.gg/wiki/TOC_format)
- [Multi-TOC Support - CurseForge](https://support.curseforge.com/support/solutions/articles/9000209856)
- [BigWigsMods Packager - GitHub](https://github.com/BigWigsMods/packager)
- [WoW API Changes by Version - Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch)

---

- **Fork target:** Project Ascension / WotLK 3.3.5a
- **Original author:** Blandros
- **Last updated:** 2026-07-21
- **Retained but not primary:** Retail, MoP Classic, Anniversary, and Classic Era paths
