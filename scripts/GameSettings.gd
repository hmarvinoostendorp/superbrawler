extends Node
## Global game configuration, persisted across scenes via autoload.

# Number of lives (stocks) each player starts with. Adjustable in Settings.
var stocks: int = 3

# Base hitpoints per stock. Shared by all characters per the design.
var max_health: int = 120

# Match mode chosen from the main menu.
# false = two human players, true = player 1 vs a basic AI.
var single_player: bool = false

# Characters chosen on the Character Select screen. Keys into CHARACTERS.
var p1_character: String = "red"
var p2_character: String = "blue"

## Static per-character tuning. All speeds/durations are in frames @ 60 FPS
## where relevant. Sizes are in pixels.
const CHARACTERS := {
	"red": {
		"name": "Red Square",
		"color": Color(0.86, 0.21, 0.21),
		"shape": "rect",
		"size": Vector2(50, 50),
		"move_speed": 330.0,     # px/sec
		"jump_velocity": -620.0, # px/sec (negative = up)
		"attack_damage": 10,
		"attack_frames": 4,      # red is faster per design
		"attack_reach": 55.0,    # shorter reach
		"attack_height": 44.0,
	},
	"blue": {
		"name": "Blue Rectangle",
		"color": Color(0.21, 0.41, 0.86),
		"shape": "rect",
		"size": Vector2(50, 90),  # taller
		"move_speed": 270.0,
		"jump_velocity": -640.0,
		"attack_damage": 10,
		"attack_frames": 6,
		"attack_reach": 85.0,     # longer reach
		"attack_height": 60.0,
	},
	"green": {
		"name": "Green Triangle",
		"color": Color(0.23, 0.70, 0.27),
		"shape": "triangle",
		# Equilateral, 60px sides. Bounding box: width 60, height 60*sqrt(3)/2.
		"size": Vector2(60, 52),
		"move_speed": 300.0,
		"jump_velocity": -630.0,
		"attack_damage": 20,      # stronger: double damage
		"attack_frames": 10,      # but slower to swing
		"attack_reach": 70.0,
		"attack_height": 50.0,
	},
	"purple": {
		"name": "Purple Hexagon",
		"color": Color(0.55, 0.27, 0.78),
		"shape": "hexagon",
		# Regular flat-top hexagon, 60px sides. Bounding box: 120 x 60*sqrt(3).
		"size": Vector2(120, 104),
		"move_speed": 200.0,      # slow tank
		"jump_velocity": -560.0,  # heavy, low jump
		"attack_damage": 10,
		"attack_frames": 6,
		"attack_reach": 85.0,     # long reach
		"attack_height": 70.0,
		"damage_reduction": 0.5,  # armored: takes 50% damage from hits
	},
}
