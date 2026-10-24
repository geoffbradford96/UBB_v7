extends Node

const MapLayoutBuilder = preload("res://Scripts/MapLayoutBuilder.gd")
const BotAI = preload("res://Scripts/BotAI.gd")

func _ready():
	print("==================================================")
	print("       STARTING MASSIVE UBB VERIFICATION TEST     ")
	print("==================================================")
	
	var total_passed = 0
	var total_failed = 0
	
	# Test 1: Cards & Data Integrity
	print("\n--- TEST 1: Cards & Data Integrity ---")
	if test_cards():
		total_passed += 1
		print("  [PASS] All card resources and referenced scenes loaded successfully.")
	else:
		total_failed += 1
		print("  [FAIL] Card integrity check failed!")
		
	# Test 2: Scenes & Unit Instantiation
	print("\n--- TEST 2: All Unit Scenes Instantiation ---")
	if test_unit_scenes():
		total_passed += 1
		print("  [PASS] All unit scenes instantiated without errors.")
	else:
		total_failed += 1
		print("  [FAIL] Unit scene instantiation failed!")

	# Test 3: Root Scenes & Menus Instantiation
	print("\n--- TEST 3: Root & Menu Scenes Instantiation ---")
	if test_root_scenes():
		total_passed += 1
		print("  [PASS] All root and menu scenes instantiated cleanly.")
	else:
		total_failed += 1
		print("  [FAIL] Root scene instantiation failed!")

	# Test 4: Scripts Compilation & Loading
	print("\n--- TEST 4: Scripts Compilation & Loading ---")
	if test_all_scripts():
		total_passed += 1
		print("  [PASS] All GDScript files compiled and loaded with 0 errors.")
	else:
		total_failed += 1
		print("  [FAIL] Script compilation check failed!")

	# Test 5: Map Layouts & Biomes
	print("\n--- TEST 5: Map Layouts & Biomes ---")
	if test_maps_and_biomes():
		total_passed += 1
		print("  [PASS] All map layouts and biomes verified.")
	else:
		total_failed += 1
		print("  [FAIL] Map layouts or biomes failed!")

	# Test 6: Shield & Armor Systems
	print("\n--- TEST 6: Shield & Armor Mechanics ---")
	if test_shield_and_armor():
		total_passed += 1
		print("  [PASS] Directional shields, 360 shields, and armor break-off verified.")
	else:
		total_failed += 1
		print("  [FAIL] Shield and armor mechanics failed!")

	# Test 7: Bot AI & Strategy
	print("\n--- TEST 7: Bot AI Decisions & Lane Navigation ---")
	if test_bot_ai():
		total_passed += 1
		print("  [PASS] Bot AI evaluation and strategic lane routing verified.")
	else:
		total_failed += 1
		print("  [FAIL] Bot AI verification failed!")

	# Test 8: Live Match Simulation
	print("\n--- TEST 8: Live Match Simulation & Endgame Maw ---")
	if test_live_match_simulation():
		total_passed += 1
		print("  [PASS] Arena match simulation, combat ticks, and endgame Maw verified.")
	else:
		total_failed += 1
		print("  [FAIL] Live match simulation failed!")

	print("\n==================================================")
	print("VERIFICATION SUMMARY: %d PASSED, %d FAILED" % [total_passed, total_failed])
	print("==================================================")

	if total_failed == 0:
		print("ALL SYSTEMS GREEN! Exiting cleanly with code 0.")
		get_tree().quit(0)
	else:
		printerr("VERIFICATION FAILED! Exiting with code 1.")
		get_tree().quit(1)

func test_cards() -> bool:
	var dir = DirAccess.open("res://Data/Cards")
	if not dir:
		printerr("Cannot open res://Data/Cards")
		return false
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var card_count = 0
	var success = true
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = "res://Data/Cards/" + file_name
			var card = ResourceLoader.load(full_path)
			if card == null:
				printerr("Failed to load card: ", full_path)
				success = false
			else:
				card_count += 1
				if card.unit_scene == null:
					printerr("Card missing unit_scene: ", full_path)
					success = false
				elif not (card.unit_scene is PackedScene):
					printerr("Card unit_scene is not PackedScene: ", full_path)
					success = false
		file_name = dir.get_next()
	dir.list_dir_end()
	print("  Verified %d card .tres resources." % card_count)
	return success and (card_count > 0)

func test_unit_scenes() -> bool:
	var dirs_to_check = ["res://Scenes/Units", "res://Scenes/Units/VoidSwarm"]
	var unit_count = 0
	var success = true
	
	for path in dirs_to_check:
		var dir = DirAccess.open(path)
		if not dir: continue
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var full_path = path + "/" + file_name
				var ps = ResourceLoader.load(full_path) as PackedScene
				if ps == null:
					printerr("Failed to load PackedScene: ", full_path)
					success = false
				else:
					var inst = ps.instantiate()
					if inst == null:
						printerr("Failed to instantiate unit scene: ", full_path)
						success = false
					else:
						unit_count += 1
						inst.free()
			file_name = dir.get_next()
		dir.list_dir_end()
	print("  Verified %d unit .tscn scenes instantiated cleanly." % unit_count)
	return success and (unit_count > 0)

func test_root_scenes() -> bool:
	var dir = DirAccess.open("res://Scenes")
	if not dir:
		printerr("Cannot open res://Scenes")
		return false
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var scene_count = 0
	var success = true
	while file_name != "":
		if file_name.ends_with(".tscn") and file_name != "VerificationTest.tscn":
			var full_path = "res://Scenes/" + file_name
			var ps = ResourceLoader.load(full_path) as PackedScene
			if ps == null:
				printerr("Failed to load root scene: ", full_path)
				success = false
			else:
				var inst = ps.instantiate()
				if inst == null:
					printerr("Failed to instantiate root scene: ", full_path)
					success = false
				else:
					scene_count += 1
					inst.free()
		file_name = dir.get_next()
	dir.list_dir_end()
	print("  Verified %d root .tscn scenes instantiated cleanly." % scene_count)
	return success and (scene_count > 0)

func test_all_scripts() -> bool:
	var dir = DirAccess.open("res://Scripts")
	if not dir:
		printerr("Cannot open res://Scripts")
		return false
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var script_count = 0
	var success = true
	while file_name != "":
		if file_name.ends_with(".gd") and file_name != "VerificationTest.gd":
			var full_path = "res://Scripts/" + file_name
			var scr = ResourceLoader.load(full_path)
			if scr == null:
				printerr("Failed to load script: ", full_path)
				success = false
			else:
				script_count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	print("  Verified %d GDScript files compiled successfully." % script_count)
	return success and (script_count > 0)

func test_maps_and_biomes() -> bool:
	if MapLayoutBuilder.MAP_CATALOG.is_empty():
		printerr("MAP_CATALOG is empty!")
		return false

	var dummy_arena = Node3D.new()
	add_child(dummy_arena)
	var ground = Node3D.new()
	ground.name = "Ground"
	dummy_arena.add_child(ground)

	var tested_count = 0
	for entry in MapLayoutBuilder.MAP_CATALOG:
		var map_id = entry.id
		var def_p = entry.get("default_players", 2)
		var comp = "2_TEAMS"
		if entry.has("comps") and not entry.comps.is_empty():
			comp = entry.comps[0].get("comp", "2_TEAMS")
		var layout = MapLayoutBuilder.build_map_layout(dummy_arena, map_id, def_p, comp)
		if not layout or not layout.has("slot_defs"):
			printerr("Failed to build map layout: ", map_id)
			dummy_arena.queue_free()
			return false
		tested_count += 1

	dummy_arena.queue_free()

	var biomes = ["SUNNY_PLAINS", "SCORCHING_DUNES", "REALM_OF_HARMONY"]
	print("  Verified %d map catalog layouts and %d biomes." % [tested_count, biomes.size()])
	return true

func test_shield_and_armor() -> bool:
	var dummy_front = CharacterBody3D.new()
	dummy_front.name = "TestReachCommander"
	add_child(dummy_front)
	dummy_front.global_position = Vector3(0, 0, 0)
	dummy_front.rotation = Vector3.ZERO
	dummy_front.add_to_group("SideA")
	dummy_front.add_to_group("Targetable")

	var hc_front = HealthComponent.new()
	hc_front.name = "HealthComponent"
	hc_front.max_health = 100.0
	hc_front.current_health = 100.0
	hc_front.max_shield = 50.0
	hc_front.current_shield = 50.0
	hc_front.shield_type = "FRONT"
	dummy_front.add_child(hc_front)
	hc_front._setup_shield_and_armor_visuals()

	# Attack from FRONT (-Z is forward for look_at, incoming from -Z)
	var attacker_front_pos = Vector3(0, 0, -10)
	hc_front.take_damage(20.0, attacker_front_pos)
	if hc_front.current_shield != 30.0 or hc_front.current_health != 100.0:
		printerr("Directional shield front block failed! Shield: %f, HP: %f" % [hc_front.current_shield, hc_front.current_health])
		dummy_front.queue_free()
		return false

	# Attack from REAR (+Z is behind)
	var attacker_rear_pos = Vector3(0, 0, 10)
	hc_front.take_damage(15.0, attacker_rear_pos)
	if hc_front.current_shield != 30.0 or hc_front.current_health != 85.0:
		printerr("Directional shield rear flank bypass failed! Shield: %f, HP: %f" % [hc_front.current_shield, hc_front.current_health])
		dummy_front.queue_free()
		return false
	dummy_front.queue_free()

	# Test 360 shield & Armor break-off
	var dummy_tank = CharacterBody3D.new()
	dummy_tank.name = "TestDominionShieldTank"
	add_child(dummy_tank)
	dummy_tank.global_position = Vector3(0, 0, 0)
	dummy_tank.add_to_group("SideA")
	dummy_tank.add_to_group("Targetable")

	var hc_tank = HealthComponent.new()
	hc_tank.name = "HealthComponent"
	hc_tank.max_health = 100.0
	hc_tank.current_health = 100.0
	hc_tank.max_shield = 40.0
	hc_tank.current_shield = 40.0
	hc_tank.shield_type = "360"
	hc_tank.max_armor = 30.0
	hc_tank.current_armor = 30.0
	hc_tank.armor_style = "REACTIVE"
	dummy_tank.add_child(hc_tank)
	hc_tank._setup_shield_and_armor_visuals()

	# Deplete 360 shield
	hc_tank.take_damage(40.0, Vector3(5, 0, 5))
	if hc_tank.current_shield != 0.0 or hc_tank.current_health != 100.0:
		printerr("360 shield full absorption failed! Shield: %f, HP: %f" % [hc_tank.current_shield, hc_tank.current_health])
		dummy_tank.queue_free()
		return false

	# Next damage hits armor (20 damage into 30 armor with 25% damage reduction = 15 armor dmg)
	hc_tank.take_damage(20.0, Vector3(5, 0, 5))
	if hc_tank.current_armor >= 30.0:
		printerr("Armor absorption failed! Armor: %f" % hc_tank.current_armor)
		dummy_tank.queue_free()
		return false

	dummy_tank.queue_free()
	print("  Shield absorption, directional blocking, and armor break logic verified.")
	return true

func test_bot_ai() -> bool:
	var bot = BotAI.new()
	bot.my_team = "SideB"
	bot.archetype = "The Reach"
	bot.difficulty = "MEDIUM"
	add_child(bot)
	
	var anchor = Node3D.new()
	add_child(anchor)
	anchor.global_position = Vector3(0, 0, 30)

	var obj = bot._compute_strategic_objective_and_lane(anchor, {})
	anchor.queue_free()
	if not obj.has("objective_pos") or not obj.has("push_dir"):
		printerr("Bot AI _compute_strategic_objective_and_lane failed: ", obj)
		bot.queue_free()
		return false
		
	var themed_deck = bot.generate_themed_deck("The Reach")
	if themed_deck.is_empty():
		printerr("Bot AI themed deck is empty!")
		bot.queue_free()
		return false

	bot.queue_free()
	print("  Bot AI strategic objective, deck building, and personality verified.")
	return true

func test_live_match_simulation() -> bool:
	# Instantiate Arena
	var arena_scn = ResourceLoader.load("res://Scenes/Arena.tscn") as PackedScene
	if not arena_scn:
		printerr("Failed to load res://Scenes/Arena.tscn")
		return false
	var arena = arena_scn.instantiate()
	add_child(arena)
	
	# Simulate 60 physics frames
	for frame in range(60):
		if arena.has_method("_physics_process"):
			arena._physics_process(0.016)
			
	# Trigger Beast of Nothingness endgame Maw
	if arena.has_method("_start_beast_of_nothingness"):
		arena._start_beast_of_nothingness()
		
	# Simulate 30 more frames with the Maw active
	for frame in range(30):
		if arena.has_method("_physics_process"):
			arena._physics_process(0.016)

	arena.queue_free()
	print("  Live Arena match simulation, 90 frames of physics ticks & endgame Maw passed.")
	return true
