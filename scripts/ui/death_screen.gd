extends ColorRect


func _ready():
	visible = false
	Globals.player_died.connect(_fade_in)
	pass
	
func _fade_in():
	await get_tree().create_timer(0.3).timeout
	visible = true
	
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		Globals.restart_game.emit()
