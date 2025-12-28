extends Control

signal start_pressed
signal quit_pressed

func _on_start_button_pressed() -> void:
	emit_signal("start_pressed")

func _on_quit_button_pressed() -> void:
	emit_signal("quit_pressed")
