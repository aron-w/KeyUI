# KeyUI Ascension

> Community fork of KeyUI for **Project Ascension on the WotLK 3.3.5a client**.

KeyUI Ascension visualizes and edits keyboard and mouse bindings inside the game. This fork keeps the original KeyUI layouts and visualization features while replacing unsupported modern WoW APIs with an Ascension-compatible ports-and-adapters layer.

The original KeyUI addon was created by **Blandros**. This repository is an Ascension-focused fork and is not the upstream CurseForge, WoWInterface, or Wago release.

<p align="center">
  <img src="https://i.imgur.com/5Fxy5QZ.jpeg" alt="KeyUI keyboard binding overview" width="66%">
  <img src="https://i.imgur.com/NDP7KZa.jpeg" alt="KeyUI mouse binding overview" width="31%">
</p>

## Features

- Visualize your keyboard and mouse bindings at a glance.
- Assign spells, macros, Interface actions, and OPie rings from a key's right-click menu.
- Drag actions onto keys or reorganize them directly inside KeyUI.
- Choose from layouts for standard keyboards, keypads, and gaming mice, then customize them to match your setup.
- See action icons, spell ranks, tooltips, modifier layers, and clearly distinguished unbound keys.
- Built specifically for Project Ascension's WotLK 3.3.5a client.

See [CHANGELOG.md](CHANGELOG.md) for the complete migration summary and current limitations.

## Using KeyUI

1. Type `/kui` or `/keyui`, or click the minimap button.
2. Choose a keyboard or mouse layout.
3. Right-click a displayed key to assign a spell, macro, OPie ring, or Interface action.
4. Drag spells or macros from their normal game UI onto a KeyUI key.
5. Drag one KeyUI binding onto another KeyUI key to move or swap it.

To assign a global toggle hotkey, open **Main Menu → Key Bindings → KeyUI** and bind **Toggle KeyUI**.

During combat, the global hotkey opens KeyUI as a dimmed, read-only binding inspector. Hover a key to see its tooltip; casting, dragging, right-click menus, layout editing, and settings controls stay disabled until combat ends. Press the hotkey again—or **Escape** when KeyUI's ESC option is enabled—to close the preview. If **Combat** is enabled in KeyUI's frame menu, an already-open layout automatically switches into this preview mode when combat starts.

Changes use the active Blizzard binding set and are saved through the normal WoW binding APIs.

## Right-click binding menus

- **Spells:** grouped by Ascension spellbook school, with rank and icon when the client supplies them.
- **Macro:** account and character macros, with their configured icons.
- **OPie:** named, non-internal OPie rings when a compatible `OneRingLib` is available.
- **Interface:** bindings reported by the 3.3.5a binding API, grouped by category.
- **Unbind Key:** removes the current binding.

Long legacy menus continue through adjacent **More...** pages so they remain on-screen.

## Addon integrations

Integration status on Ascension:

- **Bartender4:** exercised during the Ascension migration, including binding display and action-slot interaction.
- **OPie:** dedicated ring assignment is implemented through OPie's own binding API; final live-client confirmation of the latest discovery changes is still pending.
- **ElvUI, BindPad, and Dominos:** compatibility code is inherited from upstream but has **not been confirmed on Ascension**. Do not treat these integrations as supported until they receive live-client testing.

OPie ring assignments cannot be changed during combat. If OPie is installed but its API is unavailable, the OPie submenu shows a diagnostic row instead of disappearing silently.

## Layouts

The upstream keyboard, mouse, and controller visual layouts are retained, including ISO, ANSI, DVORAK, Razer, Azeron, Xbox, PlayStation, and Steam Deck designs.

On Ascension, keyboard and mouse visualization/editing are the supported input paths. The 3.3.5a client does not provide the modern native gamepad input APIs required for live controller capture.

## Known limitations on Ascension

- Native controller/gamepad input capture is unavailable on the 3.3.5a client.
- Retail-only Assisted Combat, charge displays, loss-of-control displays, gamepad events, atlas animations, and keyboard propagation are unavailable or hidden.
- Secure binding and action changes remain subject to WoW combat lockdown.
- Combat preview is opened through the global **Toggle KeyUI** binding; insecure slash-command and minimap callbacks cannot reveal protected key frames during combat.
- Legacy dropdown menus cannot scroll; KeyUI paginates them with **More...** submenus.
- OPie integration requires an enabled OPie build exposing the compatible `OneRingLib` API.
- ElvUI, BindPad, and Dominos integration paths are currently unconfirmed on Ascension.
- Ascension custom spells do not always expose standard spell IDs. KeyUI prefers spellbook slots, but unusual server-specific spell metadata may still need additional compatibility handling.
- Modern WoW client support is retained from upstream, but this fork's primary testing and release target is Ascension WotLK 3.3.5a.

## Troubleshooting

**The window is blank.**

Choose a keyboard or mouse layout from the selection screen.

**A recent change is not visible.**

Run `/reload` so KeyUI rebuilds its spellbook, layouts, and integration state.

**OPie is missing.**

Right-click a key and look for `OPie` between `Macro` and `Interface`. The submenu reports whether OPie failed to load or exposed no rings.

**KeyUI does not recognize my hardware model.**

KeyUI visualizes bindings; it cannot detect operating-system keyboard or mouse models and does not communicate with vendor driver software.

## Development

Ascension-specific client calls live in `Adapters/WotLKAscension.lua`. Shared code consumes stable boundaries from `Ports/Game.lua`; optional OPie access is isolated in `Ports/OPie.lua`. See [COMPATIBILITY.md](COMPATIBILITY.md) for implementation notes and the client test matrix.

## License and attribution

KeyUI Ascension retains the repository's [MIT license](LICENSE) and credits Blandros as the original KeyUI author.
