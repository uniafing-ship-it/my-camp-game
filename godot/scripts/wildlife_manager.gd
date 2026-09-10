extends Node3D
class_name WildlifeManager

signal animal_killed(kind: String, food: int, pelts: int)
signal carcass_skinned(kind: String)

const AnimalScript = preload("res://scripts/wildlife_animal.gd")
const CarcassScript = preload("res://scripts/carcass.gd")

const DEFINITIONS := {
	"bear": {"hp":20, "food_min":10, "food_max":14, "pelt":0.6, "aggro":8.0, "speed":3.2, "flee":false, "damage":8},
	"boar": {"hp":12, "food_min":6, "food_max":10, "pelt":0.4, "aggro":5.5, "speed":3.7, "flee":false, "damage":5},
	"deer": {"hp":8, "food_min":8, "food_max":12, "pelt":0.3, "aggro":0.0, "speed":4.8, "flee":true, "damage":0},
	"rabbit": {"hp":3, "food_min":2, "food_max":4, "pelt":0.0, "aggro":0.0, "speed":5.8, "flee":true, "damage":0},
}
const MOBILE_CAPS := {"bear":2, "boar":3, "deer":4, "rabbit":5}

@export var respawn_interval: float = 7.5
@export var world_radius: float = 27.0

var _respawn_left := 1.0
var _serial := 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("wildlife_manager")
	_rng.seed = 2026091007
	call_deferred("_initial_spawn")

func _process(delta: float) -> void:
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		_respawn_left = respawn_interval
		_refill_one_each_kind()

func _initial_spawn() -> void:
	for kind in ["bear", "boar", "deer", "rabbit"]:
		var initial := maxi(1, int(MOBILE_CAPS[kind]) - 1)
		for _i in range(initial):
			_spawn(kind)

func _refill_one_each_kind() -> void:
	var counts := {"bear":0, "boar":0, "deer":0, "rabbit":0}
	for animal in get_tree().get_nodes_in_group("wildlife"):
		if animal != null and is_instance_valid(animal):
			var kind := str(animal.get("animal_kind"))
			if counts.has(kind): counts[kind] = int(counts[kind]) + 1
	for kind in counts.keys():
		if int(counts[kind]) < int(MOBILE_CAPS[kind]):
			_spawn(str(kind))

func _spawn(kind: String) -> void:
	if not DEFINITIONS.has(kind):
		return
	var def: Dictionary = DEFINITIONS[kind]
	var animal = AnimalScript.new()
	_serial += 1
	animal.name = "%s_%d" % [kind.capitalize(), _serial]
	animal.animal_kind = kind
	animal.max_health = int(def["hp"])
	animal.food_min = int(def["food_min"])
	animal.food_max = int(def["food_max"])
	animal.pelt_chance = float(def["pelt"])
	animal.aggro_radius = float(def["aggro"])
	animal.move_speed = float(def["speed"])
	animal.flee = bool(def["flee"])
	animal.attack_damage = int(def["damage"])
	var angle := _rng.randf_range(0.0, TAU)
	var radius := _rng.randf_range(13.0, world_radius)
	animal.position = Vector3(cos(angle) * radius, 0.1, sin(angle) * radius)
	animal.died.connect(_on_animal_died)
	add_child(animal)

func _on_animal_died(kind: String, food_min: int, food_max: int, pelt_chance: float, death_position: Vector3) -> void:
	var settlement = get_tree().get_first_node_in_group("settlement_manager")
	var hunting_level := int(settlement.get_building_level("hunting_lodge")) if settlement != null else 0
	var food_mult := 1.0 + 0.25 * float(hunting_level)
	var food := maxi(1, int(round(_rng.randf_range(float(food_min), float(food_max)) * food_mult)))
	var pelts := 1 if _rng.randf() < pelt_chance else 0
	var resources = get_tree().get_first_node_in_group("resource_manager")
	if resources != null:
		resources.add_stored("food", food)
		if pelts > 0:
			resources.add_stored("pelts", pelts)
		if resources.has_method("report_activity"):
			resources.report_activity("Добыча с %s: +%d еды%s" % [_animal_name(kind), food, ", +%d шкура" % pelts if pelts > 0 else ""])
	animal_killed.emit(kind, food, pelts)
	_spawn_carcass(kind, death_position, maxi(1, int(round(float(food) * 0.5))))

func _spawn_carcass(kind: String, position: Vector3, food: int) -> void:
	var carcass = CarcassScript.new()
	carcass.animal_kind = kind
	carcass.food_amount = food
	if kind == "bear" or kind == "boar":
		carcass.pelt_amount = 1
	elif kind == "deer":
		carcass.pelt_amount = 1 if _rng.randf() < 0.5 else 0
	else:
		carcass.pelt_amount = 0
	carcass.position = position
	carcass.skinned.connect(_on_carcass_skinned)
	add_child(carcass)

func _on_carcass_skinned(kind: String, _food: int, _pelts: int) -> void:
	carcass_skinned.emit(kind)

func spawn_for_test(kind: String) -> Node:
	var before := get_tree().get_nodes_in_group("wildlife").size()
	_spawn(kind)
	var animals := get_tree().get_nodes_in_group("wildlife")
	return animals[animals.size() - 1] if animals.size() > before else null

func _animal_name(kind: String) -> String:
	match kind:
		"bear": return "медведя"
		"boar": return "кабана"
		"deer": return "оленя"
		"rabbit": return "кролика"
	return kind
