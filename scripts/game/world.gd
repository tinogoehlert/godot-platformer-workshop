class_name World extends Node2D

@onready var cm = $CanvasModulate
@onready var cl = $CanvasLayer

func _ready():
	if cm != null: cm.visible = true
	if cl != null: cl.visible = true
	Globals.restart_game.connect(_restart)
	

func _restart():
	get_tree().reload_current_scene()
