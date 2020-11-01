extends Spatial
class_name RegionObjectBlob, "res://addons/region_system_plugin/Region.svg"

################################################################################
## Constants

const OBJECT_COLLISION_INFORMATION = {
	"collision_layer" : 0,
	"collision_mask" : 0,
	"rigid_mode": RigidBody.MODE_RIGID,
}

################################################################################
## Private Variables

var _surrounding_influence := 0

################################################################################
## Public Variables

var active : bool = true setget set_active, get_active

export (NodePath) var object_node_path
var objects : Array = []

var objects_collision_information = {}

var detection_array := []

var detector_area := Area.new()
var detector_area_col_shape := CollisionShape.new()
var detector_shape : Shape setget set_detector_shape
export (float, 0.001, 1_000.0) var detector_shape_radius := 10.0 setget set_detector_area_shape_radius

var detection_area := Area.new()
var detection_area_col_shape := CollisionShape.new()
var detection_shape : Shape setget set_detection_shape
export (float, 0.001, 1_000.0) var detection_shape_radius := 0.5 setget set_detection_area_shape_radius

export (int, 0, 1_000_000) var influence_value := 1
export (bool) var is_persistent := false

var has_ros := false

################################################################################
## Virtual Functions

#func _init(_objects : Array = [], _influence := 1, persistent := false, use_custom_position : bool = false, custom_position : Vector3 = Vector3(0, 0, 0), _name := "RegionObject") -> void:
#	_constructor(_objects, _influence, persistent, _name)

func _init(_objects : Array = [], _influence := 1, persistent := false,
			_detector_area : Shape = SphereShape.new(),
			_detectable_area : Shape = SphereShape.new(),
			_name := "RegionObjectBlob", use_custom_position := false,
			custom_position := Vector3(0, 0, 0)) -> void:
	_constructor(_objects, _influence, persistent, _detector_area, _detectable_area, _name)
	
	if use_custom_position:
		set_global_transform(Transform(Basis(), custom_position))


func _physics_process(delta):
	_ro_process(delta)


func _process(delta):
	pass

################################################################################
## Signal Functions

func _on_detector_area_entered(area : Area):
	if not (area.get_parent() == self) and area.name == "DetectableArea":
		detection_array.append(area)


func _on_detector_area_exited(area : Area):
	if not (area.get_parent() == self) and area.name == "DetectableArea":
		detection_array.erase(area)

################################################################################
## Private Functions

func _constructor(_objects : Array = [], _influence := 1, persistent := false,
					_detector_area : Shape = SphereShape.new(),
					_detectable_area : Shape = SphereShape.new(),
					_name := "RegionObjectBlob") -> void:
	name = _name
	influence_value = _influence
	is_persistent = persistent
	
	add_to_group("RegionObjects", true)
	
	detector_shape = _detector_area
	detection_shape = _detectable_area
	
	if not _objects.empty():
		objects = _objects
		for object in _objects:
			objects_collision_information[object.get_instance_id()] = OBJECT_COLLISION_INFORMATION.duplicate()
			
			if object is PhysicsBody:
				objects_collision_information[object.get_instance_id()]["collision_layer"] = object.collision_layer
				objects_collision_information[object.get_instance_id()]["collision_mask"] = object.collision_mask
				
				if object is RigidBody:
					print_debug("RigidBody detected. While not inherently bad, RigidBodies may become troublesome if too far from the RegionObjectBlob it is part of. If this is intended, you can ignore this.")
			
		var centroid = _get_average_position(_objects)
		set_global_transform(Transform(Basis(), centroid))
		
		detector_area.name = "DetectorArea"
		detector_area_col_shape.shape = detector_shape
		detector_area_col_shape.name = "DetectorShape"
#		detector_shape.radius = detector_shape_radius
		detector_area.add_child(detector_area_col_shape)
		detector_area_col_shape.owner = detector_area
		detector_area.owner = self
		
		add_child(detector_area)
		
		detection_area.name = "DetectableArea"
		detection_area_col_shape.shape = detection_shape
		detection_area_col_shape.name = "DetectableShape"
#		detection_shape.radius = detection_shape_radius
		detection_area.add_child(detection_area_col_shape)
		detection_area_col_shape.owner = detection_area
		detection_area.owner = self
		
		add_child(detection_area)
		
		connect_signals()
	
	return


func _reconstruct(_object : Array = [], _influence = influence_value, persistent = is_persistent, _name = name) -> void:
	_constructor(_object, influence_value, is_persistent, _name)


func _ro_process(delta):
	if objects.empty():
		detector_area_col_shape.disabled = true
		active = false
	
	else:
#		global_transform = object.get_global_transform()
		set_global_transform(Transform(Basis(), _get_average_position(objects)))
	
	update_activity()


#func _enter_tree():
#	if not object and object_node_path:
#		object = get_node(object_node_path)
#		_constructor(object, influence_value, is_persistent, name)
#	pass


func _exit_tree():
	pass


func _create_packed_scene_for_object():
	var ps = PackedScene.new()


func _set_object_and_children_owner(object : Node, _owner : Node):
	object.set_owner(_owner)
	
	for child in object.get_children():
		_set_object_and_children_owner(child, object)


func _get_average_position(_objects : Array) -> Vector3:
	var avg_x = 0.0
	var avg_y = 0.0
	var avg_z = 0.0
	var tot_x = 0.0
	var tot_y = 0.0
	var tot_z = 0.0
	
	for i in _objects:
		tot_x += i.get_global_transform().origin.x
		tot_y += i.get_global_transform().origin.y
		tot_z += i.get_global_transform().origin.z
	
	avg_x = tot_x / _objects.size()
	avg_y = tot_y / _objects.size()
	avg_z = tot_z / _objects.size()
	
	return Vector3(avg_x, avg_y, avg_z)

################################################################################
## Public Functions

func set_detector_shape(new_shape : Shape):
	detector_shape = new_shape


func set_detection_shape(new_shape : Shape):
	detection_shape = new_shape


func set_objects(_objects : Array):
	_reconstruct(_objects)


func add_object(_object : Spatial):
	if _object is RigidBody:
		print_debug("RigidBody detected. While not inherently bad, RigidBodies may not work properly if too far from the RegionObjectBlob it is part of. If this is intended, you can ignore this.")
	
#	blobs[_name].add_object(child)
#
#	if _p:
#		blobs[_name].is_persistent = _p
#
#	if _iv > blobs[_name].influence_value:
#		blobs[_name].influence_value = _iv
	
	var _p : bool = _object.get_meta("persistent") if _object.has_meta("persistent") else false
	var _iv : int = _object.get_meta("influence_value") if _object.has_meta("influence_value") else 0
	
	if _p:
		self.is_persistent = _p
	
	if _iv > influence_value:
		self.influence_value = _iv
	
	objects.push_back(_object)
	
	objects_collision_information[_object.get_instance_id()] = OBJECT_COLLISION_INFORMATION.duplicate()
	
	if _object is PhysicsBody:
		objects_collision_information[_object.get_instance_id()]["collision_layer"] = _object.collision_layer
		objects_collision_information[_object.get_instance_id()]["collision_mask"] = _object.collision_mask
		
		if _object is RigidBody:
			print_debug("RigidBody detected. While not inherently bad, RigidBodies may not work properly if too far from the RegionObjectBlob it is part of. If this is intended, you can ignore this.")


func set_detector_area_shape_radius(value : float) -> void:
	detector_shape_radius = value


func set_detection_area_shape_radius(value : float) -> void:
	detection_shape_radius = value


func set_active(new_active : bool) -> void:
	if new_active:
		enable_object_activity()
	
	else:
		disable_object_activity()
	
	active = new_active


func get_active() -> bool:
	return active


func update_activity() -> void:
	
	if _surrounding_influence <= 0 and not is_persistent:
		# Deactivate the object tied to this RegionObject
#		disable_object_activity()
		self.active = false
#		active = false
	
	elif _surrounding_influence > 0:
		# Reactivate the object tied to this RegionObject
#		enable_object_activity()
		self.active = true
#		active = true
	
	if detector_shape.radius != detector_shape_radius:
		detector_shape.radius = detector_shape_radius
	
	if detection_shape.radius != detection_shape_radius:
		detection_shape.radius = detection_shape_radius
	
	return


func disable_object_activity() -> bool:
	if not (objects.size() > 0) or not active:
		return false
	
	for object in objects:
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
			objects_collision_information[object.get_instance_id()]["linear_velocity"] = object.linear_velocity
			objects_collision_information[object.get_instance_id()]["angular_velocity"] = object.angular_velocity
			object.linear_velocity = Vector3()
			object.angular_velocity = Vector3()
	
#	active = false
	
	return true


func enable_object_activity() -> bool:
	if not (objects.size() > 0) or active:
		return false
	
	for object in objects:
		object.set_process(true)
		object.set_physics_process(true)
		object.set_physics_process_internal(true)
		object.set_process_input(true)
		object.set_process_unhandled_input(true)
		object.set_process_unhandled_key_input(true)
		object.show()
		
		if object is PhysicsBody:
			object.collision_layer = objects_collision_information[object.get_instance_id()]["collision_layer"]
			object.collision_mask = objects_collision_information[object.get_instance_id()]["collision_mask"]
		
		if object is RigidBody:
	#		object.mode = object_collision_information["rigid_mode"]
			object.custom_integrator = false
			object.linear_velocity = objects_collision_information[object.get_instance_id()]["linear_velocity"]
			object.angular_velocity = objects_collision_information[object.get_instance_id()]["angular_velocity"]
	
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
		update_activity()


func clear_local_influence(_local_influence) -> void:
	if _local_influence < _surrounding_influence or influence_value > _local_influence:
		return
	
	else:
		_surrounding_influence = 0
		update_activity()
