extends NavigationRegion3D
class_name LevelBuilder
## Builds the map from primitives at startup, then bakes the navigation mesh The Hollow walks on.
## Route (south to north): Forest Entrance -> Cabins (west) -> Generator Station (east) ->
## Research Facility (north) -> Underground Tunnels (north-west, below ground) -> Emergency Gate.
## See docs/map_layout.md. To swap in real art, replace the meshes but keep the collision layout.

const ITEM_SCENE := preload("res://scenes/ItemPickup.tscn")
const DOC_SCENE := preload("res://scenes/Document.tscn")
const GATE_SCENE := preload("res://scenes/EmergencyGate.tscn")

const WALL_T := 0.3
const DOOR_WIDTH := 2.4
const DOOR_HEIGHT := 2.9
const TREE_SEED := 2171

## Pit for the underground tunnels (x0, x1, z0, z1) and its floor height.
const PIT := Rect2(Vector2(-50, -92), Vector2(28, 20))
const PIT_FLOOR := -4.0

var patrol_points: Array[Node3D] = []
var final_chase_spawn := Vector3(30, 0.3, -78)
var nav_ready := false

var _m := {}
var _keep_clear: Array[Rect2] = []


func _ready() -> void:
	_make_materials()
	_build_ground()
	_build_perimeter()
	_build_forest_entrance()
	_build_cabins()
	_build_generator_station()
	_build_research_facility()
	_build_tunnels()
	_build_gate()
	_build_patrol_points()
	_build_trees()
	bake_finished.connect(_on_bake_finished)
	bake_navigation_mesh(true)


func _on_bake_finished() -> void:
	nav_ready = true


# --- Materials --------------------------------------------------------------

func _make_materials() -> void:
	_m["ground"] = PrimitiveKit.mat(Color(0.08, 0.09, 0.06), 1.0)
	_m["road"] = PrimitiveKit.mat(Color(0.15, 0.13, 0.1), 1.0)
	_m["bark"] = PrimitiveKit.mat(Color(0.17, 0.12, 0.08), 1.0)
	_m["pine"] = PrimitiveKit.mat(Color(0.05, 0.11, 0.07), 1.0)
	_m["pine_dark"] = PrimitiveKit.mat(Color(0.04, 0.08, 0.05), 1.0)
	_m["rock"] = PrimitiveKit.mat(Color(0.22, 0.22, 0.21), 0.95)
	_m["concrete"] = PrimitiveKit.mat(Color(0.32, 0.32, 0.31), 0.95)
	_m["concrete_dark"] = PrimitiveKit.mat(Color(0.18, 0.18, 0.18), 0.95)
	_m["wood"] = PrimitiveKit.mat(Color(0.27, 0.19, 0.12), 0.95)
	_m["wood_dark"] = PrimitiveKit.mat(Color(0.16, 0.11, 0.07), 0.95)
	_m["metal"] = PrimitiveKit.mat(Color(0.3, 0.31, 0.33), 0.5, 0.6)
	_m["rust"] = PrimitiveKit.mat(Color(0.33, 0.19, 0.11), 0.85, 0.3)
	_m["fence"] = PrimitiveKit.mat(Color(0.2, 0.22, 0.22), 0.6, 0.5)
	_m["water"] = PrimitiveKit.mat(Color(0.04, 0.05, 0.06), 0.05, 0.3)
	_m["sign"] = PrimitiveKit.mat(Color(0.75, 0.72, 0.62), 0.9)
	_m["red_lamp"] = PrimitiveKit.mat(Color(1, 0.1, 0.05), 0.5, 0.0, Color(1, 0.1, 0.05), 4.0)
	_m["warm_lamp"] = PrimitiveKit.mat(Color(1, 0.8, 0.5), 0.5, 0.0, Color(1, 0.75, 0.45), 3.0)
	_m["fluoro"] = PrimitiveKit.mat(Color(0.8, 0.9, 1.0), 0.5, 0.0, Color(0.8, 0.9, 1.0), 3.0)
	_m["screen"] = PrimitiveKit.mat(Color(0.1, 0.4, 0.3), 0.3, 0.0, Color(0.1, 0.6, 0.4), 1.5)


# --- Building helpers -------------------------------------------------------

## Box with collision on the world layer, parented to the level so navigation bakes it.
func _solid(size: Vector3, pos: Vector3, material: Material, rot_deg := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	body.rotation_degrees = rot_deg
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	PrimitiveKit.box(body, size, material)
	add_child(body)
	return body


## Visual-only box (no collision).
func _deco(size: Vector3, pos: Vector3, material: Material, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	return PrimitiveKit.box(self, size, material, pos, rot_deg)


## Ground slab between x0..x1 and z0..z1 whose top surface sits at `top`.
func _slab(x0: float, x1: float, z0: float, z1: float, top: float, thickness: float, material: Material) -> void:
	_solid(Vector3(x1 - x0, thickness, z1 - z0), Vector3((x0 + x1) * 0.5, top - thickness * 0.5, (z0 + z1) * 0.5), material)


## Straight wall along X or Z. door_t is where a doorway sits (0..1), or -1 for none.
func _wall(start: Vector3, end: Vector3, height: float, material: Material, door_t := -1.0) -> void:
	var length := start.distance_to(end)
	var dir := (end - start).normalized()
	if door_t < 0.0:
		_wall_piece(start, end, start.y, height, material, WALL_T)
		return
	var center := length * door_t
	var a := maxf(0.0, center - DOOR_WIDTH * 0.5)
	var b := minf(length, center + DOOR_WIDTH * 0.5)
	if a > 0.05:
		_wall_piece(start, start + dir * a, start.y, height, material, WALL_T * 0.5)
	if b < length - 0.05:
		_wall_piece(start + dir * b, end, start.y, height, material, WALL_T * 0.5)
	_wall_piece(start + dir * a, start + dir * b, start.y + DOOR_HEIGHT, height - DOOR_HEIGHT, material, 0.0)


func _wall_piece(p0: Vector3, p1: Vector3, base_y: float, height: float, material: Material, overlap: float) -> void:
	if height <= 0.01:
		return
	var mid := (p0 + p1) * 0.5
	var length := Vector2(p1.x - p0.x, p1.z - p0.z).length()
	var along_x := absf(p1.x - p0.x) > absf(p1.z - p0.z)
	var size := Vector3(length + overlap, height, WALL_T) if along_x else Vector3(WALL_T, height, length + overlap)
	_solid(size, Vector3(mid.x, base_y + height * 0.5, mid.z), material)


## Four walls with optional doorways ({"south": 0.5} etc.), a visual floor and a roof.
func _room(center: Vector3, size_x: float, size_z: float, height: float, material: Material, doors: Dictionary, roof_material: Material = null) -> void:
	var hx := size_x * 0.5
	var hz := size_z * 0.5
	var y := center.y
	var sw := Vector3(center.x - hx, y, center.z + hz)
	var se := Vector3(center.x + hx, y, center.z + hz)
	var nw := Vector3(center.x - hx, y, center.z - hz)
	var ne := Vector3(center.x + hx, y, center.z - hz)
	_wall(sw, se, height, material, float(doors.get("south", -1.0)))
	_wall(nw, ne, height, material, float(doors.get("north", -1.0)))
	_wall(nw, sw, height, material, float(doors.get("west", -1.0)))
	_wall(ne, se, height, material, float(doors.get("east", -1.0)))
	_deco(Vector3(size_x, 0.02, size_z), center + Vector3(0, 0.01, 0), _m["concrete_dark"])
	if roof_material != null:
		_solid(Vector3(size_x + 0.6, 0.3, size_z + 0.6), center + Vector3(0, height + 0.15, 0), roof_material)
	_keep_clear.append(Rect2(Vector2(center.x - hx - 3.0, center.z - hz - 3.0), Vector2(size_x + 6.0, size_z + 6.0)))


func _lamp(pos: Vector3, color: Color, energy: float, light_range: float, flicker := false, bulb: Material = null) -> OmniLight3D:
	var light: OmniLight3D
	if flicker:
		light = FlickerLight.new()
	else:
		light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.position = pos
	add_child(light)
	if bulb != null:
		PrimitiveKit.sphere(self, 0.08, bulb, pos + Vector3(0, 0.12, 0))
	return light


func _sign(text: String, pos: Vector3, rot_y_deg: float, font_size := 48, board := true) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.006
	label.modulate = Color(0.12, 0.1, 0.08) if board else Color(0.9, 0.85, 0.75)
	label.outline_size = 0 if board else 8
	label.position = pos
	label.rotation_degrees = Vector3(0, rot_y_deg, 0)
	if board:
		var lines := text.split("\n").size()
		var width := 0.0
		for line in text.split("\n"):
			width = maxf(width, line.length() * font_size * 0.0034)
		var backing := _deco(Vector3(width + 0.3, lines * font_size * 0.0075 + 0.25, 0.06), pos, _m["sign"], Vector3(0, rot_y_deg, 0))
		label.position = pos + backing.basis.z * 0.04
	add_child(label)


func _item(item_id: String, pos: Vector3, amount := 1) -> void:
	var pickup := ITEM_SCENE.instantiate() as LastLightItemPickup
	pickup.item_id = item_id
	pickup.amount = amount
	pickup.position = pos
	add_child(pickup)


func _document(doc_id: String, pos: Vector3) -> void:
	var doc := DOC_SCENE.instantiate() as LastLightDocument
	doc.doc_id = doc_id
	doc.position = pos
	add_child(doc)


func _table(pos: Vector3, size := Vector3(1.4, 0.8, 0.8), material: Material = null) -> void:
	_solid(Vector3(size.x, 0.06, size.z), pos + Vector3(0, size.y - 0.03, 0), material if material != null else _m["wood"])
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_deco(Vector3(0.06, size.y, 0.06), pos + Vector3(sx * (size.x * 0.5 - 0.06), size.y * 0.5, sz * (size.z * 0.5 - 0.06)), _m["wood_dark"])


# --- Locations --------------------------------------------------------------

func _build_ground() -> void:
	var g: Material = _m["ground"]
	var x0 := PIT.position.x
	var x1 := PIT.end.x
	var z0 := PIT.position.y
	var z1 := PIT.end.y
	_slab(-70, 70, z1, 25, 0.0, 5.0, g)
	_slab(-70, 70, -125, z0, 0.0, 5.0, g)
	_slab(-70, x0, z0, z1, 0.0, 5.0, g)
	_slab(x1, 70, z0, z1, 0.0, 5.0, g)
	# Dirt road from the entrance to the gate (visual only).
	_deco(Vector3(4.0, 0.02, 132.0), Vector3(0, 0.01, -44.0), _m["road"])
	_keep_clear.append(Rect2(Vector2(-4, -125), Vector2(8, 150)))


func _build_perimeter() -> void:
	var f: Material = _m["fence"]
	_solid(Vector3(136.6, 4.0, 0.3), Vector3(0, 2.0, 23.0), f)
	_solid(Vector3(136.6, 4.0, 0.3), Vector3(0, 2.0, -122.0), f)
	_solid(Vector3(0.3, 4.0, 145.0), Vector3(-68.0, 2.0, -49.5), f)
	_solid(Vector3(0.3, 4.0, 145.0), Vector3(68.0, 2.0, -49.5), f)
	# Inner fence along the north with the 6 m gap for the emergency gate.
	_solid(Vector3(65.0, 4.0, 0.3), Vector3(-35.5, 2.0, -110.0), f)
	_solid(Vector3(65.0, 4.0, 0.3), Vector3(35.5, 2.0, -110.0), f)


func _build_forest_entrance() -> void:
	# Broken chain-link fence, a warning sign, a wrecked truck and a flickering lamp post.
	_solid(Vector3(6.0, 1.6, 0.15), Vector3(-9.0, 0.8, 8.0), _m["fence"], Vector3(0, 8, 5))
	_solid(Vector3(5.0, 1.6, 0.15), Vector3(9.5, 0.8, 7.5), _m["fence"], Vector3(0, -12, -9))
	_deco(Vector3(0.12, 2.4, 0.12), Vector3(3.2, 1.2, 10.0), _m["wood_dark"])
	_deco(Vector3(0.12, 2.4, 0.12), Vector3(5.6, 1.2, 10.0), _m["wood_dark"])
	_sign("NORTHWOOD RESEARCH STATION\nRESTRICTED AREA\nNO ENTRY AFTER DARK", Vector3(4.4, 2.0, 10.05), 0.0, 40)
	# Wrecked truck.
	_solid(Vector3(2.2, 1.1, 4.6), Vector3(-5.5, 0.75, 13.0), _m["rust"], Vector3(0, 20, 4))
	_solid(Vector3(2.0, 1.0, 1.6), Vector3(-6.2, 1.75, 11.6), _m["rust"], Vector3(0, 20, 4))
	_deco(Vector3(1.8, 0.5, 0.05), Vector3(-6.45, 1.85, 10.85), _m["water"], Vector3(-15, 20, 4))
	# Crate with the maintenance map on it.
	_solid(Vector3(0.9, 0.8, 0.9), Vector3(2.6, 0.4, 12.0), _m["wood"], Vector3(0, 15, 0))
	_document("maintenance_map", Vector3(2.6, 0.95, 12.0))
	# Lamp post.
	_deco(Vector3(0.15, 4.0, 0.15), Vector3(-3.0, 2.0, 6.0), _m["metal"])
	_lamp(Vector3(-3.0, 3.9, 6.0), Color(1.0, 0.75, 0.45), 2.5, 12.0, true, _m["warm_lamp"])
	_item("battery", Vector3(-4.2, 0.5, 9.5))
	_keep_clear.append(Rect2(Vector2(-14, 2), Vector2(28, 20)))


func _build_cabins() -> void:
	var cabins := [Vector3(-26, 0, -6), Vector3(-38, 0, -18), Vector3(-24, 0, -30)]
	for c in cabins:
		_room(c, 6.0, 5.0, 3.0, _m["wood"], {"east": 0.5}, _m["wood_dark"])
		# Porch step and a broken window frame.
		_deco(Vector3(0.6, 0.6, 1.0), c + Vector3(-1.2, 1.6, -2.45), _m["water"])
	_table(Vector3(-27.5, 0, -7.2))
	_item("battery", Vector3(-27.5, 0.95, -7.2))
	_table(Vector3(-39.5, 0, -19.2))
	_item("medkit", Vector3(-39.5, 0.95, -19.2))
	_item("bandage", Vector3(-37.0, 0.3, -16.8))
	_lamp(Vector3(-38, 2.6, -18), Color(1.0, 0.7, 0.4), 1.2, 6.0, true, _m["warm_lamp"])
	_table(Vector3(-25.0, 0, -31.2))
	_document("photograph", Vector3(-25.3, 0.9, -31.2))
	_item("flare", Vector3(-24.5, 0.9, -31.0))
	_sign("CABINS 1-3", Vector3(-18.6, 1.6, -6.0), 90.0, 40)
	_deco(Vector3(0.12, 1.6, 0.12), Vector3(-18.6, 0.8, -6.3), _m["wood_dark"])


func _build_generator_station() -> void:
	var c := Vector3(28, 0, -28)
	_room(c, 12.0, 10.0, 4.0, _m["concrete"], {"west": 0.5}, _m["concrete_dark"])
	# Generator, fuel tanks, a desk with the night-shift audio log.
	_solid(Vector3(3.0, 2.0, 1.6), c + Vector3(3.0, 1.0, -2.0), _m["metal"])
	_deco(Vector3(0.8, 0.5, 0.02), c + Vector3(2.0, 1.4, -1.19), _m["screen"])
	_solid(Vector3(1.2, 1.6, 1.2), c + Vector3(4.6, 0.8, 3.2), _m["rust"])
	_table(c + Vector3(-3.0, 0, -3.6), Vector3(1.6, 0.8, 0.8), _m["metal"])
	_document("audio_log_01", c + Vector3(-3.0, 0.9, -3.6))
	_item("power_fuse", c + Vector3(4.6, 0.5, 1.6))
	_lamp(c + Vector3(0, 3.7, 0), Color(0.8, 0.9, 1.0), 2.0, 10.0, true, _m["fluoro"])
	_sign("GENERATOR STATION", c + Vector3(-6.2, 3.0, 0.0), -90.0, 48)
	# Transformer box outside.
	_solid(Vector3(1.4, 1.8, 1.0), c + Vector3(-8.0, 0.9, 6.0), _m["metal"])
	_lamp(c + Vector3(-8.0, 2.2, 6.6), Color(1, 0.15, 0.1), 1.2, 5.0, true, _m["red_lamp"])


func _build_research_facility() -> void:
	var c := Vector3(0, 0, -62)
	var mat: Material = _m["concrete"]
	_room(c, 24.0, 18.0, 4.5, mat, {"south": 0.5}, _m["concrete_dark"])
	# Inner wall splitting the front hall from the back rooms, and the wall between the back rooms.
	_wall(Vector3(-12, 0, -64), Vector3(12, 0, -64), 4.5, mat, 0.25)
	_wall(Vector3(4, 0, -71), Vector3(4, 0, -64), 4.5, mat, 0.5)
	# Front hall: reception desk, overturned chairs, a battery.
	_solid(Vector3(3.0, 1.1, 0.8), Vector3(-5.0, 0.55, -57.0), _m["wood_dark"])
	_solid(Vector3(0.5, 0.5, 0.5), Vector3(3.0, 0.25, -58.5), _m["metal"], Vector3(0, 30, 90))
	_item("battery", Vector3(9.0, 0.4, -56.0))
	_item("bandage", Vector3(-9.5, 0.4, -61.5))
	_lamp(Vector3(0, 4.2, -58.5), Color(0.8, 0.9, 1.0), 1.6, 12.0, true, _m["fluoro"])
	# West lab: benches, terminals, the lab note.
	for i in 3:
		_solid(Vector3(3.0, 0.9, 0.9), Vector3(-8.0 + i * 4.0, 0.45, -68.5), _m["metal"])
		_deco(Vector3(0.6, 0.4, 0.05), Vector3(-8.0 + i * 4.0, 1.15, -68.8), _m["screen"])
	_document("lab_note", Vector3(-4.0, 1.0, -68.3))
	_lamp(Vector3(-4, 4.0, -67.5), Color(1, 0.12, 0.08), 1.8, 9.0, true, _m["red_lamp"])
	# East server room: racks and Fuse B.
	for i in 3:
		_solid(Vector3(0.8, 2.2, 1.0), Vector3(6.0 + i * 2.0, 1.1, -70.0), _m["concrete_dark"])
	_item("power_fuse", Vector3(10.5, 0.5, -66.0))
	_lamp(Vector3(8, 4.0, -67.5), Color(1, 0.12, 0.08), 1.8, 9.0, true, _m["red_lamp"])
	_sign("RESEARCH FACILITY - B WING", Vector3(0, 3.6, -52.8), 0.0, 48)


func _build_tunnels() -> void:
	var x0 := PIT.position.x
	var x1 := PIT.end.x
	var z0 := PIT.position.y
	var z1 := PIT.end.y
	var top := 0.0
	var ceiling_t := 0.6
	var floor_y := PIT_FLOOR
	var conc: Material = _m["concrete"]
	var dark: Material = _m["concrete_dark"]
	# Floor of the pit.
	_slab(x0, x1, z0, z1, floor_y, 1.0, dark)
	# Ramp down from the east edge (x1, ground level) to the tunnel floor, between z -84 and -80.
	var ramp_len := 12.0
	var drop := top - floor_y
	var angle := atan2(drop, ramp_len)
	var hyp := sqrt(ramp_len * ramp_len + drop * drop)
	_solid(Vector3(hyp, 0.4, 4.0), Vector3(x1 - ramp_len * 0.5, (top + floor_y) * 0.5 - 0.2 / cos(angle), -82.0), conc, Vector3(0, 0, rad_to_deg(angle)))
	# Ceiling over the pit, leaving the opening above the ramp.
	var open_x := x1 - ramp_len - 1.0
	_slab(x0, x1, z0, -84.0, top, ceiling_t, dark)
	_slab(x0, x1, -80.0, z1, top, ceiling_t, dark)
	_slab(x0, open_x, -84.0, -80.0, top, ceiling_t, dark)
	# Guard walls around the opening (ground level) and an entrance frame with a warning.
	_solid(Vector3(ramp_len + 1.0, 1.1, 0.25), Vector3(x1 - (ramp_len + 1.0) * 0.5, 0.55, -84.1), conc)
	_solid(Vector3(ramp_len + 1.0, 1.1, 0.25), Vector3(x1 - (ramp_len + 1.0) * 0.5, 0.55, -79.9), conc)
	_solid(Vector3(0.25, 1.1, 4.0), Vector3(open_x - 0.1, 0.55, -82.0), conc)
	_deco(Vector3(0.4, 3.2, 0.4), Vector3(x1 + 0.3, 1.6, -84.4), conc)
	_deco(Vector3(0.4, 3.2, 0.4), Vector3(x1 + 0.3, 1.6, -79.6), conc)
	_deco(Vector3(0.4, 0.4, 5.2), Vector3(x1 + 0.3, 3.2, -82.0), conc)
	_sign("MAINTENANCE TUNNELS\nDO NOT OPEN THE LOWER DOOR", Vector3(x1 + 0.55, 2.4, -82.0), 90.0, 36)
	_lamp(Vector3(x1 + 1.0, 3.0, -82.0), Color(1, 0.12, 0.08), 1.5, 7.0, true, _m["red_lamp"])

	# Inside: a corridor between the north and south rooms, joined at the west end.
	var inner_h := (top - ceiling_t) - floor_y
	_wall(Vector3(-46, floor_y, -84), Vector3(open_x, floor_y, -84), inner_h, conc)
	_wall(Vector3(-46, floor_y, -80), Vector3(open_x, floor_y, -80), inner_h, conc)
	# The sealed "lower door" at the west end of the corridor.
	_deco(Vector3(0.2, 3.0, 3.0), Vector3(x0 + 0.25, floor_y + 1.5, -82.0), _m["rust"])
	_sign("LOWER DOOR", Vector3(x0 + 0.4, floor_y + 3.1, -82.0), 90.0, 32)
	# Pipes, puddles, crates.
	for z in [-90.5, -87.5, -77.0, -74.0]:
		PrimitiveKit.cylinder(self, 0.12, 0.12, x1 - x0, _m["rust"], Vector3((x0 + x1) * 0.5, top - ceiling_t - 0.25, z), Vector3(0, 0, 90))
	for p in [Vector3(-40, 0, -88), Vector3(-30, 0, -76), Vector3(-44, 0, -82)]:
		_deco(Vector3(2.2, 0.01, 1.4), Vector3(p.x, floor_y + 0.01, p.z), _m["water"])
	_solid(Vector3(1.0, 1.0, 1.0), Vector3(-30, floor_y + 0.5, -75.5), _m["wood"])
	_document("radio_recording", Vector3(-30, floor_y + 1.1, -75.5))
	_item("power_fuse", Vector3(-48.0, floor_y + 0.5, -90.0))
	_item("battery", Vector3(-47.5, floor_y + 0.4, -74.0))
	_item("flare", Vector3(-26.0, floor_y + 0.3, -90.5))
	for l in [Vector3(-28, 0, -88), Vector3(-40, 0, -82), Vector3(-47, 0, -76), Vector3(-47, 0, -89)]:
		_lamp(Vector3(l.x, top - ceiling_t - 0.15, l.z), Color(0.9, 0.85, 0.6), 1.0, 8.0, true, _m["warm_lamp"])
	_keep_clear.append(Rect2(Vector2(x0 - 4.0, z0 - 4.0), Vector2(x1 - x0 + 8.0, z1 - z0 + 8.0)))


func _build_gate() -> void:
	var gate := GATE_SCENE.instantiate() as Node3D
	gate.position = Vector3(0, 0, -110)
	add_child(gate)
	_lamp(Vector3(-4.0, 4.5, -108.0), Color(0.8, 0.9, 1.0), 2.5, 14.0, true, _m["fluoro"])
	_keep_clear.append(Rect2(Vector2(-12, -122), Vector2(24, 20)))
	_keep_clear.append(Rect2(Vector2(final_chase_spawn.x - 3.0, final_chase_spawn.z - 3.0), Vector2(6, 6)))


func _build_patrol_points() -> void:
	var points := [
		Vector3(12, 0, -6), Vector3(36, 0, -16), Vector3(20, 0, -42), Vector3(0, 0, -48),
		Vector3(16, 0, -80), Vector3(-8, 0, -98), Vector3(-17, 0, -62), Vector3(-44, PIT_FLOOR, -76),
		Vector3(-32, 0, -24), Vector3(-14, 0, -12),
	]
	for i in points.size():
		var marker := Marker3D.new()
		marker.name = "Patrol%02d" % i
		marker.position = points[i]
		marker.add_to_group("patrol_point")
		add_child(marker)
		patrol_points.append(marker)
		var p: Vector3 = points[i]
		_keep_clear.append(Rect2(Vector2(p.x - 3.0, p.z - 3.0), Vector2(6, 6)))
	# Where The Hollow starts.
	_keep_clear.append(Rect2(Vector2(23, -51), Vector2(6, 6)))


func _build_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = TREE_SEED
	var transforms: Array[Transform3D] = []
	var attempts := 0
	while transforms.size() < 190 and attempts < 2000:
		attempts += 1
		var p := Vector2(rng.randf_range(-66, 66), rng.randf_range(-106, 21))
		var blocked := false
		for r in _keep_clear:
			if r.has_point(p):
				blocked = true
				break
		if not blocked:
			for t in transforms:
				if Vector2(t.origin.x, t.origin.z).distance_to(p) < 3.0:
					blocked = true
					break
		if blocked:
			continue
		var s := rng.randf_range(0.8, 1.35)
		var tree_basis := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3(s, s, s))
		transforms.append(Transform3D(tree_basis, Vector3(p.x, 0, p.y)))

	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.14
	trunk.bottom_radius = 0.26
	trunk.height = 7.0
	trunk.radial_segments = 8
	trunk.material = _m["bark"]
	var crown_low := CylinderMesh.new()
	crown_low.top_radius = 0.0
	crown_low.bottom_radius = 2.2
	crown_low.height = 4.0
	crown_low.radial_segments = 8
	crown_low.material = _m["pine"]
	var crown_high := CylinderMesh.new()
	crown_high.top_radius = 0.0
	crown_high.bottom_radius = 1.5
	crown_high.height = 3.0
	crown_high.radial_segments = 8
	crown_high.material = _m["pine_dark"]

	_multimesh(trunk, transforms, Vector3(0, 3.5, 0))
	_multimesh(crown_low, transforms, Vector3(0, 5.0, 0))
	_multimesh(crown_high, transforms, Vector3(0, 7.2, 0))

	var colliders := StaticBody3D.new()
	colliders.name = "TreeColliders"
	colliders.collision_layer = 1
	colliders.collision_mask = 0
	add_child(colliders)
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = 6.0
	for t in transforms:
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.position = t.origin + Vector3(0, 3.0, 0)
		colliders.add_child(cs)

	# A few rocks for variety (visual only).
	for i in 40:
		var p := Vector2(rng.randf_range(-66, 66), rng.randf_range(-106, 21))
		var blocked := false
		for r in _keep_clear:
			if r.has_point(p):
				blocked = true
				break
		if not blocked:
			var rs := rng.randf_range(0.3, 0.9)
			PrimitiveKit.sphere(self, rs, _m["rock"], Vector3(p.x, rs * 0.25, p.y), Vector3(1.2, 0.5, 1.0))


func _multimesh(mesh: Mesh, transforms: Array[Transform3D], offset: Vector3) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		var t := transforms[i]
		mm.set_instance_transform(i, Transform3D(t.basis, t.origin + t.basis * offset))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)
