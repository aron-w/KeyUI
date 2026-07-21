# Changelog — KeyUI Ascension fork

This changelog summarizes the Ascension WotLK 3.3.5a migration performed on the `feat/wotlk-ascension-ports-adapters` branch. It focuses on behavior visible to addon users rather than individual implementation commits.

## Unreleased — Ascension 3.3.5a migration

### Platform migration

- Added Project Ascension / WotLK 3.3.5a detection and `Interface 30300` support.
- Introduced a ports-and-adapters boundary for actions, addons, events, lifecycle, settings, spells, timers, and UI creation.
- Added a dedicated WotLK Ascension adapter for legacy globals and return-value shapes.
- Replaced unavailable modern widget templates with WotLK-safe templates or native legacy frames.
- Added legacy Interface Options registration, dropdown/context menus, addon lifecycle handling, and frame-based timers.
- Normalized legacy cooldown, spellbook, action, macro-limit, slider, font-string, and mouse-focus APIs.

### Startup and saved configuration

- Opening KeyUI no longer disables every key binding.
- Closing KeyUI no longer leaves bindings disabled.
- Keyboard, mouse, and controller Close buttons can hide their protected windows during combat.
- The minimap button no longer resets selected devices or saved layouts to `none`.
- Existing settings and layouts are preserved and repaired when a stale selection is detected.
- Default layouts are seeded without overwriting existing user configuration.

### Binding and drag-and-drop workflows

- Added a global **Toggle KeyUI** action to WoW's Key Bindings interface.
- Restored visible bindings on keyboard and mouse layouts.
- Restored right-click assignment without triggering the currently bound action.
- Added direct spell, macro, and Interface-action assignment.
- Restored dragging spells and macros from Blizzard/Ascension UI onto KeyUI keys.
- Added KeyUI-to-KeyUI direct binding moves and swaps.
- Restored action-slot moves between KeyUI buttons and synchronized affected action slots.
- Added a cursor-following icon and label while dragging a KeyUI binding.
- Added Mouse Buttons 4 and 5 to every built-in mouse layout.
- Migrates old side-button placeholders and normalizes captured `ButtonN` events to WoW's `BUTTONN` binding format.

### Spellbook and macro support

- Enumerates Ascension spellbook variants that return type/ID, lowercase type/ID, name/rank/ID, or slot-only data.
- Lists spells beneath their spellbook schools instead of showing empty school menus.
- Preserves spell ranks and displays them in the right-click menu.
- Uses the exact spellbook slot for spell icons instead of treating Ascension's numeric item data as a global spell ID.
- Uses ranked spell tokens for direct rank-specific assignments when supported by the client.
- Restored direct-spell hover tooltips through WotLK `SetSpellBookItem`, including custom spells without a usable global ID.
- Uses the client macro limits safely and supports both account and character macro menus.

### Right-click menus

- Added WotLK-compatible nested menus for spells, macros, Interface actions, and unbinding.
- Added optional spell, macro, and OPie icons; entries remain text-only when no icon exists.
- Paginates long legacy menus into screen-sized **More...** submenus.
- Prevents OPie proxy commands from appearing as generic Interface bindings.

### OPie integration

- Added a dedicated OPie submenu listing named rings and slice counts.
- Assigns rings through `OneRingLib:SetRingBinding` instead of manufacturing internal proxy commands.
- Discovers OPie when its addon folder is renamed and attempts late loading when necessary.
- Shows a diagnostic submenu row when OPie is installed but unavailable or exposes no bindable rings.
- Corrected the OPie icon path for the WotLK OPie build.

### Visual clarity

- Added a dark bordered background to the custom key-hover tooltip.
- Clamps the hover tooltip to the screen.
- Uses dark-gray labels for unbound keys and white labels for bound keys.
- Uses one neutral gear icon for UI bindings without a specific icon.
- Keeps purpose-built movement arrow and turn icons where available.

### Known limitations

- Native controller/gamepad input capture is not available through the Ascension 3.3.5a client APIs.
- Retail-only Assisted Combat, charge and loss-of-control displays, gamepad events, atlas-backed animations, and keyboard propagation do not run on Ascension.
- Secure action and binding mutations are restricted during combat.
- OPie ring changes are blocked during combat and require a compatible enabled `OneRingLib`.
- ElvUI, BindPad, and Dominos compatibility is inherited but has not been confirmed on Ascension.
- The latest OPie discovery/menu changes have adapter coverage but still need final live-client confirmation.
- WotLK dropdown menus do not support scrolling; long lists use nested pagination.
- Ascension custom spell metadata varies. The adapter has several slot/name/ID fallbacks, but new server-specific tuple shapes may require further updates.
- Modern client paths remain in the repository but are not the primary validation target for this fork.

### Validation status

- Lua sources parse with Lua 5.1.
- Adapter mocks cover legacy widget/API shapes, spellbook tuple variants, cursor spell/macro drops, OPie discovery/binding, menu pagination/icons, direct spell tooltips, and binding colors.
- Live Ascension testing has driven the fixes in this migration. Bartender4 has been observed in that testing; ElvUI, BindPad, Dominos, and the latest OPie menu discovery path remain unconfirmed.
- Release candidates should still receive a clean-profile and existing-profile in-game pass.
