extends Node

@onready var host: Node = $SceneHost
var current_scene: Node

const signal_config = [
	{
		"signal_name": "start_pressed",
		"scene_name": "Game"
	},
	{
		"signal_name": "quit_pressed",
		"function_name": "quit_game"
	},
	{
		"signal_name": "back_to_menu",
		"scene_name": "MainMenu"
	}
]

func _ready() -> void:
	load_scene("MainMenu")

func _get_scene_path(scene_name: String) -> String:
	var path: String = "res://scenes/" + scene_name + ".tscn"
	if FileAccess.file_exists(path):
		return path
	else:
		push_error("Angeforderte Szene existiert nicht! (" + path + ")")
		return ""

func quit_game() -> void:
	get_tree().quit()

func load_scene(scene_name: String) -> void:
	if is_instance_valid(current_scene):
		current_scene.queue_free()

	var path: String = _get_scene_path(scene_name)
	if path.is_empty():
		return

	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("Kein PackedScene: " + path)
		return

	current_scene = packed.instantiate()
	host.add_child(current_scene)

	# Wenn die Szene Signale hat, hier verbinden:
	for config in signal_config:
		if not current_scene.has_signal(config['signal_name']):
			continue

		if config.has('scene_name'):
			current_scene.connect(
				config['signal_name'], 
				Callable(self, "load_scene")
					.bind(config['scene_name'])
			)

		if config.has('function_name'):
			current_scene.connect(
				config['signal_name'], 
				Callable(self, config['function_name'])
			)
