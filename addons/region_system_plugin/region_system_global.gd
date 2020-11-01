extends Node

"""
	This is the Region System Global (RSG) singleton. Its main purpose is to
	provide functionality to allow for the tracking of `Region Objects` and to
	help reduce the load by `unloading` unnecessary Region Objects.
	
	Part of this singleton's job is to receive any and all signals from all
	Region Objects and the like, parsing the information and telling other
	Region Objects and the like what to do.
"""

################################################################################
## Signals

################################################################################
## Enumerations

enum RO_Types {X, ACTIVE, PASSIVE}

################################################################################
## Constants

const PERSISTENT := 1

################################################################################
## Private Variables

var _region_maps := []

var _detector_sphere_preset := SphereShape.new()
var _detection_sphere_preset := SphereShape.new()

################################################################################
## Public Variables

var influenced_objects := []

var region_objects_in_scene_tree := {}

################################################################################
## Virtual Functions

func _ready() -> void:
#	get_tree().connect("node_added", self, "_on_node_added")
#	get_tree().connect("node_removed", self, "_on_node_removed")
	_detector_sphere_preset.radius = 10.0
	_detection_sphere_preset.radius = 0.5
	pass

################################################################################
## Private Functions

################################################################################
## Public Functions

#_detector_area : Shape = _detector_sphere_preset,
#_detectable_area : Shape = _detection_sphere_preset,

func configure_metadata_on_object(object : Spatial, influence_value := 1,
								persistent := true,
								detection_shape := _detector_sphere_preset,
								detectable_shape := _detection_sphere_preset,
								type = RO_Types.X) -> void:
	match type:
		RO_Types.X:
			type = "x"
		
		RO_Types.ACTIVE:
			type = "active"
		
		RO_Types.PASSIVE:
			type = "passive"
	
	object.set_meta("type", type)
	object.set_meta("influence_value", influence_value)
	object.set_meta("persistent", persistent)
	object.set_meta("detection_area_shape", detection_shape)
	object.set_meta("detectable_area_shape", detectable_shape)


func add_region_map_to_roster(rm) -> bool:
	if not rm or _region_maps.has(rm):
		return false
	
	else:
		_region_maps.push_back(rm)
		return true

################################################################################
## Signal-related Functions


func _on_region_object_ping(invoker, object_array):
	pass


func _on_tracker_creation(identifier):
	pass
