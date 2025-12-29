extends Node2D

signal back_to_menu

@onready var pause_overlay: Control = $CanvasLayer/PauseOverlay
var is_paused: bool = false

# --- HUD refs ---
@onready var money_label: Label = $CanvasLayer/HUD/VBox/MoneyLabel
@onready var phase_label: Label = $CanvasLayer/HUD/VBox/PhaseLabel
@onready var shaft_label: Label = $CanvasLayer/HUD/VBox/ShaftLabel
@onready var rock_label: Label = $CanvasLayer/HUD/VBox/RockLabel
@onready var click_power_label: Label = $CanvasLayer/HUD/VBox/ClickPowerLabel

@onready var work_button: Button = $CanvasLayer/HUD/VBox/WorkButton
@onready var pickaxe_button: Button = $CanvasLayer/HUD/VBox/PickaxeButton
@onready var new_shaft_button: Button = $CanvasLayer/HUD/VBox/NewShaftButton
@onready var mine_button: Button = $CanvasLayer/HUD/VBox/MineButton
@onready var worker_button: Button = $CanvasLayer/HUD/VBox/WorkerButton

func _ready() -> void:
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	process_mode = Node.PROCESS_MODE_ALWAYS

	# UI live halten
	GameState.changed.connect(_refresh_ui)
	_refresh_ui()

func _process(delta: float) -> void:
	# Wichtig: weil process_mode ALWAYS ist, läuft _process auch im Pause-Menü -> daher guard
	if get_tree().paused:
		return
	GameState.tick(delta)

func _refresh_ui() -> void:
	money_label.text = "Money: %d" % GameState.money
	click_power_label.text = "Click-Power: %d" % GameState.click_power
	
	pickaxe_button.text = "Buy Pickaxe [%d G]" % [int(GameState.next_pickaxe_cost)]
	new_shaft_button.text = "Dig deeper [%d G]" % [int(GameState.next_shaft_cost)]

	var has_shaft := GameState.has_shaft()
	phase_label.text = "Phase: %s" % ("Mining" if has_shaft else "Surface")

	if has_shaft:
		var s: Dictionary = GameState.shafts[GameState.active_shaft_index]
		shaft_label.text = "Shaft depth: %d | length: %d" % [int(s["depth"]), int(s["length"])]
		rock_label.text = "Rock: %.1f / %.1f" % [float(s["rock_hp"]), float(s["rock_hp_max"])]
	else:
		shaft_label.text = "No shaft yet."
		rock_label.text = ""

	# Buttons aktivieren/deaktivieren
	pickaxe_button.disabled = GameState.money < GameState.next_pickaxe_cost
	new_shaft_button.disabled = GameState.money < GameState.next_shaft_cost
	mine_button.disabled = not has_shaft
	worker_button.disabled = not has_shaft

# --- HUD button callbacks ---
func _on_work_button_pressed() -> void:
	GameState.manual_click_work()

func _on_pickaxe_button_pressed() -> void:
	GameState.buy_pickaxe()

func _on_new_shaft_button_pressed() -> void:
	GameState.buy_new_shaft()

func _on_mine_button_pressed() -> void:
	GameState.manual_mine_click()

func _on_worker_button_pressed() -> void:
	GameState.buy_worker_for_active_shaft()

# --- Pause bleibt wie bei dir ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

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
