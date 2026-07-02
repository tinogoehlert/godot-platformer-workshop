class_name Player extends CharacterBody2D

# --- Movement ---
# Maximale horizontale Geschwindigkeit und Beschleunigungswerte am Boden.
# "turn_speed" sorgt für das typische, knackige Umkehren bei Richtungswechsel.
@export var run_speed: float = 200.0
@export var acceleration: float = 12.0
@export var deceleration: float = 8.0
@export var turn_speed: float = 30.0

# --- Air Control ---
# In der Luft gelten reduzierte Werte – der Spieler kann die Richtung
# beeinflussen, aber nicht sofort stoppen. Das gibt dem Sprung Gewicht.
@export var air_acceleration: float = 4.0
@export var air_deceleration: float = 2.0
@export var air_turn_speed: float = 6.0

# --- Jump ---
@export var jump_height: float = 400.0

# jump_cut_factor: Wenn der Sprung-Button früh losgelassen wird, wird
# die Aufwärtsgeschwindigkeit gekappt -> variabler Sprung wie bei Mario.
@export var jump_cut_factor: float = 0.5

# coyote_time: Kurzes Zeitfenster, in dem der Spieler noch springen darf,
# nachdem er eine Plattform verlassen hat.
@export var coyote_time: float = 0.2

# jump_buffer_time: Sprungdruck kurz VOR der Landung wird gespeichert
# und beim Aufkommen automatisch ausgeführt.
@export var jump_buffer_time: float = 0.12

# --- Gravity ---
# Beim Fallen wird die Schwerkraft mit dem Multiplikator verstärkt.
# Das erzeugt einen schönen Sprungbogen: langsamer Aufstieg, schneller Fall.
@export var gravity: float = 1000.0
@export var fall_gravity_multiplier: float = 1.6

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var camera: Camera2D = get_viewport().get_camera_2d()


var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _input_dir: float = 0.0
var _is_dead: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		# Sprungwunsch für kurze Zeit speichern (Jump Buffering).
		_jump_buffer_timer = jump_buffer_time
	if event.is_action_released("jump"):
		_apply_jump_cut()


func _process(_delta: float) -> void:
	# Input in _process lesen – so geht kein Tastendruck zwischen Frames verloren.
	_input_dir = Input.get_axis("run_left", "run_right")


func _physics_process(delta: float) -> void:
	# Reihenfolge ist wichtig: erst Schwerkraft, dann Timer, dann Sprung, dann Bewegung.
	_apply_gravity(delta)
	_update_timers(delta)
	_handle_jump()
	_handle_horizontal_movement(delta)
	move_and_slide()
	_update_animations(delta)
	_check_fell_out_of_screen()


# --- Gravity ---

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	# Beim Fallen (velocity.y > 0) den Multiplikator anwenden für schwereren Fall.
	var multiplier := fall_gravity_multiplier if velocity.y > 0.0 else 1.0
	velocity.y += gravity * multiplier * delta


# --- Jump ---

func _handle_jump() -> void:
	# Sprung ausführen, wenn Buffer aktiv UND Coyote-Zeit noch läuft.
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = - jump_height
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0


func _apply_jump_cut() -> void:
	# Sprung abkürzen, wenn der Button losgelassen wird (nur beim Aufstieg).
	if velocity.y < 0.0:
		velocity.y *= jump_cut_factor


# --- Horizontal Movement ---

func _handle_horizontal_movement(delta: float) -> void:
	var target_speed := _input_dir * run_speed
	# In der Luft andere Gewichtungswerte als am Boden – für reduzierten Luftcontrol.
	var weight := _get_air_weight() if not is_on_floor() else _get_ground_weight()
	# lerp() gleitet sanft zur Zielgeschwindigkeit, anstatt direkt zuzuspringen.
	velocity.x = lerp(velocity.x, target_speed, weight * delta)


func _get_ground_weight() -> float:
	# Kein Input -> abbremsen. Richtungswechsel -> sofort reagieren. Sonst -> normal beschleunigen.
	if _input_dir == 0.0:
		return deceleration
	if sign(_input_dir) != sign(velocity.x) and velocity.x != 0.0:
		return turn_speed
	return acceleration


func _get_air_weight() -> float:
	# Gleiche Logik wie am Boden, aber mit deutlich niedrigeren Werten.
	if _input_dir == 0.0:
		return air_deceleration
	if sign(_input_dir) != sign(velocity.x) and velocity.x != 0.0:
		return air_turn_speed
	return air_acceleration


# --- Update Funktionen (Timer, Animationen) ---

func _update_timers(delta: float) -> void:
	# Coyote-Timer zurücksetzen wenn am Boden, sonst herunterzählen.
	_coyote_timer = coyote_time if is_on_floor() else _coyote_timer - delta
	_jump_buffer_timer -= delta


func _update_animations(_delta: float) -> void:
	if is_on_floor():
		if abs(velocity.x) <= 10:
			sprite.play("idle")
		else:
			sprite.play("run")
			sprite.flip_h = velocity.x < 0
	else:
		if velocity.y > 0:
			sprite.play("jump")
		elif velocity.y < 0:
			sprite.play("fall")


# --- Death & Out of Screen Check ---

func _check_fell_out_of_screen() -> void:
	if camera == null: return

	var viewport_height := get_viewport_rect().size.y
	var camera_bottom := camera.global_position.y + (viewport_height * 0.5) / camera.zoom.y

	if global_position.y-32 > camera_bottom:
		_die()


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	Globals.player_died.emit()
	print("is dead")
