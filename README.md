# Super Brawlers

A two-player versus fighting game in the style of Smash Bros / Street Fighter, built with Godot 4.6.3.

## Play

- **2 Player Versus** — local multiplayer
- **Single Player** — fight a basic AI
- **Stock-based combat** — 120 HP per life, 3 lives per match (configurable 1–9)
- **4 characters** with unique stats:
  - **Red Square** — small, fast, quick 4-frame attack
  - **Blue Rectangle** — tall, long reach
  - **Green Triangle** — strong, double damage (20)
  - **Purple Hexagon** — slow tank, 50% damage reduction

## Running

**Windows:**
- Double-click `Play Super Brawlers.bat` (project root) or the desktop shortcut
- Or open in Godot: double-click `Edit Super Brawlers (Godot).bat` and press F5

**Godot required:** [Download Godot 4.6.3](https://godotengine.org/download/windows/) (standard build, not Mono)

## Controls

| Action | Player 1 | Player 2 |
|--------|----------|----------|
| Move   | A / D    | ← / →    |
| Jump   | W        | ↑        |
| Attack | F        | / or Enter |

**In-match:** Esc → menu, Enter → rematch after KO

## Tech

- Godot 4.6.3, 2D, GL Compatibility, 1280×720
- Frame-timed combat (60 FPS): attacks, hitstun, knockback, invulnerability
- Code-driven primitives (shapes drawn in `_draw()`, UI built in code)
