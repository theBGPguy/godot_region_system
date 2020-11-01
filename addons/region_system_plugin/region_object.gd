extends Spatial
class_name RegionObject, "res://addons/region_system_plugin/Region.svg"

################################################################################
## Enumerations

enum Area_Shape {INVALID = -1, BOX, CAPSULE, CONCAVE_POLYGON, CONVEX_POLYGON, CYLINDER, SPHERE}

#enum Detection_Area_Shape {INVALID = -1, BOX, CAPSULE, CONCAVE_POLYGON, CONVEX_POLYGON, CYLINDER, SPHERE}

################################################################################
## Constants

const DETECTABLE_NAME := "DetectableArea"
const DETECTABLE_SHAPE_NAME := "DetectableShape"
const DETECTOR_NAME := "DetectorArea"
const DETECTOR_SHAPE_NAME := "DetectorShape"

################################################################################
## Private Variables

var _surrounding_influence := 0

var _detector_sphere_preset := SphereShape.new()
var _detection_sphere_preset := SphereShape.new()

################################################################################
## Public Variables

var active : bool = true setget set_active, get_active

export (NodePath) var object_node_path
var object : Spatial = null

var object_instance_id : int setget , get_object_instance_id

var object_collision_information = {
	"collision_layer" : 0,
	"collision_mask" : 0,
	"rigid_mode": RigidBody.MODE_RIGID,
}

var detection_array := []

var detector_area := Area.new()
var detector_area_col_shape := CollisionShape.new()
var detector_shape
#export (float, 0.001, 1_000.0) var detector_shape_radius := 10.0 setget set_detector_area_shape_radius

var detection_area := Area.new()
var detection_area_col_shape := CollisionShape.new()
var detection_shape
#export (float, 0.001, 1_000.0) var detection_shape_radius := 0.5 setget set_detection_area_shape_radius

export (int, 0, 1_000_000) var influence_value := 1
export (bool) var is_persistent := false

var has_ros := false

################################################################################
## Virtual Functions

func _init(_object : Spatial = null, _influence := 1, persistent := false,
			_detector_area : Shape = _detector_sphere_preset,
			_detectable_area : Shape = _detection_sphere_preset,
			_name := "RegionObject") -> void:
	
	_detector_sphere_preset.radius = 10.0
	_detection_sphere_preset.radius = 0.5
	
	_constructor(_object, _influence, persistent, _detector_area, _detectable_area, _name)
	return


func _physics_process(delta):
	_ro_process(delta)


func _process(delta):
	pass


func _enter_tree():
	if not object and object_node_path:
		object = get_node(object_node_path)
#		_constructor(object, influence_value, is_persistent, name)
	pass


func _exit_tree():
	pass

################################################################################
## Private Functions # Meant to be overwritten.

func _constructor(_object : Spatial = null, _influence := 1, persistent := false,
					_detector_area : Shape = SphereShape.new(),
					_detectable_area : Shape = SphereShape.new(),
					_name := "RegionObject") -> void:
	name = _name
	influence_value = _influence
	is_persistent = persistent
	
	add_to_group("RegionObjects", true)
	
	object = _object
	
	if _object:
		object_instance_id = _object.get_instance_id()
		_set_object_and_children_owner(_object, self)
		
		detector_shape = _detector_area
		detection_shape = _detectable_area
		
		if _object is PhysicsBody:
			object_collision_information["collision_layer"] = _object.collision_layer
			object_collision_information["collision_mask"] = _object.collision_mask
			if _object is RigidBody:
				object_collision_information["rigid_mode"] = _object.mode
		
		detector_area.name = DETECTOR_NAME
		detector_area_col_shape.shape = detector_shape
		detector_area_col_shape.name = DETECTOR_SHAPE_NAME
#		detector_shape.radius = 10 #detector_shape_radius
		detector_area.add_child(detector_area_col_shape)
		detector_area_col_shape.owner = detector_area
		detector_area.owner = self
		
		add_child(detector_area)
		
		detection_area.name = DETECTABLE_NAME
		detection_area_col_shape.shape = detection_shape
		detection_area_col_shape.name = DETECTABLE_SHAPE_NAME
#		detection_shape.radius = 0.5 #detection_shape_radius
		detection_area.add_child(detection_area_col_shape)
		detection_area_col_shape.owner = detection_area
		detection_area.owner = self
		
		add_child(detection_area)
		
		connect_signals()
	
	return


func _reconstruct(_object : Spatial = null, _influence := 1, persistent := false,
					_detector_area : Shape = SphereShape.new(),
					_detectable_area : Shape = SphereShape.new(),
					_name := "RegionObject") -> void:
	_constructor(_object, _influence, persistent, _detector_area, _detectable_area, _name)


func _ro_process(delta):
	if object == null:
		detector_area_col_shape.disabled = true
		active = false
	
	else:
#		global_transform = object.get_global_transform()
		set_global_transform(object.get_global_transform())
	
	update_activity()


#func _create_packed_scene_for_object():
#	var ps = PackedScene.new()


func _set_object_and_children_owner(object : Node, _owner : Node):
	object.set_owner(_owner)
	
	for child in object.get_children():
		_set_object_and_children_owner(child, object)


func _get_area_shape(shape_id : int):
#	enum Area_Shape {INVALID = -1, BOX, CAPSULE, CONCAVE_POLYGON, CONVEX_POLYGON, CYLINDER, SPHERE}
	var ret_val
	
	match shape_id:
		Area_Shape.BOX:
#			ret_val = [BoxShape.new(), BOX_AREA_PARAMETERS.duplicate()]
			ret_val = BoxShape.new()
		
		Area_Shape.CAPSULE:
#			ret_val = [CapsuleShape.new(), CAPSULE_AREA_PARAMETERS.duplicate()]
			ret_val = CapsuleShape.new()
		
		Area_Shape.CONCAVE_POLYGON:
#			ret_val = [ConcavePolygonShape.new(), CONCAVE_POLYGON_AREA_PARAMETERS.duplicate()]
			ret_val = ConcavePolygonShape.new()
		
		Area_Shape.CONVEX_POLYGON:
#			ret_val = [ConvexPolygonShape.new(), CONVEX_POLYGON_AREA_PARAMETERS.duplicate()]
			ret_val = ConvexPolygonShape.new()
		
		Area_Shape.CYLINDER:
#			ret_val = [CylinderShape.new(), CYLINDER_AREA_PARAMETERS.duplicate()]
			ret_val = CylinderShape.new()
		
		Area_Shape.SPHERE:
#			ret_val = [SphereShape.new(), SPHERE_AREA_PARAMETERS.duplicate()]
			ret_val = SphereShape.new()
		
		_:
#			ret_val = [SphereShape.new(), SPHERE_AREA_PARAMETERS.duplicate()]
			ret_val = SphereShape.new()
	
	return ret_val

################################################################################
## Signal Functions

func _on_detector_area_entered(area : Area):
	if not (area.get_parent() == self) and area.name == DETECTABLE_NAME:
		detection_array.append(area)
		area.get_parent().set_local_influence(influence_value)


func _on_detector_area_exited(area : Area):
	if not (area.get_parent() == self) and area.name == DETECTABLE_NAME:
		detection_array.erase(area)
		area.get_parent().clear_local_influence(influence_value)

################################################################################
## Private Functions

################################################################################
## Public Functions

func set_object(_object : Spatial):
	_reconstruct(_object)


func get_object_instance_id() -> int:
	return object_instance_id


#func set_detector_area_shape_radius(value : float) -> void:
#	detector_shape_radius = value
#
#
#func set_detection_area_shape_radius(value : float) -> void:
#	detection_shape_radius = value


func set_active(new_active : bool) -> void:
	if new_active:
		enable_object_activity()
	
	else:
		disable_object_activity()
	
	active = new_active


func get_active() -> bool:
	return active


func update_activity() -> void:
	
#	if _surrounding_influence <= 0 and not is_persistent:
	if _surrounding_influence < influence_value and not is_persistent:
		# Deactivate the object tied to this RegionObject
		self.active = false
	
#	elif _surrounding_influence > 0:
	elif _surrounding_influence >= influence_value:
		# Reactivate the object tied to this RegionObject
#		enable_object_activity()
		self.active = true
#		active = true
	
#	if detector_shape.radius != detector_shape_radius:
#		detector_shape.radius = detector_shape_radius
#
#	if detection_shape.radius != detection_shape_radius:
#		detection_shape.radius = detection_shape_radius
	
	return


func disable_object_activity() -> bool:
	if not object or not active:
		return false
	
	object.set_process(false)
	object.set_physics_process(false)
	object.set_physics_process_internal(false)
	object.set_process_input(false)
	object.set_process_unhandled_input(false)
	object.set_process_unhandled_key_input(false)
	object.hide()
	
	if object is PhysicsBody:
		object.collision_layer = 0
		object.collision_mask = 0
	
	if object is RigidBody:
#		object.mode = RigidBody.MODE_STATIC
		object.custom_integrator = true
		object_collision_information["linear_velocity"] = object.linear_velocity
		object_collision_information["angular_velocity"] = object.angular_velocity
		object.linear_velocity = Vector3()
		object.angular_velocity = Vector3()
	
#	active = false
	
	return true


func enable_object_activity() -> bool:
	if not object or active:
		return false
	
	object.set_process(true)
	object.set_physics_process(true)
	object.set_physics_process_internal(true)
	object.set_process_input(true)
	object.set_process_unhandled_input(true)
	object.set_process_unhandled_key_input(true)
	object.show()
	
	if object is PhysicsBody:
		object.collision_layer = object_collision_information["collision_layer"]
		object.collision_mask = object_collision_information["collision_mask"]
	
	if object is RigidBody:
#		object.mode = object_collision_information["rigid_mode"]
		object.custom_integrator = false
		object.linear_velocity = object_collision_information["linear_velocity"]
		object.angular_velocity = object_collision_information["angular_velocity"]
	
#	active = true
	
	return true


func get_detected_objects() -> Array:
	return detection_array


func connect_signals() -> void:
	var da : Area = get_node("DetectorArea")
	
	da.connect("area_entered", self, "_on_detector_area_entered", [], CONNECT_PERSIST)
	da.connect("area_exited", self, "_on_detector_area_exited", [], CONNECT_PERSIST)


func set_local_influence(_local_influence) -> void:
	if _local_influence < _surrounding_influence or influence_value > _local_influence:
		return
	
	else:
		_surrounding_influence = _local_influence
#		update_activity()


func clear_local_influence(_local_influence) -> void:
	if _local_influence < _surrounding_influence or influence_value > _local_influence:
		return
	
	else:
		_surrounding_influence = 0
#		update_activity()


## Will create a RegionObjectStreamer and add it as a child to self *only* if
## there is not already a RegionObjectStreamer added as a child.
func create_streamer(load_area := 256.0) -> bool:
	if not has_ros:
		has_ros = true
		var ros = RegionObjectStreamer.new(load_area)
		ros.owner = self
		add_child(ros)

		return true

	else:
		return false
