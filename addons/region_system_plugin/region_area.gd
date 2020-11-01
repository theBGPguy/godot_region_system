extends Spatial
class_name RegionArea, "res://addons/region_system_plugin/Region.svg"


"""
	The `RegionArea` is a custom node that can be used as a parent for anything
	you need to be a part of the Region System, i.e. have a RegionObject created
	for it.
	
	Any child of `RegionArea` can have three entries in its metadata to override
	the default values:
	
	- influence_value
	> Integer of value 0 or greater.
	> Omitted assumed to be 1.
	>
	> Value minimum is 0. Each value higher overrides all lower values.
	
	- persistent
	> Boolean.
	> Omitted assumed to be false.
	>
	> false == will not unload unless told.
	> true  == will unload.
	
	- type
	> String with values of 'active', 'persistent', or 'x'.
	> Omitted assumed to be 'x'.
	>
	> 'active' == ActiveRegionObject
	> 'passive' == PassiveRegionObject
	> 'x' == RegionObject
	
	----------------------------------------------------------------------------
	The `RegionArea` will also create a `RegionObjectBlob` for to keep track of
	all children of `RegionArea` that belong to the same group.
	To have a group be turned into a RegionObjectBlob, the group's name *must*
	start with 'blob-'. It can have any name (the name will be used as the name
	of the RegionObjectBlob that will be made).
"""


################################################################################
## Signals

################################################################################
## Constants

const DEFAULT_DETECTION_SPHERE_RADIUS := 100.0
const DEFAULT_DETECTABLE_SPHERE_RADIUS := 0.5

################################################################################
## Private Variables

################################################################################
## Public Variables

export (bool) var disabled := false

#export (float, 0.001, 1_000_000_000.0) var detection_zone_

################################################################################
## Virtual Functions

func _init():
	pass

# We need to define `_ready` and add all the children to a sibling RegionMap
# so we can have all the children ready and in the tree before trying to
# reference them.
func _ready():
	if disabled:
		return
	
	if get_child_count() > 0:
		_create_region_map()

################################################################################
## Private Functions

func _check_for_configuration_nodes(node) -> Dictionary:
	var default_detection_sphere = SphereShape.new()
	var default_detectable_sphere = SphereShape.new()
	default_detection_sphere.radius = DEFAULT_DETECTION_SPHERE_RADIUS
	default_detectable_sphere.radius = DEFAULT_DETECTABLE_SPHERE_RADIUS
	
	var ret_dic := {
		"type": "passive",
		"persistent": false,
		"influence_value": 1,
		"streamer": false,
		"streamer_radius": 256.0,
		"detection_area_shape": default_detection_sphere,
		"detectable_area_shape": default_detectable_sphere,
	}
	
	if node.get_child_count() > 0:
		
		for child in node.get_children():
			
			## If there is a child node named "ro_config":
			if child.name == "ro_config":
				# Check the children of that node
				if child.get_child_count() > 0:
					
					for config in child.get_children():
						
						var nm = config.name.split("=")
						
#						if nm.size() < 2:
#							continue
						
						if not ["type", "persistent", "influence_value",
								"streamer", "streamer_radius", "detection_area",
								"detectable_area", "detection_area_shape",
								"detectable_area_shape"].has(nm[0]):
							continue
						
						match nm[0]:
							"type":
								ret_dic[nm[0]] = nm[1]
							
							"persistent":
								ret_dic[nm[0]] = true
							
							"influence_value":
								ret_dic[nm[0]] = nm[1].to_int()
							
							"streamer":
								ret_dic[nm[0]] = true
							
							"streamer_radius":
								ret_dic[nm[0]] = nm[1].to_float()
							
							"detection_area", "detectable_area":
#								ret_dic[nm[0] + "_shape"] = child.get_child(0)#.shape.duplicate()#nm[1]#.duplicate()
								ret_dic[nm[0] + "_shape"] = config.shape.duplicate()
							
							"detection_area_shape", "detectable_area_shape":
								ret_dic[nm[0]] = config.shape.duplicate()
						
						config.queue_free()
				child.queue_free()
			
			## This is always tried, so if the object has metadata set, it will
			## be used, **overwriting** what was done by the configure nodes.
			## If the metadata does not exist for a particular config option,
			## what had already been set, or the default if unset, will still be
			## used.
			ret_dic["type"] = node.get_meta("type") if node.has_meta("type") else ret_dic["type"]
			ret_dic["persistent"] = node.get_meta("persistent") if node.has_meta("persistent") else ret_dic["persistent"]
			ret_dic["influence_value"] = node.get_meta("influence_value") if node.has_meta("influence_value") else ret_dic["influence_value"]
			
			ret_dic["streamer"] = node.get_meta("streamer") if node.has_meta("streamer") else ret_dic["streamer"]
			ret_dic["streamer_radius"] = node.get_meta("streamer_radius") if node.has_meta("streamer_radius") else ret_dic["streamer_radius"]
			
			ret_dic["detection_area_shape"] = node.get_meta("detection_area_shape") if node.has_meta("detection_area_shape") else ret_dic["detection_area_shape"]
			ret_dic["detectable_area_shape"] = node.get_meta("detectable_area_shape") if node.has_meta("detectable_area_shape") else ret_dic["detectable_area_shape"]
	
	return ret_dic


func _create_region_map():
	var rom = RegionMap.new()
	
	var blobs = {}
	
	var default_detect_shape := SphereShape.new()
	var default_detectable_shape := SphereShape.new()
	
	default_detect_shape.radius = DEFAULT_DETECTION_SPHERE_RADIUS
	default_detectable_shape.radius = DEFAULT_DETECTABLE_SPHERE_RADIUS
	
	for child in get_children():
		
		if child is Node:
			
			var config = {}
			
#			if child.get_child_count() > 0:
			config = _check_for_configuration_nodes(child)
			
			var skip = false
			
			for group in child.get_groups():
				if group is String:
					if group.begins_with("blob-"):
						var _name = group.lstrip("blob-")
						if not blobs.keys().has(_name):
							var detect_area_shape : Shape = config["detection_area_shape"]
							var detectable_area_shape : Shape = config["detectable_area_shape"]
							
							blobs[_name] = RegionObjectBlob.new([child], 1, false, detect_area_shape, detectable_area_shape, "RegionObjectBlob_" + _name, false, Vector3())
							var _p : bool = config["persistent"]#child.get_meta("persistent") if child.has_meta("persistent") else false
							var _iv : int = config["influence_value"]#child.get_meta("influence_value") if child.has_meta("influence_value") else 1
							
							blobs[_name].is_persistent = _p
							blobs[_name].influence_value = _iv
						
						else:
							blobs[_name].add_object(child)
							var _p : bool = config["persistent"]
							var _iv : int = config["influence_value"]
							
							if _p:
								blobs[_name].is_persistent = _p
							
							if _iv > blobs[_name].influence_value:
								blobs[_name].influence_value = _iv
							
							if not (config["detection_area_shape"] is SphereShape and config["detection_area_shape"].radius == DEFAULT_DETECTION_SPHERE_RADIUS):
								blobs[_name].get_node("DetectorArea/DetectorShape").shape = config["detection_area_shape"]
							
							if not (config["detectable_area_shape"] is SphereShape and config["detectable_area_shape"].radius == DEFAULT_DETECTABLE_SPHERE_RADIUS):
								blobs[_name].get_node("DetectableArea/DetectableShape").shape = config["detectable_area_shape"]
							
							blobs[_name].connect_signals()
						
						skip = true
						break
			
			## This variable `skip` is used to make sure we don't create two
			## RegionObjects for the same thing. If it is in a group, we will
			## add it to that RegionObjectBlob; we don't want doubled-up
			## RegionObjects.
			if skip:
				continue
			
			var data = create_region_object(child)
			rom.add_region_object(data)
	
	for i in blobs:
		rom.add_region_object(blobs[i])
	
	call_deferred("_ready_region_map", rom)


func _ready_region_map(rom):
	get_parent().add_child(rom)

################################################################################
## Public Functions

func add_child(node : Node, legible_unique_name : bool = false):
	print("adding node to region area")
	node.owner = self
	.add_child(node, legible_unique_name)


func create_region_object(object : Spatial) -> RegionObject:
	if not object:
		return null
	
#	print(object)
#	print(object.name)
	
#	var default_detect_shape := SphereShape.new()
#	var default_detectable_shape := SphereShape.new()
#
#	default_detect_shape.radius = 50.0
#	default_detectable_shape.radius = 0.5
#	
#	var type : String = object.get_meta("type") if object.has_meta("type") else "passive"
#	var persistent : bool = object.get_meta("persistent") if object.has_meta("persistent") else false
#	var influence_value : int = object.get_meta("influence_value") if object.has_meta("influence_value") else 1
#
#	var gets_streamer : bool = object.get_meta("streamer") if object.has_meta("streamer") else false
#	var streamer_radius : float = object.get_meta("streamer_radius") if object.has_meta("streamer_radius") else 500.0
#
#	var detect_area_shape : Shape = object.get_meta("detection_area_shape") if object.has_meta("detection_area_shape") else default_detect_shape
#	var detectable_area_shape : Shape = object.get_meta("detectable_area_shape") if object.has_meta("detectable_area_shape") else default_detectable_shape
	
	var config = _check_for_configuration_nodes(object)
	
	var type : String = config["type"] # object.get_meta("type") if object.has_meta("type") else "passive"
	var persistent : bool = config["persistent"] # object.get_meta("persistent") if object.has_meta("persistent") else false
	var influence_value : int = config["influence_value"] # object.get_meta("influence_value") if object.has_meta("influence_value") else 1
	
	var gets_streamer : bool = config["streamer"] # object.get_meta("streamer") if object.has_meta("streamer") else false
	var streamer_radius : float = config["streamer_radius"] # object.get_meta("streamer_radius") if object.has_meta("streamer_radius") else 500.0
	
	var detect_area_shape : Shape = config["detection_area_shape"] # object.get_meta("detection_area_shape") if object.has_meta("detection_area_shape") else default_detect_shape
	var detectable_area_shape : Shape = config["detectable_area_shape"] # object.get_meta("detectable_area_shape") if object.has_meta("detectable_area_shape") else default_detectable_shape
	
	var ro
	
	match type:
		"active":
			ro = ActiveRegionObject.new(object, influence_value, persistent, detect_area_shape, detectable_area_shape)
		
		"passive":
			ro = PassiveRegionObject.new(object, influence_value, persistent, detect_area_shape, detectable_area_shape)
		
		"x", _:
			ro = RegionObject.new(object, influence_value, persistent, detect_area_shape, detectable_area_shape)
	
	if gets_streamer:
		ro.add_child(create_streamer(streamer_radius))
	
	return ro


func create_streamer(radius : float) -> RegionObjectStreamer:
	return RegionObjectStreamer.new(radius)
