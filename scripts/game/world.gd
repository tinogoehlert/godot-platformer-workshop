class_name World extends Node2D

func _ready():
	if $CanvasModulate != null: $CanvasModulate.visible = true
	if $CanvasModulate != null: $CanvasLayer.visible = true
	Globals.restart_game.connect(_restart)
	

func _restart():
	get_tree().reload_current_scene()
