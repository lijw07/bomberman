# Imported arcade scenes

All 32 approved v11 sheets have reusable scenes. The gallery shows collision footprints and exposes animation selection.

[Open the asset gallery](asset_gallery.tscn)

The game uses a 64-pixel grid. CharacterBody2D footprints describe the grounded body rather than the tall helmet silhouette. Grid rules govern lane movement, wall-pass and owner bomb clearance. Floors and cosmetic effects have no blocking shape. UI Controls use GUI hit rectangles, not physics bodies. Closed exits block a tile; open exits expose an Area2D trigger for future level assembly. Existing campaign completion still occurs when all enemies are defeated.

| Artwork | Scene | Collision |
| --- | --- | --- |
| bomber_white | [bomber_white](/Users/jaili/projects/godot/bomberman/scenes/arcade/characters/bomber_white.tscn) | CharacterBody2D 60×48 / layer 4 |
| bomber_coral | [bomber_coral](/Users/jaili/projects/godot/bomberman/scenes/arcade/characters/bomber_coral.tscn) | CharacterBody2D 60×48 / layer 4 |
| bomber_lime | [bomber_lime](/Users/jaili/projects/godot/bomberman/scenes/arcade/characters/bomber_lime.tscn) | CharacterBody2D 60×48 / layer 4 |
| bomber_violet | [bomber_violet](/Users/jaili/projects/godot/bomberman/scenes/arcade/characters/bomber_violet.tscn) | CharacterBody2D 60×48 / layer 4 |
| enemy_ballom | [ballom](/Users/jaili/projects/godot/bomberman/scenes/arcade/enemies/ballom.tscn) | CharacterBody2D 56×44 / layer 8 |
| enemy_onil | [onil](/Users/jaili/projects/godot/bomberman/scenes/arcade/enemies/onil.tscn) | CharacterBody2D 56×44 / layer 8 |
| enemy_dahl | [dahl](/Users/jaili/projects/godot/bomberman/scenes/arcade/enemies/dahl.tscn) | CharacterBody2D 56×44 / layer 8 |
| enemy_minvo | [minvo](/Users/jaili/projects/godot/bomberman/scenes/arcade/enemies/minvo.tscn) | CharacterBody2D 56×44 / layer 8 |
| enemy_doria | [doria](/Users/jaili/projects/godot/bomberman/scenes/arcade/enemies/doria.tscn) | CharacterBody2D 56×44 / layer 8 |
| enemy_ovape | [ovape](/Users/jaili/projects/godot/bomberman/scenes/arcade/enemies/ovape.tscn) | CharacterBody2D 56×44 / layer 8 |
| enemy_pass | [pass](/Users/jaili/projects/godot/bomberman/scenes/arcade/enemies/pass.tscn) | CharacterBody2D 56×44 / layer 8 |
| enemy_pontan | [pontan](/Users/jaili/projects/godot/bomberman/scenes/arcade/enemies/pontan.tscn) | CharacterBody2D 56×44 / layer 8 |
| terrain | [floor](/Users/jaili/projects/godot/bomberman/scenes/arcade/terrain/floor.tscn) | none |
| terrain | [stone](/Users/jaili/projects/godot/bomberman/scenes/arcade/terrain/stone.tscn) | StaticBody2D 64×64 / layer 1 |
| terrain | [brick](/Users/jaili/projects/godot/bomberman/scenes/arcade/terrain/brick.tscn) | StaticBody2D 64×64 / layer 2 |
| terrain | [exit_closed](/Users/jaili/projects/godot/bomberman/scenes/arcade/terrain/exit_closed.tscn) | StaticBody2D 64×64 / layer 1 |
| exit-open | [exit_open](/Users/jaili/projects/godot/bomberman/scenes/arcade/terrain/exit_open.tscn) | Area2D 48×48 / layer 128 |
| terrain | [floor_2](/Users/jaili/projects/godot/bomberman/scenes/arcade/terrain/floor_2.tscn) | none |
| terrain | [floor_3](/Users/jaili/projects/godot/bomberman/scenes/arcade/terrain/floor_3.tscn) | none |
| terrain | [vine_stone](/Users/jaili/projects/godot/bomberman/scenes/arcade/terrain/vine_stone.tscn) | StaticBody2D 64×64 / layer 1 |
| bomb | [bomb](/Users/jaili/projects/godot/bomberman/scenes/entities/bomb.tscn) | StaticBody2D 56×56 / layer 16 |
| explosion | [flame_center](/Users/jaili/projects/godot/bomberman/scenes/arcade/effects/flame_center.tscn) | Area2D 64×64 / layer 64 |
| explosion | [flame_arm](/Users/jaili/projects/godot/bomberman/scenes/arcade/effects/flame_arm.tscn) | Area2D 64×64 / layer 64 |
| explosion | [flame_tip](/Users/jaili/projects/godot/bomberman/scenes/arcade/effects/flame_tip.tscn) | Area2D 64×64 / layer 64 |
| brick-break | [brick_break](/Users/jaili/projects/godot/bomberman/scenes/effects/brick_break.tscn) | none |
| puff | [puff](/Users/jaili/projects/godot/bomberman/scenes/effects/puff.tscn) | none |
| powerups | [fire](/Users/jaili/projects/godot/bomberman/scenes/arcade/pickups/fire.tscn) | Area2D 48×48 / layer 32 |
| powerups | [bomb](/Users/jaili/projects/godot/bomberman/scenes/arcade/pickups/bomb.tscn) | Area2D 48×48 / layer 32 |
| powerups | [speed](/Users/jaili/projects/godot/bomberman/scenes/arcade/pickups/speed.tscn) | Area2D 48×48 / layer 32 |
| powerups | [wall_pass](/Users/jaili/projects/godot/bomberman/scenes/arcade/pickups/wall_pass.tscn) | Area2D 48×48 / layer 32 |
| powerups | [bomb_pass](/Users/jaili/projects/godot/bomberman/scenes/arcade/pickups/bomb_pass.tscn) | Area2D 48×48 / layer 32 |
| powerups | [remote](/Users/jaili/projects/godot/bomberman/scenes/arcade/pickups/remote.tscn) | Area2D 48×48 / layer 32 |
| powerups | [shield](/Users/jaili/projects/godot/bomberman/scenes/arcade/pickups/shield.tscn) | Area2D 48×48 / layer 32 |
| powerups | [mystery](/Users/jaili/projects/godot/bomberman/scenes/arcade/pickups/mystery.tscn) | Area2D 48×48 / layer 32 |
| screen-menu | [screen-menu](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/screen-menu.tscn) | Control |
| screen-setup | [screen-setup](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/screen-setup.tscn) | Control |
| screen-how-to-play | [screen-how-to-play](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/screen-how-to-play.tscn) | Control |
| screen-battle | [screen-battle](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/screen-battle.tscn) | Control |
| screen-campaign | [screen-campaign](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/screen-campaign.tscn) | Control |
| screen-results | [screen-results](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/screen-results.tscn) | Control |
| screen-stage_clear | [screen-stage_clear](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/screen-stage_clear.tscn) | Control |
| screen-game_over | [screen-game_over](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/screen-game_over.tscn) | Control |
| screen-stage_intro | [screen-stage_intro](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/screen-stage_intro.tscn) | Control |
| screen-pause | [screen-pause](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/screen-pause.tscn) | Control |
| button-states | [button-states_0](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/button-states_0.tscn) | Control |
| button-states | [button-states_1](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/button-states_1.tscn) | Control |
| button-states | [button-states_2](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/button-states_2.tscn) | Control |
| button-states | [button-states_3](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/button-states_3.tscn) | Control |
| button-states | [button-states_4](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/button-states_4.tscn) | Control |
| panel-states | [panel-states_0](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/panel-states_0.tscn) | Control |
| panel-states | [panel-states_1](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/panel-states_1.tscn) | Control |
| panel-states | [panel-states_2](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/panel-states_2.tscn) | Control |
| panel-states | [panel-states_3](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/panel-states_3.tscn) | Control |
| round-markers | [round-markers_0](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/round-markers_0.tscn) | Control |
| round-markers | [round-markers_1](/Users/jaili/projects/godot/bomberman/scenes/arcade/ui/round-markers_1.tscn) | Control |
