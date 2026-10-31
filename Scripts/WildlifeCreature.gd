extends CharacterBody3D
class_name WildlifeCreature

const WildlifeModelBuilder = preload("res://Scripts/WildlifeModelBuilder.gd")

@export var species_id: String = "WildlifeMonkey"
@export var speed: float = 5.0
@export var attack_damage: float = 12.0
@export var attack_range: float = 1.8
@export var attack_speed: float = 1.2
@export var aggro_range: float = 12.0
@export var is_flying: bool = false
@export var flight_height: float = 5.5
@export var drops_rocks: bool = false
@export var is_pecking: bool = false
@export var poison_dps: float = 0.0
@export var poison_ticks: int = 0
@export var projectile_type: String = "NONE"
@export var is_commander: bool = false

var team: String = "Player"
var target: Node3D = null
var attack_timer: float = 0.0
var is_selected: bool = false
var manual_target_pos: Vector3 = Vector3.ZERO
var has_manual_order: bool = false
var manual_attack_target: Node3D = null
var patrol_point_a: Vector3 = Vector3.ZERO
var patrol_point_b: Vector3 = Vector3.ZERO
var is_patrolling: bool = false
var assigned_lane: String = "Center"
var is_following_lane: bool = true

var _anim_phase: float = 0.0
var _retarget_timer: float = 0.0
var _aura_timer: float = 0.0
var _queen_spawn_timer: float = 0.0
var _strike_flash: float = 0.0
var _archetype: String = "QUADRUPED"

var _model_root: Node3D = null
var _head_pivot: Node3D = null
var _jaw_pivot: Node3D = null
var _tail_pivot: Node3D = null
var _wing_l: Node3D = null
var _wing_r: Node3D = null
var _leg_fl: Node3D = null
var _leg_fr: Node3D = null
var _leg_bl: Node3D = null
var _leg_br: Node3D = null
var _held_rock: Node3D = null

@onready var health_comp: HealthComponent = $HealthComponent
@onready var visual_pivot: Node3D = $VisualPivot
@onready var selection_ring: MeshInstance3D = $SelectionRing

func is_humanoid() -> bool:
	return false

func _ready():
	add_to_group("Units")
	add_to_group("WildlifeUnits")
	_anim_phase = randf() * TAU
	_retarget_timer = randf() * 0.25

	var raw_key = species_id if (species_id != "" and species_id != "WildlifeMonkey") else name
	species_id = WildlifeModelBuilder.get_species_key(raw_key)
	var info: Dictionary = WildlifeModelBuilder.get_species_info(species_id)
	_archetype = info.get("archetype", "QUADRUPED")
	speed = float(info.get("spd", speed))
	attack_damage = float(info.get("dmg", attack_damage))
	attack_range = float(info.get("rng", attack_range))
	attack_speed = float(info.get("aspd", attack_speed))
	is_flying = bool(info.get("fly", is_flying))
	drops_rocks = bool(info.get("rock", drops_rocks))
	is_pecking = bool(info.get("peck", is_pecking))
	poison_dps = float(info.get("poison_dps", poison_dps))
	poison_ticks = int(info.get("poison_ticks", poison_ticks))
	projectile_type = String(info.get("proj", projectile_type))
	is_commander = bool(info.get("cmdr", is_commander))

	if is_commander:
		add_to_group("Commander")

	if health_comp:
		var base_hp = float(info.get("hp", 60.0))
		health_comp.max_health = base_hp
		health_comp.current_health = base_hp
		var nat_armor = float(info.get("armor", 0.0))
		health_comp.max_armor = nat_armor
		health_comp.current_armor = nat_armor
		health_comp.max_shield = 0.0
		health_comp.current_shield = 0.0

	_model_root = WildlifeModelBuilder.build_animal_model(self, species_id)
	if _model_root:
		_head_pivot = _model_root.get_node_or_null("HeadPivot")
		if _head_pivot:
			_jaw_pivot = _head_pivot.get_node_or_null("JawPivot")
		_tail_pivot = _model_root.get_node_or_null("TailPivot")
		_wing_l = _model_root.get_node_or_null("WingL")
		_wing_r = _model_root.get_node_or_null("WingR")
		_leg_fl = _model_root.get_node_or_null("LegFL")
		_leg_fr = _model_root.get_node_or_null("LegFR")
		_leg_bl = _model_root.get_node_or_null("LegBL")
		_leg_br = _model_root.get_node_or_null("LegBR")
		_held_rock = _model_root.get_node_or_null("HeldRock")

	set_selected(false)
	update_team_visuals()
	if is_flying:
		global_position.y = flight_height

func update_team_visuals():
	if not is_inside_tree() or not visual_pivot:
		return
	var ring = visual_pivot.get_node_or_null("WildlifeTeamMarker") as MeshInstance3D
	if not ring:
		ring = MeshInstance3D.new()
		ring.name = "WildlifeTeamMarker"
		var tm = TorusMesh.new()
		tm.inner_radius = 0.42
		tm.outer_radius = 0.52
		ring.mesh = tm
		ring.position = Vector3(0, 0.06, 0)
		visual_pivot.add_child(ring)
	var mat = StandardMaterial3D.new()
	var col = Color(0.18, 0.85, 0.42) if team == "Player" else Color(0.95, 0.25, 0.20)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.85
	ring.material_override = mat

func set_selected(val: bool):
	is_selected = val
	if selection_ring:
		selection_ring.visible = val

func give_move_order(pos: Vector3):
	manual_target_pos = pos
	has_manual_order = true
	is_patrolling = false
	manual_attack_target = null
	is_following_lane = false

func give_attack_order(enemy: Node3D):
	manual_attack_target = enemy
	has_manual_order = false
	is_patrolling = false
	is_following_lane = false

func give_patrol_order(p1: Vector3, p2: Vector3):
	patrol_point_a = p1
	patrol_point_b = p2
	manual_target_pos = p2
	is_patrolling = true
	has_manual_order = true
	manual_attack_target = null
	is_following_lane = false

func _physics_process(delta: float):
	if health_comp and health_comp.current_health <= 0.0:
		return
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		_animate_creature(delta, velocity.length() > 0.2)
		return

	if is_commander:
		_process_commander_abilities(delta)

	if is_flying:
		global_position.y = lerpf(global_position.y, flight_height, delta * 5.0)
		velocity.y = 0.0
	else:
		if not is_on_floor():
			velocity.y -= 18.0 * delta
		else:
			velocity.y = 0.0

	_retarget_timer -= delta
	if _retarget_timer <= 0.0:
		_retarget_timer = 0.25
		_find_target()

	var spd_mult = 1.0
	if has_meta("wildlife_pack_speed_until") and Time.get_ticks_msec() < int(get_meta("wildlife_pack_speed_until")):
		spd_mult = 1.22
	var cur_speed = speed * spd_mult

	if is_instance_valid(manual_attack_target):
		var m_hc = manual_attack_target.get_node_or_null("HealthComponent") as HealthComponent
		if m_hc and m_hc.current_health > 0.0:
			target = manual_attack_target
		else:
			manual_attack_target = null

	var moving = false
	if is_instance_valid(target):
		var d2 = Vector2(global_position.x - target.global_position.x, global_position.z - target.global_position.z).length()
		var eff_range = attack_range
		if "Base" in target.name or "CommandBay" in target.name:
			eff_range += 2.6
		elif "Tower" in target.name:
			eff_range += 1.6

		if d2 <= eff_range:
			velocity.x = 0.0
			velocity.z = 0.0
			_face_position(target.global_position, delta)
			_process_combat(delta)
		else:
			_move_towards(target.global_position, cur_speed, delta)
			moving = true
	elif has_manual_order:
		var d_man = Vector2(global_position.x - manual_target_pos.x, global_position.z - manual_target_pos.z).length()
		if d_man < 1.2:
			if is_patrolling:
				var tmp = patrol_point_a
				patrol_point_a = patrol_point_b
				patrol_point_b = tmp
				manual_target_pos = patrol_point_b
			else:
				has_manual_order = false
				is_following_lane = true
		else:
			_move_towards(manual_target_pos, cur_speed, delta)
			moving = true
	else:
		var forward_z = -1.0 if team == "Player" else 1.0
		var goal_z = -55.0 if team == "Player" else 55.0
		var lane_x = _get_lane_x()
		var next_pos = Vector3(lane_x, global_position.y, clampf(global_position.z + forward_z * 12.0, -56.0, 56.0))
		if absf(global_position.z - goal_z) < 10.0:
			next_pos.x = 0.0
			next_pos.z = goal_z
		_move_towards(next_pos, cur_speed, delta)
		moving = true

	move_and_slide()
	if is_flying:
		global_position.y = flight_height
	_animate_creature(delta, moving)

func _get_lane_x() -> float:
	if assigned_lane == "Left":
		return -20.0
	elif assigned_lane == "Right":
		return 20.0
	return 0.0

func _face_position(pos: Vector3, delta: float):
	if not visual_pivot:
		return
	var dir = Vector3(pos.x - global_position.x, 0.0, pos.z - global_position.z)
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
		var target_basis = Basis.looking_at(dir, Vector3.UP)
		visual_pivot.basis = visual_pivot.basis.slerp(target_basis, minf(1.0, delta * 12.0)).orthonormalized()

func _move_towards(dest: Vector3, cur_speed: float, delta: float):
	var raw_dir = Vector3(dest.x - global_position.x, 0.0, dest.z - global_position.z)
	if raw_dir.length_squared() < 0.001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dir = raw_dir.normalized()

	var sep = Vector3.ZERO
	for u in get_tree().get_nodes_in_group("Units"):
		if u == self or not is_instance_valid(u) or not (u is Node3D):
			continue
		var u_fly = bool(u.get("is_flying")) if "is_flying" in u else false
		if u_fly != is_flying:
			continue
		var diff = Vector3(global_position.x - u.global_position.x, 0.0, global_position.z - u.global_position.z)
		var dist = diff.length()
		if dist > 0.01 and dist < 1.35:
			sep += diff.normalized() * ((1.35 - dist) / 1.35)

	if not is_flying:
		var space = get_world_3d().direct_space_state
		var from = global_position + Vector3(0, 0.5, 0)
		var q = PhysicsRayQueryParameters3D.create(from, from + dir * 2.2)
		q.exclude = [self.get_rid()]
		var hit = space.intersect_ray(q)
		if hit and hit.has("collider"):
			var col = hit["collider"]
			if is_instance_valid(col) and not col.is_in_group("Units"):
				var n = Vector3(hit["normal"].x, 0.0, hit["normal"].z).normalized()
				var slide = (dir - n * dir.dot(n)).normalized()
				if slide.length_squared() > 0.05:
					dir = slide

	var final_dir = (dir + sep * 0.75).normalized()
	velocity.x = final_dir.x * cur_speed
	velocity.z = final_dir.z * cur_speed
	_face_position(global_position + final_dir, delta)

func _find_target():
	var best: Node3D = null
	var best_score: float = 999999.0
	var candidates: Array = []
	candidates.append_array(get_tree().get_nodes_in_group("Units"))
	candidates.append_array(get_tree().get_nodes_in_group("Structures"))

	var can_hit_air = is_flying or drops_rocks or projectile_type != "NONE" or attack_range >= 4.0

	for node in candidates:
		if not is_instance_valid(node) or node == self or not (node is Node3D):
			continue
		var n_team = node.get("team")
		if n_team == null or n_team == team:
			continue
		var n_hc = node.get_node_or_null("HealthComponent") as HealthComponent
		if not n_hc or n_hc.current_health <= 0.0:
			continue
		var target_fly = bool(node.get("is_flying")) if "is_flying" in node else false
		if target_fly and not can_hit_air:
			continue

		var d = Vector2(global_position.x - node.global_position.x, global_position.z - node.global_position.z).length()
		var is_struct = node.is_in_group("Structures")
		if not is_struct and d > aggro_range:
			continue

		var score = d
		if is_struct and d > aggro_range:
			score += 25.0
		if score < best_score:
			best_score = score
			best = node

	target = best

func _process_combat(delta: float):
	var aspd_mult = 1.0
	if has_meta("wildlife_pack_aspd_until") and Time.get_ticks_msec() < int(get_meta("wildlife_pack_aspd_until")):
		aspd_mult = 1.20
	attack_timer -= delta * aspd_mult
	if attack_timer <= 0.0:
		attack_timer = 1.0 / maxf(0.2, attack_speed)
		_perform_attack()

func _perform_attack():
	if not is_instance_valid(target):
		return
	var target_hc = target.get_node_or_null("HealthComponent") as HealthComponent
	if not target_hc or target_hc.current_health <= 0.0:
		return

	_strike_flash = 1.0

	var dmg = attack_damage
	if is_pecking and target_hc.current_armor > 0.0:
		dmg *= 1.25
	elif ("MantisShrimp" in species_id or "PistolShrimp" in species_id or "CoconutCrab" in species_id) and target_hc.current_armor > 0.0:
		dmg *= 1.45

	if drops_rocks:
		_spawn_projectile_fx(target.global_position, "ROCK")
	elif projectile_type != "NONE":
		_spawn_projectile_fx(target.global_position, projectile_type)

	target_hc.take_damage(dmg, global_position)

	if poison_dps > 0.0 and poison_ticks > 0:
		target_hc.apply_poison(poison_ticks, poison_dps)

	if "Mosquito" in species_id and health_comp and health_comp.current_health > 0.0:
		health_comp.current_health = minf(health_comp.max_health, health_comp.current_health + dmg * 0.35)

func _spawn_projectile_fx(target_pos: Vector3, p_type: String):
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	var proj = MeshInstance3D.new()
	var start_pos = global_position + Vector3(0, 0.5, 0)
	var col = Color(0.50, 0.48, 0.44)
	if p_type == "ROCK":
		var sm = SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.30
		proj.mesh = sm
		proj.scale = Vector3(1.2, 0.85, 1.05)
		start_pos = global_position + Vector3(0, -0.25 if is_flying else 0.65, 0)
	elif p_type == "VENOM" or p_type == "ACID":
		var sm = SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		proj.mesh = sm
		col = Color(0.35, 1.0, 0.20) if p_type == "VENOM" else Color(0.95, 0.85, 0.15)
	elif p_type == "QUILL":
		var cm = CylinderMesh.new()
		cm.top_radius = 0.01
		cm.bottom_radius = 0.035
		cm.height = 0.45
		proj.mesh = cm
		col = Color(0.95, 0.94, 0.88)
	elif p_type == "LIGHTNING" or p_type == "SONIC":
		var sm = SphereMesh.new()
		sm.radius = 0.18
		sm.height = 0.36
		proj.mesh = sm
		col = Color(0.25, 0.90, 1.0)
	elif p_type == "TONGUE":
		var bm = BoxMesh.new()
		bm.size = Vector3(0.08, 0.08, 0.55)
		proj.mesh = bm
		col = Color(0.95, 0.35, 0.50)
	else:
		var sm = SphereMesh.new()
		sm.radius = 0.14
		sm.height = 0.28
		proj.mesh = sm
		col = Color(0.92, 0.92, 0.96)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.2 if p_type != "ROCK" else 0.15
	proj.material_override = mat
	scene_root.add_child(proj)
	proj.global_position = start_pos

	var tw = proj.create_tween()
	tw.tween_property(proj, "global_position", target_pos + Vector3(0, 0.4, 0), 0.18)
	tw.tween_callback(proj.queue_free)

func _process_commander_abilities(delta: float):
	_aura_timer -= delta
	if _aura_timer <= 0.0:
		_aura_timer = 1.0
		var expire_ms = Time.get_ticks_msec() + 1500
		for u in get_tree().get_nodes_in_group("WildlifeUnits"):
			if not is_instance_valid(u) or not (u is Node3D):
				continue
			if u.get("team") != team:
				continue
			if global_position.distance_to(u.global_position) <= 14.0:
				u.set_meta("wildlife_pack_speed_until", expire_ms)
				u.set_meta("wildlife_pack_aspd_until", expire_ms)

	if "QueenHornet" in species_id:
		_queen_spawn_timer += delta
		if _queen_spawn_timer >= 9.0:
			_queen_spawn_timer = 0.0
			var arena = get_tree().current_scene
			if arena and ResourceLoader.exists("res://Scenes/Units/WildlifeHornetSwarm.tscn"):
				var hornet_scene = load("res://Scenes/Units/WildlifeHornetSwarm.tscn") as PackedScene
				if hornet_scene:
					var h = hornet_scene.instantiate()
					h.team = team
					h.assigned_lane = assigned_lane
					arena.add_child(h)
					h.global_position = global_position + Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.5, 1.5))
					if h.has_method("update_team_visuals"):
						h.update_team_visuals()

func _animate_creature(delta: float, moving: bool):
	if not is_instance_valid(_model_root):
		return
	var rate = (8.5 if moving else 2.4) * (1.35 if is_flying else 1.0)
	_anim_phase += delta * rate
	if _strike_flash > 0.0:
		_strike_flash = maxf(0.0, _strike_flash - delta * 4.5)

	var swing = sin(_anim_phase) * (26.0 if moving else 4.0)
	if is_instance_valid(_leg_fl):
		_leg_fl.rotation_degrees.x = swing
	if is_instance_valid(_leg_br):
		_leg_br.rotation_degrees.x = swing
	if is_instance_valid(_leg_fr):
		_leg_fr.rotation_degrees.x = -swing
	if is_instance_valid(_leg_bl):
		_leg_bl.rotation_degrees.x = -swing

	if is_instance_valid(_wing_l) and is_instance_valid(_wing_r):
		var flap = sin(_anim_phase * 2.2) * 38.0
		_wing_l.rotation_degrees.z = flap
		_wing_r.rotation_degrees.z = -flap

	if is_instance_valid(_tail_pivot):
		if _archetype == "SERPENT" or _archetype == "EEL":
			_tail_pivot.rotation_degrees.y = sin(_anim_phase * 1.4) * 18.0
		else:
			_tail_pivot.rotation_degrees.y = sin(_anim_phase) * 14.0

	if is_instance_valid(_head_pivot):
		var peck_angle = -_strike_flash * (36.0 if is_pecking else 18.0)
		_head_pivot.rotation_degrees.x = peck_angle + sin(_anim_phase * 0.5) * 4.0

	if is_instance_valid(_jaw_pivot):
		_jaw_pivot.rotation_degrees.x = _strike_flash * 28.0

	if _archetype == "BIPED_HOPPER" and moving:
		_model_root.position.y = absf(sin(_anim_phase)) * 0.28
	else:
		_model_root.position.y = 0.0
