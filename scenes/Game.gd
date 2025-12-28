extends Node2D

signal back_to_menu

@onready var pause_overlay: Control = $CanvasLayer/PauseOverlay
var is_paused: bool = false

func _ready() -> void:
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS # Ansonsten friert das Overlay auch ein!
	process_mode = Node.PROCESS_MODE_ALWAYS # Ansonsten bekommt man Inputs nicht mehr mit!

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ESC-Taste
		toggle_pause()
		get_viewport().set_input_as_handled() # verhindert Doppelverarbeitung

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_overlay.visible = is_paused


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	pause_overlay.visible = false
	is_paused = false


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	emit_signal("back_to_menu")
