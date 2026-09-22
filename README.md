# Bomberman

A web-playable recreation of NES Bomberman built in Godot 4.7 (GL Compatibility renderer). Every campaign stage is procedurally generated, enemies follow the original eight archetypes, and battle mode pits you against up to three AI bombers on mirrored arenas with sudden-death pressure blocks.

## Controls

Move with WASD or the arrow keys, drop a bomb with Space or Z, detonate manually with X once you hold the Detonator, and press Esc to pause or resume. The menu is navigated with the same keys and Enter.

## Project layout

`scripts/level/level_generator.gd` builds the arena lattice (border, pillars on even/even cells), places bricks by stage count (54 + 2 per stage), hides the power-up under a brick, and rolls the enemy mix from a weighted tier table. Everything is driven by `RandomNumberGenerator` streams derived from the campaign seed, stage number and attempt, so a seed always produces the same layout.

`scripts/level/grid.gd` is the source of truth for the board at runtime: walkability, bombs, flames, blast propagation with chain reactions, and brick destruction. The floor TileMapLayer renders the floor; reusable StaticBody2D scenes provide walls and bricks. The grid remains authoritative for movement and power-up pass-through rules, while physics bodies and areas expose matching footprints.

`scripts/entities/` holds the bombers (`bomber.gd`: free pixel movement with intersection steps, bombs, death; `player.gd` reads input, `ai_bomber.gd` plans with a danger map, breadth-first search and safe-path checks), grid-locked enemies (`enemy_types.gd` defines speed, chase axis, wall-pass, turn timers and points), bombs, flames and power-ups.

`scripts/battle/battle.gd` runs a battle round: mirrored 15x13 arena, hidden Fire/Bomb/Speed items, a two-minute clock, pressure blocks spiralling inward from 1:00, and a first-to-two-rounds match.

`scripts/stage/stage.gd` runs a campaign stage: stage card, timer, pickups, timeout Pontans, multi-kill scoring, the stage-clear screen when the last enemy dies, and the life/level flow through the `Game` autoload.

## Debug tools

Press F3 in any scene to toggle the debug overlay: FPS, bomb and flame counts, every bomber's cell, stats and power-up flags, and for CPU bombers their profile, path length and wait/idle timers. The overlay also paints each bomb's blast area in yellow, the AI danger map in red, and the planned path of each CPU in cyan. While the overlay is on: F5 kills every enemy or CPU, F6 maxes out the player's power-ups, F7 toggles player invincibility, F8 skips the stage or ends the round.

## Web export

The `Web` preset in `export_presets.cfg` targets `build/web/index.html` with thread support disabled so it runs on itch.io without cross-origin isolation headers. Sound effects use sample playback for the single-threaded web audio path.

## Credits

See `assets/CREDITS.txt`. The current visual set is the approved project-specific arcade v11 art. Existing music, sound effects and the font retain their original licenses.

## Approved arcade art

The v11 set is integrated under `assets/arcade/`: 32 sheets, 87 animation clips and 55 reusable asset scenes. See [scene index](scenes/arcade/README.md). Run `scenes/arcade/asset_gallery.tscn` to browse every asset and its animation clips; green rectangles show the collision footprint.

World cells are 64 pixels. Character canvases are 128 pixels with their approved ground anchor retained. Textures use nearest filtering, lossless imports and no mipmaps; camera zoom stays at 1 and canvas transforms snap to pixels. The window starts at 1024×768. Larger windows reveal more arena; the camera follows the player when the arena exceeds the available area. The complete 15×13 battle arena is visible when the window is tall enough (at least 1028 pixels).

`resources/arcade/` holds editable SpriteFrames resources with all authored directions, idles, victory and death clips. Disappearance clips do not loop; flame collision expires before the final transparent frame. `tools/import_arcade_art.py` can recreate the asset resources and scene catalog from the approved review bundle. Gameplay wrappers retain their original paths.

The old sprite directory and its import sidecars have been removed. Licensed audio and the font are still in use. An exact pre-import rollback archive and rendered verification captures are kept under `art-review/integration-v11/`, excluded from Godot by `art-review/.gdignore`.

Native checks: run `tests/arcade_integration.tscn` headlessly. Rendered UI/play checks: run `tests/arcade_visual_smoke.tscn` using the compatibility renderer. This integration was verified on macOS at 1024×768 and 1536×1152; a fresh web export is not part of this validation.
