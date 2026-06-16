extends CharacterBody2D
class_name Player
## A fighter. Movement, jumping, a frame-timed basic attack, health and stocks.
## Visuals are drawn as colored primitives in _draw(). Instantiated from Game.gd.

signal health_changed(player: Player)
signal stocks_changed(player: Player)
signal defeated(player: Player)

const GRAVITY := 1500.0          # px/sec^2
const HITSTUN_FRAMES := 14       # frames the victim cannot act after a hit
const RESPAWN_INVULN_FRAMES := 90
const KNOCKBACK_X := 360.0
const KNOCKBACK_Y := -320.0

# Identity / config
var player_index: int = 1         # 1 or 2; selects the input action prefix
var character_id: String = "red"
var is_ai: bool = false
var opponent: Player = null
var spawn_position: Vector2 = Vector2.ZERO

# Resolved character stats (copied from GameSettings.CHARACTERS)
var body_size: Vector2 = Vector2(50, 50)
var shape_type: String = "rect"   # "rect" or "triangle"
var color: Color = Color.WHITE
var move_speed: float = 330.0
var jump_velocity: float = -620.0
var attack_damage: int = 10
var attack_frames: int = 4
var attack_reach: float = 55.0
var attack_height: float = 44.0
var damage_reduction: float = 0.0   # fraction of incoming damage ignored (0..1)

# Runtime state
var max_health: int = 120
var health: int = 120
var stocks: int = 3
var facing: int = 1               # 1 = right, -1 = left
var attack_timer: int = 0         # frames remaining in current attack
var hit_landed: bool = false      # has the current attack already connected?
var hitstun_timer: int = 0
var invuln_timer: int = 0
var alive: bool = true            # false only when out of stocks (match over for them)

var _shape: CollisionShape2D


func setup(p_index: int, char_id: String, ai: bool, spawn: Vector2) -> void:
	player_index = p_index
	character_id = char_id
	is_ai = ai
	spawn_position = spawn
	var data: Dictionary = GameSettings.CHARACTERS[char_id]
	body_size = data["size"]
	shape_type = data.get("shape", "rect")
	color = data["color"]
	move_speed = data["move_speed"]
	jump_velocity = data["jump_velocity"]
	attack_damage = data["attack_damage"]
	attack_frames = data["attack_frames"]
	attack_reach = data["attack_reach"]
	attack_height = data["attack_height"]
	damage_reduction = data.get("damage_reduction", 0.0)
	max_health = GameSettings.max_health
	health = max_health
	stocks = GameSettings.stocks
	facing = 1 if spawn.x < 640 else -1


func _ready() -> void:
	# Players collide with the world (layer 1) but not with each other.
	collision_layer = 2
	collision_mask = 1
	_shape = CollisionShape2D.new()
	if shape_type == "rect":
		var rect := RectangleShape2D.new()
		rect.size = body_size
		_shape.shape = rect
	else:
		# Convex polygons (triangle, hexagon, ...) built from the body outline.
		var poly := ConvexPolygonShape2D.new()
		poly.points = _local_points()
		_shape.shape = poly
	add_child(_shape)
	position = spawn_position
	z_index = 5


func _physics_process(delta: float) -> void:
	if invuln_timer > 0:
		invuln_timer -= 1

	# Gravity always applies.
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var can_act := alive and attack_timer <= 0 and hitstun_timer <= 0

	if hitstun_timer > 0:
		hitstun_timer -= 1

	if can_act:
		var dir := _get_move_axis()
		velocity.x = dir * move_speed
		if dir != 0:
			facing = dir
		if _jump_pressed() and is_on_floor():
			velocity.y = jump_velocity
		if _attack_pressed():
			_start_attack()
	elif hitstun_timer > 0 or attack_timer > 0:
		# Decay horizontal momentum (knockback / rooted during attack).
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 0.12)

	# Advance the active attack and test for a hit.
	if attack_timer > 0:
		attack_timer -= 1
		_process_attack_hit()

	move_and_slide()
	queue_redraw()
	if is_ai and alive:
		_ai_think()


# --- Input -----------------------------------------------------------------

func _get_move_axis() -> int:
	if is_ai:
		return _ai_move_dir
	var prefix := "p%d_" % player_index
	return int(Input.get_axis(prefix + "left", prefix + "right"))


func _jump_pressed() -> bool:
	if is_ai:
		return _ai_jump
	return Input.is_action_just_pressed("p%d_jump" % player_index)


func _attack_pressed() -> bool:
	if is_ai:
		return _ai_attack
	return Input.is_action_just_pressed("p%d_attack" % player_index)


# --- Attacking -------------------------------------------------------------

func _start_attack() -> void:
	attack_timer = attack_frames
	hit_landed = false


func _attack_hitbox() -> Rect2:
	# A rectangle extending in front of the fighter.
	var half := body_size * 0.5
	var origin := global_position + Vector2(facing * half.x, -attack_height * 0.5)
	if facing < 0:
		origin.x -= attack_reach
	return Rect2(origin, Vector2(attack_reach, attack_height))


func _body_rect() -> Rect2:
	# Bounding box, used for attack-overlap tests (approximate for triangles).
	return Rect2(global_position - body_size * 0.5, body_size)


func _local_points() -> PackedVector2Array:
	# Body outline in local space, centered on the origin.
	var half := body_size * 0.5
	if shape_type == "triangle":
		# Equilateral, point up, flat base at the bottom.
		return PackedVector2Array([
			Vector2(0, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
	if shape_type == "hexagon":
		# Regular flat-top hexagon (flat top & bottom edges); half.x == side length.
		return PackedVector2Array([
			Vector2(half.x, 0),
			Vector2(half.x * 0.5, half.y),
			Vector2(-half.x * 0.5, half.y),
			Vector2(-half.x, 0),
			Vector2(-half.x * 0.5, -half.y),
			Vector2(half.x * 0.5, -half.y),
		])
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])


func _process_attack_hit() -> void:
	if hit_landed or opponent == null or not opponent.alive:
		return
	if opponent.invuln_timer > 0:
		return
	if _attack_hitbox().intersects(opponent._body_rect()):
		hit_landed = true
		var kb := Vector2(facing * KNOCKBACK_X, KNOCKBACK_Y)
		opponent.take_hit(attack_damage, kb)


func take_hit(damage: int, knockback: Vector2) -> void:
	if not alive or invuln_timer > 0:
		return
	# Armor reduces incoming damage (at least 1 so hits always chip).
	var taken := maxi(1, int(round(damage * (1.0 - damage_reduction))))
	health -= taken
	velocity = knockback
	hitstun_timer = HITSTUN_FRAMES
	attack_timer = 0  # interrupt any attack
	health_changed.emit(self)
	if health <= 0:
		_lose_stock()


func _lose_stock() -> void:
	stocks -= 1
	stocks_changed.emit(self)
	if stocks <= 0:
		stocks = 0
		alive = false
		visible = false
		defeated.emit(self)
	else:
		_respawn()


func _respawn() -> void:
	health = max_health
	position = spawn_position
	velocity = Vector2.ZERO
	attack_timer = 0
	hitstun_timer = 0
	invuln_timer = RESPAWN_INVULN_FRAMES
	health_changed.emit(self)


# --- Basic AI --------------------------------------------------------------

var _ai_move_dir: int = 0
var _ai_jump: bool = false
var _ai_attack: bool = false
var _ai_attack_cooldown: int = 0

func _ai_think() -> void:
	_ai_jump = false
	_ai_attack = false
	if _ai_attack_cooldown > 0:
		_ai_attack_cooldown -= 1
	if opponent == null or not opponent.alive:
		_ai_move_dir = 0
		return

	var dx := opponent.global_position.x - global_position.x
	var dist := absf(dx)
	var in_range := dist <= attack_reach + body_size.x * 0.5 + 8.0

	if in_range:
		_ai_move_dir = 0
		facing = 1 if dx >= 0 else -1
		if _ai_attack_cooldown <= 0:
			_ai_attack = true
			_ai_attack_cooldown = attack_frames + 18
	else:
		_ai_move_dir = 1 if dx > 0 else -1
		# Hop toward an airborne opponent.
		if opponent.global_position.y < global_position.y - 40.0 and is_on_floor():
			_ai_jump = true


# --- Rendering -------------------------------------------------------------

func _draw() -> void:
	var half := body_size * 0.5
	var draw_color := color
	# Flash while invulnerable (just respawned).
	if invuln_timer > 0 and (invuln_timer / 4) % 2 == 0:
		draw_color = color.lerp(Color.WHITE, 0.7)

	var pts := _local_points()
	draw_colored_polygon(pts, draw_color)
	# Outline (closed loop).
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color.BLACK, 2.0)

	# Small facing indicator.
	var eye := Vector2(facing * (half.x - 8), -half.y + 10)
	if shape_type == "triangle":
		eye = Vector2(facing * 8, 0)  # nearer the centroid for a triangle
	draw_circle(eye, 4, Color.WHITE)

	# Visualize the attack hitbox while active.
	if attack_timer > 0:
		var hb := _attack_hitbox()
		var local := hb.position - global_position
		draw_rect(Rect2(local, hb.size), Color(1, 1, 0, 0.35), true)
