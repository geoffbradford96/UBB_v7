extends Node
class_name HumanoidRig

func _init():
	name = "HumanoidRig"

# Reference to the unit CharacterBody3D
var unit: CharacterBody3D = null
var rig_root: Node3D = null

# Anatomical Rig Nodes
var torso: Node3D = null
var head: Node3D = null
var left_arm_pivot: Node3D = null
var left_arm_mesh: Node3D = null
var right_arm_pivot: Node3D = null
var right_arm_mesh: Node3D = null
var left_leg_pivot: Node3D = null
var left_leg_mesh: Node3D = null
var right_leg_pivot: Node3D = null
var right_leg_mesh: Node3D = null
var weapon_node: Node3D = null

# Base resting positions
var base_torso_pos: Vector3 = Vector3(0, 0.95, 0)
var base_head_pos: Vector3 = Vector3(0, 1.55, 0)
var base_left_arm_pos: Vector3 = Vector3(-0.29, 1.26, 0)
var base_right_arm_pos: Vector3 = Vector3(0.29, 1.26, 0)
var base_left_leg_pos: Vector3 = Vector3(-0.16, 0.62, 0)
var base_right_leg_pos: Vector3 = Vector3(0.16, 0.62, 0)

# Animation timers & state
var walk_time: float = 0.0
var idle_time: float = 0.0
var limp_time: float = 0.0
var attack_anim_timer: float = 0.0
var attack_anim_duration: float = 0.32
var is_active: bool = false

func trigger_attack(duration: float = 0.32):
	attack_anim_duration = clampf(duration, 0.15, 0.65)
	attack_anim_timer = attack_anim_duration

func setup(p_unit: CharacterBody3D):
	unit = p_unit
	if not unit: return
	
	# Hide or remove any existing raw placeholder meshes in the unit visual root
	var visual_root = unit.get_node_or_null("VisualPivot")
	if not visual_root: visual_root = unit.get_node_or_null("MeshInstance3D")
	if not visual_root: visual_root = unit.get_node_or_null("Visuals")
	if not visual_root:
		visual_root = Node3D.new()
		visual_root.name = "VisualPivot"
		unit.add_child(visual_root)
		
	# Hide previous raw mesh if it exists
	if visual_root is MeshInstance3D:
		visual_root.mesh = null
	for child in visual_root.get_children():
		if child.name == "HumanoidRigRoot":
			child.queue_free()
		elif child.name == "ShieldVisualRoot" or child.name == "ArmorPlatesRoot":
			continue
		else:
			child.visible = false
			
	_build_humanoid_anatomy(visual_root)
	is_active = true

func _build_humanoid_anatomy(parent: Node3D):
	rig_root = Node3D.new()
	rig_root.name = "HumanoidRigRoot"
	rig_root.rotation.y = PI # Align with Godot's forward vector (-Z) so infantry face where they walk and shoot!
	parent.add_child(rig_root)
	
	# Determine Faction & Styling
	var u_name = unit.name
	var is_reach = "Reach" in u_name
	var is_scrap = "Scrap" in u_name
	var is_beast_speaker = "GreatBeastSpeaker" in u_name
	var is_rimworlder = "Rimworlder" in u_name or is_beast_speaker
	var is_medic = "Medic" in u_name or "Repair" in u_name
	var is_commander = "Commander" in u_name or "Hero" in u_name or is_beast_speaker
	var is_hunter = "Hunter" in u_name or "Assassin" in u_name
	
	# Materials
	var body_mat = StandardMaterial3D.new()
	var armor_mat = StandardMaterial3D.new()
	var visor_mat = StandardMaterial3D.new()
	var weapon_mat = StandardMaterial3D.new()
	
	if is_beast_speaker:
		# Primal Shaman Beast-Speaker: dark beast-hide pelts, bleached bone armor, glowing emerald totem energy
		body_mat.albedo_color = Color(0.32, 0.22, 0.14)
		body_mat.roughness = 0.85
		armor_mat.albedo_color = Color(0.86, 0.82, 0.70)
		armor_mat.roughness = 0.55
		visor_mat.albedo_color = Color(0.15, 1.0, 0.45)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.15, 1.0, 0.45)
		visor_mat.emission_energy_multiplier = 3.2
		weapon_mat.albedo_color = Color(0.55, 0.42, 0.25)
		weapon_mat.roughness = 0.7
	elif is_reach:
		# Sleek cybernetic white with glowing cyan energy
		body_mat.albedo_color = Color(0.92, 0.95, 0.98)
		body_mat.metallic = 0.8
		body_mat.roughness = 0.2
		armor_mat.albedo_color = Color(0.82, 0.88, 0.94)
		armor_mat.metallic = 0.9
		armor_mat.roughness = 0.15
		visor_mat.albedo_color = Color(0.0, 0.9, 1.0)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.0, 0.9, 1.0)
		visor_mat.emission_energy_multiplier = 3.5
		weapon_mat.albedo_color = Color(0.2, 0.25, 0.3)
		weapon_mat.metallic = 0.9
	elif is_scrap:
		# Weathered rust iron and junk metal
		body_mat.albedo_color = Color(0.46, 0.26, 0.16)
		body_mat.roughness = 0.85
		armor_mat.albedo_color = Color(0.32, 0.3, 0.28)
		armor_mat.metallic = 0.6
		armor_mat.roughness = 0.7
		visor_mat.albedo_color = Color(1.0, 0.35, 0.1)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(1.0, 0.35, 0.1)
		visor_mat.emission_energy_multiplier = 2.0
		weapon_mat.albedo_color = Color(0.28, 0.25, 0.22)
		weapon_mat.metallic = 0.7
	elif is_rimworlder:
		# Leather duster / survival khaki
		body_mat.albedo_color = Color(0.45, 0.32, 0.22)
		body_mat.roughness = 0.8
		armor_mat.albedo_color = Color(0.55, 0.48, 0.36)
		armor_mat.roughness = 0.75
		visor_mat.albedo_color = Color(0.2, 0.85, 0.35)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.2, 0.85, 0.35)
		visor_mat.emission_energy_multiplier = 1.6
		weapon_mat.albedo_color = Color(0.25, 0.22, 0.2)
		weapon_mat.metallic = 0.5
	elif is_medic:
		# Medical white with red cross
		body_mat.albedo_color = Color(0.9, 0.9, 0.92)
		body_mat.roughness = 0.5
		armor_mat.albedo_color = Color(0.85, 0.15, 0.15)
		visor_mat.albedo_color = Color(0.1, 0.8, 0.3)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.1, 0.8, 0.3)
		visor_mat.emission_energy_multiplier = 2.0
		weapon_mat.albedo_color = Color(0.3, 0.3, 0.3)
	elif is_hunter or "Assassin" in u_name:
		# Stealth midnight charcoal / purple visor
		body_mat.albedo_color = Color(0.12, 0.12, 0.14)
		body_mat.roughness = 0.6
		armor_mat.albedo_color = Color(0.18, 0.18, 0.22)
		visor_mat.albedo_color = Color(0.75, 0.15, 0.9)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.75, 0.15, 0.9)
		visor_mat.emission_energy_multiplier = 3.0
		weapon_mat.albedo_color = Color(0.1, 0.1, 0.12)
		weapon_mat.metallic = 0.9
	elif is_commander:
		# Majestic heavy slate plate with gold trim
		body_mat.albedo_color = Color(0.18, 0.22, 0.28)
		body_mat.metallic = 0.7
		armor_mat.albedo_color = Color(0.95, 0.78, 0.2)
		armor_mat.metallic = 0.9
		armor_mat.roughness = 0.2
		visor_mat.albedo_color = Color(1.0, 0.85, 0.3)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(1.0, 0.85, 0.3)
		visor_mat.emission_energy_multiplier = 2.5
		weapon_mat.albedo_color = Color(0.9, 0.8, 0.2)
		weapon_mat.metallic = 0.95
	else:
		# Standard Dominion military combat uniform (olive drab / slate)
		body_mat.albedo_color = Color(0.24, 0.34, 0.2)
		body_mat.roughness = 0.7
		armor_mat.albedo_color = Color(0.18, 0.24, 0.16)
		armor_mat.metallic = 0.4
		visor_mat.albedo_color = Color(0.2, 0.7, 0.9)
		visor_mat.emission_enabled = true
		visor_mat.emission = Color(0.2, 0.7, 0.9)
		visor_mat.emission_energy_multiplier = 2.0
		weapon_mat.albedo_color = Color(0.18, 0.18, 0.18)
		weapon_mat.metallic = 0.8

	# --- 1. TORSO & CHEST ---
	torso = Node3D.new()
	torso.name = "Torso"
	torso.position = base_torso_pos
	rig_root.add_child(torso)
	
	var chest_mesh = MeshInstance3D.new()
	var box_t = BoxMesh.new()
	box_t.size = Vector3(0.48, 0.65, 0.28)
	chest_mesh.mesh = box_t
	chest_mesh.material_override = body_mat
	torso.add_child(chest_mesh)
	
	# Armor vest plate
	var armor_plate = MeshInstance3D.new()
	var box_ap = BoxMesh.new()
	box_ap.size = Vector3(0.52, 0.45, 0.32)
	armor_plate.mesh = box_ap
	armor_plate.material_override = armor_mat
	armor_plate.position = Vector3(0, 0.08, 0)
	torso.add_child(armor_plate)
	
	# Tactical belt
	var belt = MeshInstance3D.new()
	var box_b = BoxMesh.new()
	box_b.size = Vector3(0.5, 0.12, 0.3)
	belt.mesh = box_b
	belt.material_override = weapon_mat
	belt.position = Vector3(0, -0.28, 0)
	torso.add_child(belt)

	# Pelvis / Hip block bridging lower torso to upper leg sockets
	var pelvis = MeshInstance3D.new()
	var box_pelvis = BoxMesh.new()
	box_pelvis.size = Vector3(0.44, 0.18, 0.26)
	pelvis.mesh = box_pelvis
	pelvis.material_override = body_mat
	pelvis.position = Vector3(0, -0.36, 0)
	torso.add_child(pelvis)

	# Armored Neck / Gorget Cylinder bridging upper torso (y=1.275) to head base (y=1.36)
	var neck = MeshInstance3D.new()
	var cyl_neck = CylinderMesh.new()
	cyl_neck.top_radius = 0.095
	cyl_neck.bottom_radius = 0.115
	cyl_neck.height = 0.22
	neck.mesh = cyl_neck
	neck.material_override = armor_mat
	neck.position = Vector3(0, 0.38, 0)
	torso.add_child(neck)

	# Faction & Role Back / Torso Silhouette Accessories
	if is_beast_speaker:
		# Fur mantle + bone trophy spines across the back
		var fur_mantle = MeshInstance3D.new()
		var fm_box = BoxMesh.new()
		fm_box.size = Vector3(0.68, 0.24, 0.42)
		fur_mantle.mesh = fm_box
		fur_mantle.material_override = body_mat
		fur_mantle.position = Vector3(0, 0.28, -0.04)
		torso.add_child(fur_mantle)
	elif is_reach:
		# Cybernetic Halo Mounting Spine Bracket + Cyan Halo Ring behind shoulders
		var halo_mount = MeshInstance3D.new()
		var hm_box = BoxMesh.new()
		hm_box.size = Vector3(0.10, 0.20, 0.16)
		halo_mount.mesh = hm_box
		halo_mount.material_override = armor_mat
		halo_mount.position = Vector3(0, 0.22, -0.18)
		torso.add_child(halo_mount)

		var reach_halo = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 0.24
		torus.outer_radius = 0.30
		reach_halo.mesh = torus
		reach_halo.material_override = visor_mat
		reach_halo.rotation_degrees.x = 90.0
		reach_halo.position = Vector3(0, 0.22, -0.24)
		torso.add_child(reach_halo)
	elif is_scrap:
		# Twin Belching Scrap Exhaust Pipes on back with manifold block
		var manifold = MeshInstance3D.new()
		var mf_box = BoxMesh.new()
		mf_box.size = Vector3(0.38, 0.18, 0.14)
		manifold.mesh = mf_box
		manifold.material_override = armor_mat
		manifold.position = Vector3(0, 0.12, -0.18)
		torso.add_child(manifold)
		for side in [-1.0, 1.0]:
			var pipe = MeshInstance3D.new()
			var cyl_p = CylinderMesh.new()
			cyl_p.top_radius = 0.05
			cyl_p.bottom_radius = 0.06
			cyl_p.height = 0.48
			pipe.mesh = cyl_p
			pipe.material_override = weapon_mat
			pipe.position = Vector3(side * 0.15, 0.26, -0.20)
			pipe.rotation_degrees.z = side * 14.0
			torso.add_child(pipe)
	elif is_medic:
		# Medical Field Pack with glowing bio-stabilizer core
		var med_pack = MeshInstance3D.new()
		var mp_box = BoxMesh.new()
		mp_box.size = Vector3(0.36, 0.38, 0.18)
		med_pack.mesh = mp_box
		med_pack.material_override = armor_mat
		med_pack.position = Vector3(0, 0.08, -0.20)
		torso.add_child(med_pack)
		var med_glow = MeshInstance3D.new()
		var mg_box = BoxMesh.new()
		mg_box.size = Vector3(0.14, 0.14, 0.06)
		med_glow.mesh = mg_box
		med_glow.material_override = visor_mat
		med_glow.position = Vector3(0, 0.08, -0.30)
		torso.add_child(med_glow)
	elif is_commander:
		# Heroic Command Mantle Cape anchored to upper back armor
		var cape = MeshInstance3D.new()
		var cape_box = BoxMesh.new()
		cape_box.size = Vector3(0.54, 0.72, 0.05)
		cape.mesh = cape_box
		cape.material_override = armor_mat
		cape.position = Vector3(0, -0.06, -0.17)
		cape.rotation_degrees.x = 8.0
		torso.add_child(cape)

	# --- 2. HEAD & HELMET ---
	head = Node3D.new()
	head.name = "Head"
	head.position = base_head_pos
	rig_root.add_child(head)
	
	var head_mesh = MeshInstance3D.new()
	var sphere_h = SphereMesh.new()
	sphere_h.radius = 0.2
	sphere_h.height = 0.38
	head_mesh.mesh = sphere_h
	head_mesh.material_override = body_mat
	head.add_child(head_mesh)
	
	# Helmet / Cowl
	var helm_mesh = MeshInstance3D.new()
	var sphere_helm = SphereMesh.new()
	sphere_helm.radius = 0.23
	sphere_helm.height = 0.4
	helm_mesh.mesh = sphere_helm
	helm_mesh.material_override = armor_mat
	helm_mesh.position = Vector3(0, 0.04, -0.02)
	head.add_child(helm_mesh)
	
	# Eye Visor / Face Guard
	var visor_mesh = MeshInstance3D.new()
	var box_v = BoxMesh.new()
	box_v.size = Vector3(0.24, 0.08, 0.14)
	visor_mesh.mesh = box_v
	visor_mesh.material_override = visor_mat
	visor_mesh.position = Vector3(0, 0.02, 0.16)
	head.add_child(visor_mesh)

	if is_beast_speaker:
		# Curved Primal Beast Horns on the Skull Helm
		for side in [-1.0, 1.0]:
			var horn = MeshInstance3D.new()
			var cyl_h = CylinderMesh.new()
			cyl_h.top_radius = 0.02
			cyl_h.bottom_radius = 0.07
			cyl_h.height = 0.42
			horn.mesh = cyl_h
			horn.material_override = armor_mat
			horn.position = Vector3(side * 0.20, 0.18, 0.04)
			horn.rotation_degrees = Vector3(-25.0, 0.0, side * -38.0)
			head.add_child(horn)
	elif is_rimworlder:
		# Wide-brimmed Frontier Duster Hat
		var brim = MeshInstance3D.new()
		var cyl_brim = CylinderMesh.new()
		cyl_brim.top_radius = 0.36
		cyl_brim.bottom_radius = 0.38
		cyl_brim.height = 0.04
		brim.mesh = cyl_brim
		brim.material_override = body_mat
		brim.position = Vector3(0, 0.14, 0.0)
		head.add_child(brim)
	elif is_commander:
		# Regal Command Crest Fin
		var crest = MeshInstance3D.new()
		var box_cr = BoxMesh.new()
		box_cr.size = Vector3(0.06, 0.16, 0.32)
		crest.mesh = box_cr
		crest.material_override = visor_mat
		crest.position = Vector3(0, 0.24, 0.0)
		head.add_child(crest)

	# --- 3. LEFT ARM (SHOULDER PIVOT) ---
	left_arm_pivot = Node3D.new()
	left_arm_pivot.name = "LeftArmPivot"
	left_arm_pivot.position = base_left_arm_pos
	rig_root.add_child(left_arm_pivot)

	# Left Shoulder Socket Joint connecting into torso
	var left_shoulder_joint = MeshInstance3D.new()
	var sph_ls = SphereMesh.new()
	sph_ls.radius = 0.115
	sph_ls.height = 0.23
	left_shoulder_joint.mesh = sph_ls
	left_shoulder_joint.material_override = armor_mat
	left_shoulder_joint.position = Vector3(0.03, 0.0, 0.0)
	left_arm_pivot.add_child(left_shoulder_joint)
	
	left_arm_mesh = MeshInstance3D.new()
	var cyl_la = CapsuleMesh.new()
	cyl_la.radius = 0.09
	cyl_la.height = 0.55
	left_arm_mesh.mesh = cyl_la
	left_arm_mesh.material_override = body_mat
	left_arm_mesh.position = Vector3(0, -0.25, 0)
	left_arm_pivot.add_child(left_arm_mesh)

	# Left Gauntlet / Hand
	var left_hand = MeshInstance3D.new()
	var sph_lh = SphereMesh.new()
	sph_lh.radius = 0.085
	sph_lh.height = 0.17
	left_hand.mesh = sph_lh
	left_hand.material_override = weapon_mat
	left_hand.position = Vector3(0, -0.48, 0.03)
	left_arm_pivot.add_child(left_hand)
	
	# Shoulder pauldron
	var left_pad = MeshInstance3D.new()
	var box_lp = BoxMesh.new()
	box_lp.size = Vector3(0.26, 0.22, 0.28) if "ArmoredInfantry" in u_name else Vector3(0.18, 0.16, 0.2)
	left_pad.mesh = box_lp
	left_pad.material_override = armor_mat
	left_pad.position = Vector3(0, 0.04, 0)
	left_arm_pivot.add_child(left_pad)

	if "ShieldInfantry" in u_name or ("Commander" in u_name and is_reach):
		# Forearm clamp bracket + Left-arm mounted hardlight buckler emitter
		var buckler_brace = MeshInstance3D.new()
		var bb_box = BoxMesh.new()
		bb_box.size = Vector3(0.14, 0.14, 0.20)
		buckler_brace.mesh = bb_box
		buckler_brace.material_override = armor_mat
		buckler_brace.position = Vector3(-0.04, -0.34, 0.10)
		left_arm_pivot.add_child(buckler_brace)

		var buckler = MeshInstance3D.new()
		buckler.name = "LeftShieldBuckler"
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.28
		b_cyl.bottom_radius = 0.24
		b_cyl.height = 0.06
		buckler.mesh = b_cyl
		buckler.material_override = visor_mat
		buckler.position = Vector3(-0.06, -0.34, 0.18)
		buckler.rotation_degrees = Vector3(75.0, 20.0, 0.0)
		left_arm_pivot.add_child(buckler)

	# --- 4. RIGHT ARM (SHOULDER PIVOT & WEAPON) ---
	right_arm_pivot = Node3D.new()
	right_arm_pivot.name = "RightArmPivot"
	right_arm_pivot.position = base_right_arm_pos
	rig_root.add_child(right_arm_pivot)

	# Right Shoulder Socket Joint connecting into torso
	var right_shoulder_joint = MeshInstance3D.new()
	var sph_rs = SphereMesh.new()
	sph_rs.radius = 0.115
	sph_rs.height = 0.23
	right_shoulder_joint.mesh = sph_rs
	right_shoulder_joint.material_override = armor_mat
	right_shoulder_joint.position = Vector3(-0.03, 0.0, 0.0)
	right_arm_pivot.add_child(right_shoulder_joint)
	
	right_arm_mesh = MeshInstance3D.new()
	var cyl_ra = CapsuleMesh.new()
	cyl_ra.radius = 0.09
	cyl_ra.height = 0.55
	right_arm_mesh.mesh = cyl_ra
	right_arm_mesh.material_override = body_mat
	right_arm_mesh.position = Vector3(0, -0.25, 0)
	right_arm_pivot.add_child(right_arm_mesh)

	# Right Gauntlet / Hand gripping weapon
	var right_hand = MeshInstance3D.new()
	var sph_rh = SphereMesh.new()
	sph_rh.radius = 0.088
	sph_rh.height = 0.175
	right_hand.mesh = sph_rh
	right_hand.material_override = weapon_mat
	right_hand.position = Vector3(0, -0.46, 0.05)
	right_arm_pivot.add_child(right_hand)
	
	# Shoulder pauldron
	var right_pad = MeshInstance3D.new()
	var box_rp = BoxMesh.new()
	box_rp.size = Vector3(0.26, 0.22, 0.28) if "ArmoredInfantry" in u_name else Vector3(0.18, 0.16, 0.2)
	right_pad.mesh = box_rp
	right_pad.material_override = armor_mat
	right_pad.position = Vector3(0, 0.04, 0)
	right_arm_pivot.add_child(right_pad)
	
	# --- WEAPON IN HAND ---
	weapon_node = Node3D.new()
	weapon_node.name = "EquippedWeapon"
	weapon_node.position = Vector3(0, -0.46, 0.08)
	right_arm_pivot.add_child(weapon_node)
	
	_build_weapon(weapon_node, u_name, weapon_mat, visor_mat)

	# --- 5. LEFT LEG (HIP PIVOT & BOOT) ---
	left_leg_pivot = Node3D.new()
	left_leg_pivot.name = "LeftLegPivot"
	left_leg_pivot.position = base_left_leg_pos
	rig_root.add_child(left_leg_pivot)

	var left_hip = MeshInstance3D.new()
	var sph_lh_joint = SphereMesh.new()
	sph_lh_joint.radius = 0.105
	sph_lh_joint.height = 0.21
	left_hip.mesh = sph_lh_joint
	left_hip.material_override = armor_mat
	left_leg_pivot.add_child(left_hip)
	
	left_leg_mesh = MeshInstance3D.new()
	var cyl_ll = CapsuleMesh.new()
	cyl_ll.radius = 0.1
	cyl_ll.height = 0.6
	left_leg_mesh.mesh = cyl_ll
	left_leg_mesh.material_override = body_mat
	left_leg_mesh.position = Vector3(0, -0.28, 0)
	left_leg_pivot.add_child(left_leg_mesh)
	
	# Left Boot
	var left_boot = MeshInstance3D.new()
	var box_lb = BoxMesh.new()
	box_lb.size = Vector3(0.18, 0.16, 0.28)
	left_boot.mesh = box_lb
	left_boot.material_override = weapon_mat
	left_boot.position = Vector3(0, -0.52, 0.05)
	left_leg_pivot.add_child(left_boot)

	# --- 6. RIGHT LEG (HIP PIVOT & BOOT) ---
	right_leg_pivot = Node3D.new()
	right_leg_pivot.name = "RightLegPivot"
	right_leg_pivot.position = base_right_leg_pos
	rig_root.add_child(right_leg_pivot)

	var right_hip = MeshInstance3D.new()
	var sph_rh_joint = SphereMesh.new()
	sph_rh_joint.radius = 0.105
	sph_rh_joint.height = 0.21
	right_hip.mesh = sph_rh_joint
	right_hip.material_override = armor_mat
	right_leg_pivot.add_child(right_hip)
	
	right_leg_mesh = MeshInstance3D.new()
	var cyl_rl = CapsuleMesh.new()
	cyl_rl.radius = 0.1
	cyl_rl.height = 0.6
	right_leg_mesh.mesh = cyl_rl
	right_leg_mesh.material_override = body_mat
	right_leg_mesh.position = Vector3(0, -0.28, 0)
	right_leg_pivot.add_child(right_leg_mesh)
	
	# Right Boot
	var right_boot = MeshInstance3D.new()
	var box_rb = BoxMesh.new()
	box_rb.size = Vector3(0.18, 0.16, 0.28)
	right_boot.mesh = box_rb
	right_boot.material_override = weapon_mat
	right_boot.position = Vector3(0, -0.52, 0.05)
	right_leg_pivot.add_child(right_boot)

func _build_weapon(w_root: Node3D, u_name: String, w_mat: Material, energy_mat: Material):
	var w_mesh = MeshInstance3D.new()
	
	# Universal Pistol Grip / Hilt Socket connecting hand (0, 0, -0.02) into weapon body
	var grip_mount = MeshInstance3D.new()
	var grip_box = BoxMesh.new()
	grip_box.size = Vector3(0.06, 0.15, 0.08)
	grip_mount.mesh = grip_box
	grip_mount.material_override = w_mat
	grip_mount.position = Vector3(0, -0.02, 0.0)
	grip_mount.rotation_degrees.x = 15.0
	w_root.add_child(grip_mount)
	
	if "GreatBeastSpeaker" in u_name:
		# Tall Shamanic Bone-Totem Staff with bone cradle & glowing emerald beast crystal
		var staff = CylinderMesh.new()
		staff.top_radius = 0.048
		staff.bottom_radius = 0.036
		staff.height = 1.65
		w_mesh.mesh = staff
		w_mesh.material_override = w_mat
		w_mesh.rotation_degrees.x = 18.0
		w_mesh.position = Vector3(0, 0.25, 0.06)
		w_root.add_child(w_mesh)

		var cradle = MeshInstance3D.new()
		var c_tor = TorusMesh.new()
		c_tor.inner_radius = 0.08
		c_tor.outer_radius = 0.14
		cradle.mesh = c_tor
		cradle.material_override = w_mat
		cradle.position = Vector3(0, 0.94, 0.28)
		cradle.rotation_degrees.x = 18.0
		w_root.add_child(cradle)

		var totem_orb = MeshInstance3D.new()
		var sph = SphereMesh.new()
		sph.radius = 0.14
		sph.height = 0.28
		totem_orb.mesh = sph
		totem_orb.material_override = energy_mat
		totem_orb.position = Vector3(0, 1.02, 0.30)
		w_root.add_child(totem_orb)
	elif "Sniper" in u_name or "ReachRanged" in u_name or "ScrapRanged" in u_name:
		# Long-barreled sniper rifle with stock & scope Mount
		var rifle_body = BoxMesh.new()
		rifle_body.size = Vector3(0.08, 0.12, 1.15)
		w_mesh.mesh = rifle_body
		w_mesh.material_override = w_mat
		w_mesh.position = Vector3(0, 0.02, 0.28)
		w_root.add_child(w_mesh)
		
		var scope_mount = MeshInstance3D.new()
		var sm_box = BoxMesh.new()
		sm_box.size = Vector3(0.05, 0.06, 0.22)
		scope_mount.mesh = sm_box
		scope_mount.material_override = w_mat
		scope_mount.position = Vector3(0, 0.08, 0.14)
		w_root.add_child(scope_mount)

		var scope = MeshInstance3D.new()
		var cyl_s = CylinderMesh.new()
		cyl_s.top_radius = 0.035
		cyl_s.bottom_radius = 0.035
		cyl_s.height = 0.35
		scope.mesh = cyl_s
		scope.rotation.x = deg_to_rad(90.0)
		scope.position = Vector3(0, 0.12, 0.14)
		scope.material_override = energy_mat
		w_root.add_child(scope)
	elif "Rocket" in u_name:
		# Shoulder rocket tube + vertical hand-grip strut connecting down to right hand
		var r_strut = MeshInstance3D.new()
		var rs_box = BoxMesh.new()
		rs_box.size = Vector3(0.06, 0.30, 0.08)
		r_strut.mesh = rs_box
		r_strut.material_override = w_mat
		r_strut.position = Vector3(0.02, 0.12, 0.04)
		w_root.add_child(r_strut)

		var tube = CylinderMesh.new()
		tube.top_radius = 0.12
		tube.bottom_radius = 0.12
		tube.height = 1.2
		w_mesh.mesh = tube
		w_mesh.material_override = w_mat
		w_mesh.rotation.x = deg_to_rad(90.0)
		w_mesh.position = Vector3(0.04, 0.26, 0.1)
		w_root.add_child(w_mesh)
	elif "Medic" in u_name or "Repair" in u_name:
		# Medical Injector or Wrench
		var tool_box = BoxMesh.new()
		tool_box.size = Vector3(0.1, 0.18, 0.48)
		w_mesh.mesh = tool_box
		w_mesh.material_override = w_mat
		w_mesh.position = Vector3(0, 0.02, 0.12)
		w_root.add_child(w_mesh)
		
		var tip = MeshInstance3D.new()
		var tip_mesh = CylinderMesh.new()
		tip_mesh.top_radius = 0.02
		tip_mesh.bottom_radius = 0.05
		tip_mesh.height = 0.25
		tip.mesh = tip_mesh
		tip.rotation.x = deg_to_rad(90.0)
		tip.position = Vector3(0, 0.02, 0.42)
		tip.material_override = energy_mat
		w_root.add_child(tip)
	elif "Melee" in u_name or "Commander" in u_name or "Hero" in u_name or "ShieldInfantry" in u_name or "ArmoredInfantry" in u_name:
		# Sword / Combat Blade connected directly into crossguard hilt at hand
		var blade = BoxMesh.new()
		blade.size = Vector3(0.04, 0.14, 0.95)
		w_mesh.mesh = blade
		w_mesh.material_override = energy_mat
		w_mesh.position = Vector3(0, 0.02, 0.48)
		w_root.add_child(w_mesh)
		
		var hilt = MeshInstance3D.new()
		var hilt_mesh = BoxMesh.new()
		hilt_mesh.size = Vector3(0.10, 0.30, 0.08)
		hilt.mesh = hilt_mesh
		hilt.material_override = w_mat
		hilt.position = Vector3(0, 0.02, 0.04)
		w_root.add_child(hilt)
	elif "Hunter" in u_name or "Assassin" in u_name:
		# Combat dagger with hilt in hand
		var dagger = BoxMesh.new()
		dagger.size = Vector3(0.04, 0.08, 0.58)
		w_mesh.mesh = dagger
		w_mesh.material_override = energy_mat
		w_mesh.position = Vector3(0, 0.02, 0.26)
		w_root.add_child(w_mesh)
	else:
		# Combat Assault Rifle / Carbine with stock and connected barrel
		var gun = BoxMesh.new()
		gun.size = Vector3(0.08, 0.13, 0.68)
		w_mesh.mesh = gun
		w_mesh.material_override = w_mat
		w_mesh.position = Vector3(0, 0.02, 0.18)
		w_root.add_child(w_mesh)
		
		var barrel = MeshInstance3D.new()
		var bar_mesh = CylinderMesh.new()
		bar_mesh.top_radius = 0.025
		bar_mesh.bottom_radius = 0.028
		bar_mesh.height = 0.32
		barrel.mesh = bar_mesh
		barrel.rotation.x = deg_to_rad(90.0)
		barrel.position = Vector3(0, 0.03, 0.56)
		barrel.material_override = w_mat
		w_root.add_child(barrel)

func animate(delta: float, is_moving: bool, is_critically_wounded: bool, move_speed: float):
	if not is_active or not torso: return
	
	if is_critically_wounded:
		# --- CRITICALLY WOUNDED ANATOMY STATE ---
		# Hunched forward in agony
		torso.rotation.x = deg_to_rad(24.0)
		head.rotation.x = deg_to_rad(18.0)
		
		# Left arm tightly clutching torso wound across the abdomen
		left_arm_pivot.rotation.z = deg_to_rad(45.0)
		left_arm_pivot.rotation.x = deg_to_rad(22.0)
		left_arm_pivot.rotation.y = deg_to_rad(25.0)
		
		# Right arm lower, struggling with weapon
		right_arm_pivot.rotation.x = deg_to_rad(-12.0)
		right_arm_pivot.rotation.y = deg_to_rad(-8.0)
		
		if is_moving:
			# Limping hobble gait: asymmetric dragging stride
			limp_time += delta * clamp(move_speed * 1.4, 2.0, 4.2)
			
			# Left leg drags forward heavily
			left_leg_pivot.rotation.x = sin(limp_time) * 0.52
			# Right leg hitches short and stiff
			right_leg_pivot.rotation.x = -sin(limp_time) * 0.26 + 0.12
			
			# Severe lateral limp lurch
			torso.rotation.z = sin(limp_time) * 0.14
			torso.position.y = base_torso_pos.y - 0.06 + abs(sin(limp_time)) * 0.04
			head.position.y = base_head_pos.y - 0.08 + abs(sin(limp_time)) * 0.03
		else:
			# Standing wounded: heavy pained breathing shudder
			idle_time += delta * 3.2
			torso.rotation.z = lerp(torso.rotation.z, 0.0, 8.0 * delta)
			torso.position.y = base_torso_pos.y + sin(idle_time) * 0.025
			head.position.y = base_head_pos.y + sin(idle_time) * 0.015
			left_leg_pivot.rotation = Vector3.ZERO
			right_leg_pivot.rotation = Vector3.ZERO
	else:
		# --- HEALTHY / NORMAL STATE ---
		torso.rotation.x = lerp(torso.rotation.x, 0.0, 10.0 * delta)
		torso.rotation.y = lerp(torso.rotation.y, 0.0, 10.0 * delta)
		torso.position.z = lerp(torso.position.z, base_torso_pos.z, 10.0 * delta)
		head.rotation.x = lerp(head.rotation.x, 0.0, 10.0 * delta)
		var u_name_stance: String = unit.name if unit else ""
		var has_buckler: bool = "ShieldInfantry" in u_name_stance or ("Commander" in u_name_stance and "Reach" in u_name_stance)
		
		if is_moving:
			# Authentic alternating two-legged stride
			walk_time += delta * clamp(move_speed * 2.2, 3.5, 9.0)
			
			# Leg stride (left vs right alternating)
			left_leg_pivot.rotation.x = sin(walk_time) * 0.65
			right_leg_pivot.rotation.x = -sin(walk_time) * 0.65
			left_leg_pivot.rotation.z = 0.0
			right_leg_pivot.rotation.z = 0.0
			
			# Arm swing opposite legs (or held forward if bracing shield buckler)
			if has_buckler:
				left_arm_pivot.rotation.x = deg_to_rad(-48.0) + sin(walk_time) * 0.14
				left_arm_pivot.rotation.y = deg_to_rad(24.0)
				left_arm_pivot.rotation.z = deg_to_rad(10.0)
			else:
				left_arm_pivot.rotation.x = -sin(walk_time) * 0.55
				left_arm_pivot.rotation.z = deg_to_rad(-6.0)
				left_arm_pivot.rotation.y = 0.0
			
			# Right arm swings while holding weapon ready forward
			right_arm_pivot.rotation.x = deg_to_rad(-22.0) + sin(walk_time) * 0.32
			right_arm_pivot.rotation.y = deg_to_rad(-10.0)
			right_arm_pivot.rotation.z = 0.0
			
			# Torso bounce / vertical bob & sway
			torso.position.y = base_torso_pos.y + abs(sin(walk_time)) * 0.07
			torso.rotation.z = sin(walk_time) * 0.04
			head.position.y = base_head_pos.y + abs(sin(walk_time)) * 0.03
		else:
			# Standing pose: natural resting breathing stance with weapon at ready
			idle_time += delta * 2.2
			walk_time = 0.0
			
			# Gentle breathing cycle
			torso.position.y = base_torso_pos.y + sin(idle_time) * 0.022
			torso.rotation.z = lerp(torso.rotation.z, 0.0, 8.0 * delta)
			head.position.y = base_head_pos.y + sin(idle_time) * 0.014
			
			# Arms in ready standing posture
			right_arm_pivot.rotation.x = lerp(right_arm_pivot.rotation.x, deg_to_rad(-24.0), 8.0 * delta)
			right_arm_pivot.rotation.y = lerp(right_arm_pivot.rotation.y, deg_to_rad(-12.0), 8.0 * delta)
			right_arm_pivot.rotation.z = lerp(right_arm_pivot.rotation.z, 0.0, 8.0 * delta)
			
			if has_buckler:
				left_arm_pivot.rotation.x = lerp(left_arm_pivot.rotation.x, deg_to_rad(-52.0), 8.0 * delta)
				left_arm_pivot.rotation.y = lerp(left_arm_pivot.rotation.y, deg_to_rad(26.0), 8.0 * delta)
				left_arm_pivot.rotation.z = lerp(left_arm_pivot.rotation.z, deg_to_rad(12.0), 8.0 * delta)
			else:
				left_arm_pivot.rotation.x = lerp(left_arm_pivot.rotation.x, deg_to_rad(4.0), 8.0 * delta)
				left_arm_pivot.rotation.z = lerp(left_arm_pivot.rotation.z, deg_to_rad(-8.0), 8.0 * delta)
				left_arm_pivot.rotation.y = lerp(left_arm_pivot.rotation.y, 0.0, 8.0 * delta)
			
			# Stable standing stance
			left_leg_pivot.rotation.x = lerp(left_leg_pivot.rotation.x, 0.0, 8.0 * delta)
			right_leg_pivot.rotation.x = lerp(right_leg_pivot.rotation.x, 0.0, 8.0 * delta)
			left_leg_pivot.rotation.z = deg_to_rad(2.5)
			right_leg_pivot.rotation.z = deg_to_rad(-2.5)

	# --- ACTIVE ATTACK / ACTION ANIMATION OVERLAY ---
	if attack_anim_timer > 0.0:
		attack_anim_timer = max(0.0, attack_anim_timer - delta)
		var p: float = 1.0 - (attack_anim_timer / max(0.01, attack_anim_duration))
		var swing: float = sin(p * PI)
		var u_name: String = unit.name if unit else ""
		if "Melee" in u_name or "Commander" in u_name or "Hero" in u_name or "Assassin" in u_name or "GreatBeastSpeaker" in u_name or "Grunt" in u_name or "Runner" in u_name or "ShieldInfantry" in u_name or "ArmoredInfantry" in u_name:
			# Dynamic melee weapon slash / staff slam
			var slash_angle: float = lerpf(-1.55, 0.65, p)
			right_arm_pivot.rotation.x = slash_angle * swing + right_arm_pivot.rotation.x * (1.0 - swing)
			right_arm_pivot.rotation.y = deg_to_rad(-28.0 * swing)
			torso.rotation.y = sin(p * PI) * 0.36
			torso.rotation.x = deg_to_rad(14.0 * swing)
			torso.position.z = base_torso_pos.z + 0.14 * swing
		elif "Medic" in u_name or "Repair" in u_name:
			# Extend medical injector / repair welder forward
			right_arm_pivot.rotation.x = deg_to_rad(-65.0 * swing)
			left_arm_pivot.rotation.x = deg_to_rad(-35.0 * swing)
			torso.rotation.x = deg_to_rad(10.0 * swing)
		else:
			# Crisp firearm / sniper / rocket recoil kick
			right_arm_pivot.rotation.x = deg_to_rad(-32.0 - 24.0 * swing)
			left_arm_pivot.rotation.x = deg_to_rad(-28.0 - 14.0 * swing)
			torso.rotation.x = deg_to_rad(-8.0 * swing)
			if weapon_node:
				weapon_node.position.z = 0.08 - 0.08 * swing
	elif weapon_node:
		weapon_node.position.z = lerpf(weapon_node.position.z, 0.08, 12.0 * delta)

