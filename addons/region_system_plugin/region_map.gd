extends Spatial
class_name RegionMap, "res://addons/region_system_plugin/Region.svg"

################################################################################
## Signals

################################################################################
## Constants

################################################################################
## Private Variables

var _ids := PoolIntArray()
var _last_free_id : int = 1

################################################################################
## Public Variables

var region_objects := []

################################################################################
## Virtual Functions

func _init(_name := "RegionMap"):
	name = _name
#	Region_System_Global.add_region_map_to_roster(self)

################################################################################
## Private Functions

func _create_save_map():
	var p = PackedScene.new()
	p.pack(self)
	pass


func _generate_from_file():
	pass

################################################################################
## Public Functions

#func create_region_object(node : Node, _influence_level : int, persistent : bool):
#
#	var ro = RegionObject.new(node, _influence_level, persistent, SphereShape.new(), SphereShape.new(), "RegionObject_" + str(get_available_object_id()))
#
#	add_child(ro)
#	region_objects.append(ro)
#
#	return ro
#
#
#func create_active_ro(node : Node, _influence_level : int, persistent : bool, ro_owner : String):
#
#	var ro = ActiveRegionObject.new(node, _influence_level, persistent, "RegionObject_" + str(get_available_object_id()))
#
#	add_child(ro)
#	region_objects.append(ro)
#
#	return ro
#
#
#func create_passive_ro(node : Node, persistent : bool, ro_owner : String):
#
#	var ro = PassiveRegionObject.new(node, 1, persistent, "RegionObject_" + str(get_available_object_id()))
#
#	add_child(ro)
#	region_objects.append(ro)
#
#	return ro


#func create_ro(object : Spatial) -> RegionObject:
#	if not object:
#		return null
#
#	var should_be_in_blob := false
#	var blob_name := ""
#	var type : String = object.get_meta("type") if object.has_meta("type") else "passive"
#	var persistent : bool = object.get_meta("persistent") if object.has_meta("persistent") else false
#	var influence_value : int = object.get_meta("influence_value") if object.has_meta("influence_value") else 0
#
#	for group in object.get_groups():
#		if group.begins_with("blob-"):
#			should_be_in_blob = true
#			blob_name = group
#			blob_name.lstrip("blob-")
#
#	var ro
#
#	if should_be_in_blob:
#		type = "x"
#		pass
#
#	match type:
#		"active":
#			print(type)
#			ro = ActiveRegionObject.new(object, influence_value, persistent)
#
#		"passive":
#			print(type)
#			ro = PassiveRegionObject.new(object, influence_value, persistent)
#
#		"x":
#			print(type)
#			ro = RegionObject.new(object, influence_value, persistent)
#
#	return ro


func remove_region_object(region_object) -> bool:
	if region_objects.has(region_object):
		remove_child(region_object)
		region_objects.erase(region_object)
		var _a = Array(_ids)
		var _id_s = region_object.name.split("_")
		
		if _id_s.size() == 1:
			return false
		
		_a.erase(int(_id_s[-1]))
		return true
	
	else:
		return false


func find_region_object_by_id(id : int):
	var _name = "RegionObject_" + str(id)
	
	var n = find_node(_name, false, true)
	
	return n


func find_region_object_blob(_name : String):
	pass


func add_region_object(obj, id : int = -1) -> bool:
	if id < 0:
		id = get_available_object_id()
	
	if not Array(_ids).has(id):
		_ids.push_back(id)
		obj.name = obj.name + "_" + str(id)
		obj.owner = self
		add_child(obj)
		
		return true
	
	else:
		return false


func get_available_object_id() -> int:
	var cur_id = 1
	
	if get_child_count() == 0:
		return cur_id
	
	if Array(_ids).has(_last_free_id):
		cur_id = _last_free_id
		while Array(_ids).has(cur_id):
			cur_id += 1
		
		_last_free_id = cur_id
	
	return cur_id
