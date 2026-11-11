extends Node3D

var body: Node3D
var head: Node3D
var scarf: MeshInstance3D
var _squash := 1.0

func _ready() -> void:
	body = Node3D.new()
	add_child(body)
	_part(CapsuleMesh.new(), Vector3(0, 0.95, 0), Color("3a3f7a"), Vector3(0.58, 0.9, 0.5), body)
	_part(CapsuleMesh.new(), Vector3(-0.14, 0.32, 0), Color("22244d"), Vector3(0.2, 0.62, 0.2), body)
	_part(CapsuleMesh.new(), Vector3(0.14, 0.32, 0), Color("22244d"), Vector3(0.2, 0.62, 0.2), body)
	head = Node3D.new()
	head.position = Vector3(0, 1.52, 0)
	body.add_child(head)
	_part(SphereMesh.new(), Vector3.ZERO, Color("ffe0c8"), Vector3(0.6, 0.58, 0.56), head)
	_part(SphereMesh.new(), Vector3(0, 0.06, -0.05), Color("ff7fb0"), Vector3(0.68, 0.6, 0.64), head)
	_part(SphereMesh.new(), Vector3(0, 0.34, 0.02), Color("ff7fb0"), Vector3(0.14, 0.22, 0.14), head)
	_part(SphereMesh.new(), Vector3(-0.13, -0.02, 0.26), Color("2a2140"), Vector3(0.1, 0.16, 0.05), head, false)
	_part(SphereMesh.new(), Vector3(0.13, -0.02, 0.26), Color("2a2140"), Vector3(0.1, 0.16, 0.05), head, false)
	scarf = _part(BoxMesh.new(), Vector3(0, 1.22, -0.34), Color("4dd4ff"), Vector3(0.38, 0.1, 0.55), body, false)

func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.roughness = 1.0
	return m

func _part(mesh: Mesh, pos: Vector3, color: Color, size: Vector3, parent: Node3D, outline: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	if mesh is SphereMesh:
		mesh.radius = 0.5
		mesh.height = 1.0
		mi.scale = size
	elif mesh is CapsuleMesh:
		mesh.radius = 0.5
		mesh.height = 2.0
		mi.scale = Vector3(size.x, size.y / 2.0, size.z)
	else:
		mi.scale = size
	mi.material_override = _material(color)
	parent.add_child(mi)
	if outline:
		var ol := MeshInstance3D.new()
		ol.mesh = mesh
		ol.scale = Vector3.ONE * 1.08
		var om := StandardMaterial3D.new()
		om.albedo_color = Color(0.05, 0.03, 0.1)
		om.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		om.cull_mode = BaseMaterial3D.CULL_FRONT
		ol.material_override = om
		mi.add_child(ol)
	return mi

func update_pose(vel: Vector3, grounded: bool, gliding: bool, dashing: bool, facing: Vector2, delta: float) -> void:
	if facing.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(facing.x, facing.y), clampf(delta * 14.0, 0.0, 1.0))
	var horizontal := Vector2(vel.x, vel.z).length()
	var lean := clampf(horizontal * 6.0, 0.0, 0.35)
	var target_squash := 1.0
	if not grounded:
		target_squash = 1.0 + clampf(vel.y * 3.0, -0.25, 0.25)
	if dashing:
		lean = 0.8
	if gliding:
		lean = 1.2
	_squash = lerpf(_squash, target_squash, clampf(delta * 18.0, 0.0, 1.0))
	body.scale = Vector3(1.0 / sqrt(_squash), _squash, 1.0 / sqrt(_squash))
	body.rotation.x = lerpf(body.rotation.x, lean, clampf(delta * 12.0, 0.0, 1.0))
	scarf.rotation.x = -lean * 0.8 - (0.0 if grounded else 0.3)
