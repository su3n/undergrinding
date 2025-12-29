extends Node
signal changed

# --- Player ---
var money: int = 0
var click_power: float = 1.0
var pickaxe_level: int = 0

# --- Schächte ---
var shafts: Array[Dictionary] = []
var active_shaft_index: int = -1  # -1 = kein Schacht aktiv

# --- Worker (pro Schacht) ---
var worker_power: float = 0.3

# --- Balance ---
var base_rock_hp: float = 10.0
var rock_hp_growth_by_depth: float = 1.35
var value_growth_by_depth: float = 1.45

# --- Costs ---
var pickaxe_base_cost: int = 25
var first_shaft_cost: int = 100
var next_shaft_base_cost: int = 200
var next_shaft_cost: int
var next_pickaxe_cost: int
var worker_base_cost: int = 50

func _init():
	_calc_next_shaft_price()
	_calc_next_pickaxe_price()

func reset_run() -> void:
	money = 0
	click_power = 1.0
	shafts.clear()
	active_shaft_index = -1
	emit_signal("changed")

# -------------------
# Surface Phase
# -------------------

func manual_click_work() -> void:
	# Initial: Geld verdienen überirdisch
	money += 100
	emit_signal("changed")

func buy_pickaxe() -> bool:
	var cost = next_pickaxe_cost
	if money < cost:
		return false
	money -= cost
	click_power += 3.0
	pickaxe_level += 1
	_calc_next_pickaxe_price()
	emit_signal("changed")
	return true

# -------------------
# Mining Phase
# -------------------

func has_shaft() -> bool:
	return active_shaft_index >= 0 and active_shaft_index < shafts.size()

func manual_mine_click() -> void:
	if not has_shaft():
		return
	_damage_rock(active_shaft_index, click_power)
	emit_signal("changed")

func buy_worker_for_active_shaft() -> bool:
	if not has_shaft():
		return false
	if money < worker_base_cost:
		return false

	money -= worker_base_cost
	shafts[active_shaft_index]["workers"] += 1
	emit_signal("changed")
	return true

func buy_new_shaft() -> bool:
	# erster Schacht: depth 0
	if shafts.is_empty():
		if money < first_shaft_cost:
			return false
		money -= first_shaft_cost
		shafts.append(_make_shaft(0))
		active_shaft_index = 0
		_calc_next_shaft_price()
		emit_signal("changed")
		return true

	# weitere Schächte
	var next_depth := shafts.size()
	if money < next_shaft_cost:
		return false
	money -= next_shaft_cost
	shafts.append(_make_shaft(next_depth))
	active_shaft_index = shafts.size() - 1
	_calc_next_shaft_price()
	emit_signal("changed")
	return true

func set_active_shaft(index: int) -> void:
	if index < 0 or index >= shafts.size():
		return
	active_shaft_index = index
	emit_signal("changed")

# -------------------
# Automation / Tick
# -------------------

func tick(delta: float) -> void:
	if shafts.is_empty():
		return

	for shaft_index in range(shafts.size()):
		var shaft_workers: int = shafts[shaft_index]["workers"]
		if shaft_workers <= 0:
			continue
		var power := float(shaft_workers) * worker_power
		_damage_rock(shaft_index, power * delta)

	emit_signal("changed")

# -------------------
# Internals
# -------------------
func _calc_next_pickaxe_price() -> void:
	if pickaxe_level == 0:
		next_pickaxe_cost = pickaxe_base_cost
		return
	
	next_pickaxe_cost = int(round((pickaxe_level * 1.5) * pickaxe_base_cost))

func _calc_next_shaft_price() -> void:
	if shafts.is_empty():
		next_shaft_cost = first_shaft_cost
		return

	var next_depth := shafts.size()
	next_shaft_cost = next_shaft_base_cost * next_depth
	
	print("Next shaft price: " + str(next_shaft_cost))

func _make_shaft(depth: int) -> Dictionary:
	print('_make_shaft')
	var hp := _rock_hp_for_depth(depth)
	return {
		"depth": depth,
		"length": 0,
		"rock_hp_max": hp,
		"rock_hp": hp,
		"workers": 0
	}

func _damage_rock(shaft_index: int, amount: float) -> void:
	var s: Dictionary = shafts[shaft_index]
	s["rock_hp"] = float(s["rock_hp"]) - amount

	if float(s["rock_hp"]) <= 0.0:
		s["length"] = int(s["length"]) + 1
		money += _value_for_depth(int(s["depth"]))

		var hp := _rock_hp_for_depth(int(s["depth"]))
		s["rock_hp_max"] = hp
		s["rock_hp"] = hp

func _rock_hp_for_depth(depth: int) -> float:
	return base_rock_hp * pow(rock_hp_growth_by_depth, float(depth))

func _value_for_depth(depth: int) -> int:
	return int(1 * pow(value_growth_by_depth, float(depth)))
