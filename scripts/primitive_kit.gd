class_name PrimitiveKit
extends RefCounted
## Helpers that build placeholder meshes and materials from code.
## Used by the level builder and by the Alex / Hollow stand-in models until real
## GLB models are dropped into assets/models.

static var _materials := {}


static func mat(color: Color, roughness := 0.9, metallic := 0.0, emission := Color.BLACK, emission_energy := 1.0) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s|%s" % [color, roughness, metallic, emission, emission_energy]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_energy
	_materials[key] = m
	return m


static func add_mesh(parent: Node3D, mesh: Mesh, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return add_mesh(parent, m, material, pos, rot_deg)


static func capsule(parent: Node3D, radius: float, height: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = maxf(height, radius * 2.0)
	m.radial_segments = 10
	m.rings = 4
	return add_mesh(parent, m, material, pos, rot_deg)


static func cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, material: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = top_radius
	m.bottom_radius = bottom_radius
	m.height = height
	m.radial_segments = 10
	m.rings = 1
	return add_mesh(parent, m, material, pos, rot_deg)


static func sphere(parent: Node3D, radius: float, material: Material, pos := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 12
	m.rings = 6
	return add_mesh(parent, m, material, pos, Vector3.ZERO, scl)


static func pivot(parent: Node3D, node_name: String, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.name = node_name
	p.position = pos
	parent.add_child(p)
	return p
