extends RegionObject #"res://addons/region_system_plugin/region_object.gd"
class_name PassiveRegionObject, "res://addons/region_system_plugin/Region.svg"

################################################################################
## Virtual Functions

func _init(_object : Spatial = null, _influence := 1, persistent := false,
			_detector_area : Shape = SphereShape.new(),
			_detectable_area : Shape = SphereShape.new(),
			_name := "RegionObject") -> void:
	_constructor(_object, _influence, persistent, _detector_area, _detectable_area, _name)
	return


func _physics_process(delta):
	_ro_process(delta)


func _process(delta):
	pass


#func _enter_tree():
#	if not object and object_node_path:
#		object = get_node(object_node_path)
#		_constructor(object, influence_value, is_persistent, name)
#	pass


func _exit_tree():
	pass

################################################################################
## Private Functions # Meant to be overwritten.

#func _constructor(_object : Spatial = null, _influence := 1, persistent := false, _name := "RegionObject") -> void:
#	name = "RegionObject"
#	influence_value = _influence
#	is_persistent = persistent
#
#	add_to_group("RegionObjects", true)
#
#	object = _object
#
#	detector_area.name = "DetectorArea"
#	detector_area_col_shape.shape = detector_shape
#	detector_area_col_shape.name = "DetectorShape"
#	detector_shape.radius = detector_shape_radius
#	detector_area.add_child(detector_area_col_shape)
#
#	add_child(detector_area)
#
#	detection_area.name = "DetectionArea"
#	detection_area_col_shape.shape = detection_shape
#	detection_area_col_shape.name = "DetectionShape"
#	detection_shape.radius = detection_shape_radius
#	detection_area.add_child(detection_area_col_shape)
#
#	add_child(detection_area)
#
#	connect_signals()
#
#	return
#
#
#func _ro_process(delta):
#	if object == null:
#		detector_area_col_shape.disabled = true
#		active = false
#
#	else:
#		global_transform = object.global_transform
#
#	update_activity()

################################################################################
## Public Functions

#func update_activity() -> void:
#
#	if _surrounding_influence <= 0 and not is_persistent:
#		# Deactivate the object tied to this RegionObject
##		disable_object_activity()
#		self.active = false
##		active = false
#
#	elif _surrounding_influence > 0:
#		# Reactivate the object tied to this RegionObject
##		enable_object_activity()
#		self.active = true
##		active = true
#
#	return

################################################################################
## Signal Functions

func _on_detector_area_entered(area : Area):
	if not (area.get_parent() == self) and not area.name == DETECTABLE_NAME:
		detection_array.append(area)
#		area.get_parent().set_local_influence(influence_value)


func _on_detector_area_exited(area : Area):
	if not (area.get_parent() == self) and not area.name == DETECTABLE_NAME:
		detection_array.erase(area)
#		area.get_parent().clear_local_influence(influence_value)
