extends Node
class_name Stage10SettlementParity

signal parity_changed(snapshot: Dictionary)
signal parity_building_built(building_id: String, level: int)
signal parity_building_upgraded(building_id: String, level: int)
signal camp_tier_changed(tier: Dictionary)
signal encounter_available(encounter: Dictionary)
signal encounter_resolved(encounter_id: String, choice_id: String, rewards: Dictionary)
signal extension_quest_completed(quest_id: String, reward: Dictionary)
signal activity_changed(text: String)

const LEGACY_BUILDINGS := {
	"house":{"index":1,"name":"ДОМ","cost":{"wood":30},"description":"Рюкзак +10"},
	"gold_mine":{"index":5,"name":"ЗОЛОТАЯ ШАХТА","cost":{"wood":80,"stone":60,"food":30},"description":"+1 золото каждые 4 с","production":{"gold":4.0}},
	"forge":{"index":6,"name":"КУЗНИЦА","cost":{"stone":120,"gold":15},"description":"Рабочие: +1 добыча за уровень"},
	"workshop":{"index":7,"name":"МАСТЕРСКАЯ","cost":{"wood":90,"stone":60},"description":"Рабочие: +10% скорость, +2 рюкзак за уровень"},
	"residential_house":{"index":8,"name":"ЖИЛОЙ ДОМ","cost":{"wood":70,"stone":40},"description":"+2 жителя-добытчика","population":2},
	"big_house":{"index":10,"name":"БОЛЬШОЙ ДОМ","cost":{"wood":120,"stone":80,"food":50},"description":"+3 жителя-добытчика","population":3},
	"farm":{"index":16,"name":"ФЕРМА","cost":{"wood":180,"stone":120,"gold":40},"description":"+1 еда каждые 3 с","production":{"food":3.0}},
}
const BUILDING_ORDER := ["house","gold_mine","forge","workshop","residential_house","big_house","farm"]
const CAMP_TIERS := [
	{"index":0,"id":"camp-site","min_buildings":0,"name":"СТОЯНКА"},
	{"index":1,"id":"camp","min_buildings":3,"name":"ЛАГЕРЬ"},
	{"index":2,"id":"settlement","min_buildings":6,"name":"ПОСЕЛЕНИЕ"},
	{"index":3,"id":"fortress","min_buildings":10,"name":"КРЕПОСТЬ"},
	{"index":4,"id":"citadel","min_buildings":14,"name":"ЦИТАДЕЛЬ"},
]
const ENCOUNTERS := [
	{"id":"forest-spoils","wave":1,"title":"Трофеи лесного рейда","text":"После первой ночи у стены остались пригодные припасы. Забрать можно только одну часть добычи.","choices":[{"id":"timber","label":"Забрать связки древесины","rewards":{"wood":25}},{"id":"coins","label":"Собрать потерянные монеты","rewards":{"gold":10}},{"id":"leave","label":"Оставить всё как есть","rewards":{}}]},
	{"id":"stone-cache","wave":2,"title":"Расколотый обоз великанов","text":"Среди обломков найден запас камня и строительного леса. Лагерь успеет вывезти только один груз.","choices":[{"id":"stone","label":"Вывезти камень","rewards":{"stone":22}},{"id":"mixed","label":"Забрать смешанный груз","rewards":{"wood":16,"stone":10}},{"id":"leave","label":"Не задерживаться","rewards":{}}]},
	{"id":"hunter-trail","wave":3,"title":"Свежий звериный след","text":"Охотники нашли богатую добычу после звериного рейда. Можно сделать запас еды или сохранить лучшие шкуры.","choices":[{"id":"food","label":"Заготовить мясо","rewards":{"food":30}},{"id":"pelts","label":"Снять лучшие шкуры","rewards":{"food":12,"pelts":1}},{"id":"leave","label":"Оставить след зверям","rewards":{}}]},
	{"id":"pirate-chest","wave":4,"title":"Пиратский сундук","text":"Уцелевший сундук заперт плохо. Внутри — монеты и строительные припасы, но унести всё не получится.","choices":[{"id":"gold","label":"Забрать золото","rewards":{"gold":18}},{"id":"supplies","label":"Забрать припасы","rewards":{"wood":18,"stone":18}},{"id":"leave","label":"Не трогать сундук","rewards":{}}]},
]
const LEGACY_COUNT_IDS := ["lumber_camp","quarry","hunting_lodge","stone_wall","watchtower","cannon","barracks","kennel","infirmary","training_ground"]
const QUEST_HINTS := {
	"wood30":"Подойди к деревьям — сбор автоматический. Затем вернись к складу.",
	"lumber":"Подойди к строительной площадке и построй лесопилку.",
	"food20":"Собирай ягодные кусты или добывай еду охотой.",
	"bear1":"Найди медведя за пределами лагеря и победи его.",
	"workers2":"Найми двух рабочих в меню лагеря.",
	"boar1":"Найди кабана вне лагеря и победи его.",
	"carc3":"После охоты находи туши и разделывай их.",
	"deer1":"Найди оленя вне лагеря и победи его.",
	"house":"Построй ДОМ — он увеличит вместимость рюкзака.",
}

var levels: Dictionary = {"house":0,"gold_mine":0,"forge":0,"workshop":0,"residential_house":0,"big_house":0,"farm":0}
var production_timers: Dictionary = {"gold_mine":0.0,"farm":0.0}
var resolved_encounters: Array[String] = []
var active_encounter_id := ""
var extension_house_quest_completed := false
var last_activity := "Развивай поселение: доступно 7 legacy-зданий."
var _resource_manager = null
var _settlement_manager = null
var _progression_manager = null
var _wave_manager = null
var _last_tier_index := -1
var _loaded_once := false

func _ready() -> void:
	add_to_group("stage10_settlement_parity")
	call_deferred("_bind")

func _process(delta: float) -> void:
	_bind_managers()
	_process_production(delta)
	_update_house_quest()

func _bind() -> void:
	_bind_managers()
	if _settlement_manager != null and _settlement_manager.has_signal("settlement_changed"):
		var cb := Callable(self,"_on_settlement_changed")
		if not _settlement_manager.is_connected("settlement_changed",cb): _settlement_manager.connect("settlement_changed",cb)
	if _wave_manager != null and _wave_manager.has_signal("wave_ended"):
		var wcb := Callable(self,"_on_wave_ended")
		if not _wave_manager.is_connected("wave_ended",wcb): _wave_manager.connect("wave_ended",wcb)
	_refresh_tier(false)
	_emit_snapshot()

func _bind_managers() -> void:
	if _resource_manager == null or not is_instance_valid(_resource_manager): _resource_manager=get_tree().get_first_node_in_group("resource_manager")
	if _settlement_manager == null or not is_instance_valid(_settlement_manager): _settlement_manager=get_tree().get_first_node_in_group("settlement_manager")
	if _progression_manager == null or not is_instance_valid(_progression_manager): _progression_manager=get_tree().get_first_node_in_group("progression_manager")
	if _wave_manager == null or not is_instance_valid(_wave_manager): _wave_manager=get_tree().get_first_node_in_group("raid_manager")

func get_building_level(building_id: String) -> int: return int(levels.get(building_id,0))
func get_build_cost(building_id: String) -> Dictionary:
	if not LEGACY_BUILDINGS.has(building_id): return {}
	return (LEGACY_BUILDINGS[building_id]["cost"] as Dictionary).duplicate(true)
func get_upgrade_cost(building_id: String) -> Dictionary:
	if not LEGACY_BUILDINGS.has(building_id) or get_building_level(building_id)<=0: return {}
	var def:Dictionary=LEGACY_BUILDINGS[building_id]; var lvl:=get_building_level(building_id); var index:=int(def["index"]); var cost:Dictionary={"gold":int(round(float(20+index*6)*pow(1.6,lvl-1)))}
	for key in (def["cost"] as Dictionary).keys():
		if str(key)=="gold": continue
		cost[str(key)]=int(ceil(float(def["cost"][key])*0.25*pow(1.2,lvl-1)))
	return cost
func can_build(building_id:String)->bool:
	_bind_managers(); return LEGACY_BUILDINGS.has(building_id) and get_building_level(building_id)==0 and _resource_manager!=null and _resource_manager.can_afford_stored(get_build_cost(building_id))
func build(building_id:String)->bool:
	if not can_build(building_id) or not _resource_manager.spend_stored(get_build_cost(building_id)): return false
	levels[building_id]=1; _spawn_population_for_building(building_id,int(LEGACY_BUILDINGS[building_id].get("population",0)))
	_set_activity("Построено: %s"%str(LEGACY_BUILDINGS[building_id]["name"])); parity_building_built.emit(building_id,1); _refresh_tier(true); _update_house_quest(); _emit_snapshot(); _request_save(); return true
func can_upgrade(building_id:String)->bool:
	_bind_managers(); return LEGACY_BUILDINGS.has(building_id) and get_building_level(building_id)>0 and _resource_manager!=null and _resource_manager.can_afford_stored(get_upgrade_cost(building_id))
func upgrade(building_id:String)->bool:
	if not can_upgrade(building_id): return false
	var cost:=get_upgrade_cost(building_id)
	if not _resource_manager.spend_stored(cost): return false
	levels[building_id]=get_building_level(building_id)+1
	if int(LEGACY_BUILDINGS[building_id].get("population",0))>0: _spawn_population_for_building(building_id,1)
	_set_activity("%s улучшен до уровня %d"%[str(LEGACY_BUILDINGS[building_id]["name"]),get_building_level(building_id)]); parity_building_upgraded.emit(building_id,get_building_level(building_id)); _emit_snapshot(); _request_save(); return true

func get_hero_carry_bonus()->int:
	var lvl:=get_building_level("house"); return 0 if lvl<=0 else 10+maxi(0,lvl-1)*6
func get_worker_harvest_bonus()->int: return get_building_level("forge")
func get_worker_speed_multiplier()->float: return 1.0+0.1*float(get_building_level("workshop"))
func get_worker_carry_bonus()->int: return 2*get_building_level("workshop")
func get_resident_count()->int:
	return get_tree().get_nodes_in_group("stage10_residents").size() if is_inside_tree() else 0

func get_legacy_building_count()->int:
	var count:=0
	if _settlement_manager!=null:
		for id in LEGACY_COUNT_IDS:
			if int(_settlement_manager.get_building_level(id))>0: count+=1
	for id in BUILDING_ORDER:
		if get_building_level(id)>0: count+=1
	return count
func get_camp_tier()->Dictionary:
	var count:=get_legacy_building_count(); var tier:Dictionary=CAMP_TIERS[0]
	for candidate in CAMP_TIERS:
		if count>=int(candidate["min_buildings"]): tier=candidate
	return {"index":int(tier["index"]),"id":str(tier["id"]),"name":str(tier["name"]),"buildings":count,"total":17}

func get_current_encounter()->Dictionary:
	if active_encounter_id.is_empty(): return {}
	for encounter in ENCOUNTERS:
		if str(encounter["id"])==active_encounter_id: return encounter.duplicate(true)
	return {}
func resolve_encounter(choice_id:String)->bool:
	var encounter:=get_current_encounter(); if encounter.is_empty(): return false
	var selected:Dictionary={}
	for choice in encounter["choices"]:
		if str(choice["id"])==choice_id: selected=choice; break
	if selected.is_empty(): return false
	_bind_managers(); if _resource_manager==null: return false
	var rewards:Dictionary=selected.get("rewards",{})
	for key in rewards.keys(): _resource_manager.add_stored(str(key),int(rewards[key]))
	var id:=str(encounter["id"]); if not resolved_encounters.has(id): resolved_encounters.append(id)
	active_encounter_id=""; _set_activity("Событие завершено: %s"%str(encounter["title"])); encounter_resolved.emit(id,choice_id,rewards.duplicate(true)); _emit_snapshot(); _request_save(); return true

func get_extension_quest()->Dictionary:
	if _progression_manager==null: return {"active":false}
	var base_quest:Dictionary=_progression_manager.get_current_quest()
	if not bool(base_quest.get("complete",false)): return {"active":false}
	if extension_house_quest_completed: return {"active":false,"complete":true}
	return {"active":true,"id":"house","title":"Построй ДОМ","progress":"%d/1"%(1 if get_building_level("house")>0 else 0),"reward":{"wood":60},"hint":QUEST_HINTS["house"]}
func get_player_hint()->String:
	if _progression_manager==null: return ""
	var quest:Dictionary=_progression_manager.get_current_quest()
	if bool(quest.get("complete",false)):
		var ext:=get_extension_quest(); return str(ext.get("hint","")) if bool(ext.get("active",false)) else ""
	return str(QUEST_HINTS.get(str(quest.get("id","")),""))

func get_snapshot()->Dictionary:
	return {"levels":levels.duplicate(true),"legacy_buildings":get_legacy_building_count(),"camp_tier":get_camp_tier(),"resolved_encounters":resolved_encounters.duplicate(),"active_encounter":get_current_encounter(),"house_quest_completed":extension_house_quest_completed,"extension_quest":get_extension_quest(),"player_hint":get_player_hint(),"residents":get_resident_count(),"activity":last_activity}
func export_state()->Dictionary:
	return {"levels":levels.duplicate(true),"production_timers":production_timers.duplicate(true),"resolved_encounters":resolved_encounters.duplicate(),"active_encounter_id":active_encounter_id,"house_quest_completed":extension_house_quest_completed,"last_activity":last_activity}
func import_state(data:Dictionary)->void:
	for id in BUILDING_ORDER: levels[id]=maxi(0,int((data.get("levels",{}) as Dictionary).get(id,0)))
	for id in production_timers.keys(): production_timers[id]=maxf(0.0,float((data.get("production_timers",{}) as Dictionary).get(id,0.0)))
	resolved_encounters.clear(); for value in data.get("resolved_encounters",[]):
		var id:=str(value); if ENCOUNTERS.any(func(item): return str(item["id"])==id) and not resolved_encounters.has(id): resolved_encounters.append(id)
	active_encounter_id=str(data.get("active_encounter_id","")); extension_house_quest_completed=bool(data.get("house_quest_completed",false)); last_activity=str(data.get("last_activity",last_activity)); _loaded_once=true; call_deferred("_rebuild_residents"); _refresh_tier(false); _emit_snapshot()

func _process_production(delta:float)->void:
	if _resource_manager==null: return
	for id in ["gold_mine","farm"]:
		var lvl:=get_building_level(id); if lvl<=0: continue
		var def:Dictionary=LEGACY_BUILDINGS[id]; var prod:Dictionary=def["production"]
		for resource in prod.keys():
			var interval:=maxf(0.25,float(prod[resource])*pow(0.94,lvl-1)); production_timers[id]=float(production_timers.get(id,0.0))+delta
			while float(production_timers[id])>=interval:
				production_timers[id] = float(production_timers[id]) - interval
				var amount := lvl
				var meta = get_tree().get_first_node_in_group("meta_progression_manager")
				if meta != null and meta.has_method("get_production_multiplier"):
					amount = maxi(1, int(round(float(amount) * float(meta.get_production_multiplier()))))
				_resource_manager.add_stored(str(resource), amount)
func _on_wave_ended(number:int)->void:
	if number<=0 or not active_encounter_id.is_empty(): return
	if not _loaded_once and resolved_encounters.is_empty() and number>1:
		for item in ENCOUNTERS:
			if int(item["wave"])<number: resolved_encounters.append(str(item["id"]))
	_loaded_once=true
	for item in ENCOUNTERS:
		var id:=str(item["id"]); if int(item["wave"])<=number and not resolved_encounters.has(id): active_encounter_id=id; encounter_available.emit(item.duplicate(true)); _emit_snapshot(); return
func _on_settlement_changed(_snapshot:Dictionary)->void: _refresh_tier(true); _emit_snapshot()
func _refresh_tier(announce:bool)->void:
	var tier:=get_camp_tier(); var index:=int(tier["index"])
	if _last_tier_index<0: _last_tier_index=index
	elif index>_last_tier_index:
		_last_tier_index=index; if announce: _set_activity("Лагерь развился: %s"%str(tier["name"])); camp_tier_changed.emit(tier)
	else: _last_tier_index=index
func _update_house_quest()->void:
	if extension_house_quest_completed or _progression_manager==null or not bool(_progression_manager.get_current_quest().get("complete",false)) or get_building_level("house")<=0: return
	extension_house_quest_completed=true; _bind_managers(); var reward:Dictionary={"wood":60}; if _resource_manager!=null: _resource_manager.add_stored("wood",60); extension_quest_completed.emit("house",reward); _set_activity("Задание выполнено: Построй ДОМ"); _request_save(); _emit_snapshot()
func _spawn_population_for_building(_building_id:String,count:int)->void:
	if count<=0 or not is_inside_tree(): return
	var WorkerScript=load("res://scripts/camp_worker.gd")
	for i in range(count):
		var worker=WorkerScript.new(); worker.name="Resident_%d_%d"%[Time.get_ticks_msec(),i]; worker.worker_id=1000+get_tree().get_nodes_in_group("stage10_residents").size()+1; worker.preferred_resource=["wood","stone","food"][worker.worker_id%3]; worker.position=Vector3(float((worker.worker_id%5)-2)*1.4,0.0,4.0+float(worker.worker_id%3)); add_child(worker); worker.add_to_group("stage10_residents")
func _rebuild_residents()->void:
	for node in get_tree().get_nodes_in_group("stage10_residents"): if node!=null and is_instance_valid(node): node.queue_free()
	await get_tree().process_frame
	var target:=0; var r:=get_building_level("residential_house"); if r>0: target+=2+maxi(0,r-1)
	var b:=get_building_level("big_house"); if b>0: target+=3+maxi(0,b-1)
	_spawn_population_for_building("loaded",target)
func _set_activity(text:String)->void: last_activity=text; activity_changed.emit(text)
func _emit_snapshot()->void: parity_changed.emit(get_snapshot())
func _request_save()->void:
	var saver=get_tree().get_first_node_in_group("save_manager"); if saver!=null and saver.has_method("save_game"): saver.call_deferred("save_game")
func reset_for_test()->void:
	for id in BUILDING_ORDER: levels[id]=0
	production_timers={"gold_mine":0.0,"farm":0.0}; resolved_encounters.clear(); active_encounter_id=""; extension_house_quest_completed=false; last_activity=""; _last_tier_index=-1; _loaded_once=false; _emit_snapshot()
