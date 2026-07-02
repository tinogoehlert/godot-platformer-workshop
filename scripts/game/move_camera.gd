class_name MoveCamera extends Camera2D

@export var speed: float = 10
@export var delay: float = 2
@export var active: bool = true

@export_group("Shake")
@export var shake_strength: float = 8.0
@export var shake_decay: float = 5.0

var delay_timer: Timer = Timer.new()
var _curr_speed: float = 0
var _shake_amount: float = 0.0


func _ready():
	add_child(delay_timer)
	delay_timer.one_shot = true
	delay_timer.start(delay)
	Globals.player_died.connect(func():
		active = false
	)


func shake(strength: float = shake_strength) -> void:
	_shake_amount = strength


func _physics_process(delta):
	if delay_timer.is_stopped() && active:
		_curr_speed = lerp(_curr_speed, speed, 0.01)
		global_position += Vector2.UP * _curr_speed * delta
	
	_apply_shake(delta)


func _apply_shake(delta: float) -> void:
	# shake via offset
	if _shake_amount > 0.0:
		offset = Vector2(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
		_shake_amount = lerpf(_shake_amount, 0.0, shake_decay * delta)
		if _shake_amount < 0.1:
			_shake_amount = 0.0
			offset = Vector2.ZERO
