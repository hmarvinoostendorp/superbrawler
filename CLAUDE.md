# Super Brawlers (working title)

A two player versus fighting game in the style of Smash Bros / Street Fighter.

## Game engine

- **Godot 4.6.3** (stable, standard / non-Mono build), 2D.
- Installed via winget (`GodotEngine.GodotEngine`) at:
  `C:\Users\nate\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_win64.exe`
- Rendering method: **GL Compatibility** (broad hardware + web/mobile export support).
- Target PC first, with the option to export to Android / web later.
- Project resolution: 1280x720, stretch mode `canvas_items` / aspect `keep`.

### Running the game

The game must be launched from an **interactive desktop session** to get a visible
window — launching from the agent's background shell produces no visible window
(the process exits with code 1 because it has no interactive window station).
Launchers created for this:

- `Play Super Brawlers.bat` (project root) — runs the game.
- `Edit Super Brawlers (Godot).bat` (project root) — opens the Godot editor.
- `Play Super Brawlers.lnk` on the Desktop.

Headless validation (works from any shell, for CI-style checks):

- Import / parse check: `Godot --headless --editor --quit --path .`
- Run a scene N frames: `Godot --headless --path . res://scenes/Game.tscn --quit-after 200`

## Assets

Basic shape + color primitives for now, drawn in code (`_draw()` / `ColorRect`).
Custom assets come later.

## Project structure

Everything is built in code from primitives; scene files (`.tscn`) are intentionally
minimal (just a root node + attached script). UI is also constructed in code.

```
project.godot          # config + input map (2 players), autoload, display
scenes/
  MainMenu.tscn        # root Control + MainMenu.gd
  CharSelect.tscn      # root Control + CharSelect.gd
  Settings.tscn        # root Control + Settings.gd
  Game.tscn            # root Node2D + Game.gd
scripts/
  GameSettings.gd      # autoload singleton: stocks, HP, mode, picks, CHARACTERS table
  Player.gd            # CharacterBody2D fighter: movement, attack, HP, stocks, AI
  Game.gd              # arena, player spawns, HUD, match/win loop
  MainMenu.gd
  CharSelect.gd        # character select for both players
  Settings.gd
```

## Basic play

- **Stock rounds**: each character has 3 lives (configurable in Settings, range 1–9).
- All characters have **120 hitpoints** per stock.
- Lose all HP → lose one stock and respawn at the spawn point with full HP and a
  brief invulnerability window (visualized as a white flash). Out of stocks →
  that player is defeated and the match ends.
- Played at **60 FPS**; all speeds/attacks are expressed in frames.
- **Basic attack**: 10 damage. Duration is per-character in frames. A hit applies
  knockback + hitstun and can only connect once per attack.
- Hitboxes, speed, and attacks vary by character.

### Combat implementation notes

- Movement is grounded with gravity + jump (platform-fighter feel). The arena is a
  floor with left/right walls that keep fighters in bounds (no ledges yet).
- Players are on collision layer 2 / mask 1 — they collide with the world but
  **not with each other** (fighters pass through one another).
- Attack detection is done manually: while an attack is active, a rectangle in
  front of the attacker (sized by `attack_reach` x `attack_height`) is tested for
  overlap against the opponent's body rect. Deterministic and frame-based rather
  than physics-driven.
- Hitstun is 14 frames; respawn invulnerability is 90 frames (constants in `Player.gd`).

## Characters

Per-character stats live in `GameSettings.CHARACTERS`. Current roster:

| Character        | Size (px) | Move speed | Attack frames | Reach (px) | Notes              |
|------------------|-----------|------------|---------------|------------|--------------------|
| Red Square (`red`)   | 50 x 50   | 330        | 4             | 55         | Smaller, faster    |
| Blue Rectangle (`blue`) | 50 x 90   | 270        | 6             | 85         | Taller, longer reach |
| Green Triangle (`green`) | 60 on each side| 300        | 10            | 70         | stronger, deals double damage (20) |
| Purple Hexagon (`purple`) | 60 on each side| 200        | 6            | 85         | big, long reach but slow, has 50% damage reduction |


Each character has a `shape` (`rect`, `triangle`, or `hexagon`). `Player` builds its
collision shape and `_draw()` outline from `_local_points()` based on that shape:
`rect` uses a `RectangleShape2D`, the others a `ConvexPolygonShape2D`. The triangle is
equilateral, point-up with a flat base; the hexagon is a regular flat-top hexagon
(flat top & bottom edges, so it rests on the floor) where `size.x` equals the side
length. `size` is the bounding box and is used (approximately) for attack-overlap
tests. Players are picked on the Character Select screen and stored in
`GameSettings.p1_character` / `p2_character`.

An optional `damage_reduction` stat (0..1, default 0) makes a character armored:
incoming damage in `Player.take_hit()` is scaled by `(1 - damage_reduction)`, with a
floor of 1 so hits always chip. Purple Hexagon has 0.5 (takes half damage).

## Menus and layout

The game starts at a **main menu** with: 2 Player Versus, Single Player, Settings, Exit.
Both play modes route through the **Character Select** screen before the match.

- **2 Player Versus** — two humans. Both players cursor the roster independently
  (P1 with P1 controls, P2 with P2 controls) and the match starts once both confirm.
- **Single Player** — P1 (human) vs a **basic AI**. On Character Select, P1 picks
  their own fighter first, then the CPU's, both with the P1 controls. The AI closes
  distance, faces the opponent, attacks when in range (with a cooldown), and hops
  toward an airborne opponent.
- **Character Select** — left/right cycles the fighter, attack/jump confirms, Esc
  steps back a confirmation (and leaves to the menu when nothing is locked in).
- **Settings** — adjust the stock/lives count (1–9). More settings to come.
- **Exit** — quits.

In-match: **Esc** returns to the menu; after a KO, **Enter** triggers a rematch.

## Controls

- **Player 1 (Red):** `A`/`D` move, `W` jump, `F` attack.
- **Player 2 (Blue):** Arrow keys move/jump, `/` or numpad-Enter attack.

Input actions are defined in `project.godot` using **physical** keycodes (layout
independent): `p1_left/right/jump/attack`, `p2_left/right/jump/attack`. Menus use
Godot's built-in `ui_accept` / `ui_cancel`.

## Open / deferred decisions

- Single player is vs-AI (could become a training dummy or arcade ladder later).
- Triangle/hexagon attack-overlap uses the bounding box, not the true silhouette.
- Only the basic attack exists; no special moves, blocking, or grabs yet.
- Flat arena with walls; no platforms or ledges/ring-outs.
- Gamepad/controller support not added yet.
