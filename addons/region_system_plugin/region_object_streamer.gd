extends Spatial
class_name RegionObjectStreamer

#signal object_loaded(object)

################################################################################
## Constants

const SAVE_LOAD_PATH = "user://region_system/temp/streamer/"

################################################################################
## Private Variables

var _temp_ids = PoolIntArray()

################################################################################
## Public Variables

################################################################################
## Virtual Functions

func _init(load_area_radius := 50.0) -> void:
	name = "RegionObjectStreamer"
	
#	print(get_instance_id())
	_constructor(load_area_radius)
	
#	var p = SphereMesh.new()
#	p.radius = load_area_radius / 2
#	p.height = load_area_radius
#	p.flip_faces = true
#	var m = MeshInstance.new()
#	m.mesh = p
#	add_child(m)


func _notification(what):
	# I want to delete the directory for this RegionObjectStreamer
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			_remove_recursive(SAVE_LOAD_PATH + str(get_instance_id()))
	
	return


func _exit_tree():
	_remove_recursive(SAVE_LOAD_PATH + str(get_instance_id()))

################################################################################
## Private Functions

func _constructor(load_area_radius := 500.0) -> void:
	
	var load_area = Area.new()
	var load_collision_shape = CollisionShape.new()
	var load_shape = SphereShape.new()
	load_shape.radius = load_area_radius
	load_collision_shape.shape = load_shape
	
	load_area.connect("area_entered", self, "_on_detector_area_entered")
	load_area.connect("area_exited", self, "_on_detector_area_exited")
	
	load_area.add_child(load_collision_shape)
	add_child(load_area)
	
	var dir = Directory.new()
	if not dir.dir_exists(SAVE_LOAD_PATH + "/" + str(get_instance_id())):
			dir.make_dir_recursive(SAVE_LOAD_PATH + "/" + str(get_instance_id()))
	
	return


func _get_new_save_id() -> int:
	var ret_int = _temp_ids.size()
	
	return ret_int


func _create_save(object):
	# We need to use the resource saver for this.
	var ps = PackedScene.new()
	ps.pack(object)
	var id = object.get_instance_id()
	_temp_ids.push_back(id)
	
#	var dir = Directory.new()
#	if not dir.dir_exists(SAVE_LOAD_PATH + "/" + str(get_instance_id())):
#			dir.make_dir(SAVE_LOAD_PATH + "/" + str(get_instance_id()))
	
	var path = SAVE_LOAD_PATH + "/" + str(get_instance_id()) + "/" + str(id) + ".tscn"
	ResourceSaver.save(path, ps)


func _load_save(id : int) -> PackedScene:
	var ti = Array(_temp_ids)
	
	if ti.has(id):
		var dir = Directory.new()
		if not dir.dir_exists(SAVE_LOAD_PATH + "/" + str(get_instance_id())):
			return null
		
		elif not dir.file_exists(SAVE_LOAD_PATH + "/" + str(get_instance_id()) + str(id)):
			return null
			
		
		var ps = ResourceLoader.load(SAVE_LOAD_PATH + "/" + str(get_instance_id()) + "/" + str(id) + ".tscn")
		# Need to do something with the PackedScene.
		
		ti.erase(id)
		_temp_ids = PoolIntArray(ti)
		
		return ps
	
	return null


func _remove_recursive(path):
	var directory = Directory.new()
	
	# Open directory
	var error = directory.open(path)
	if error == OK:
		# List directory content
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				_remove_recursive(path + "/" + file_name)
			else:
				directory.remove(file_name)
			file_name = directory.get_next()
		
		# Remove current path
		directory.remove(path)
	else:
		print("Error removing " + path)

################################################################################
## Public Functions

func create_packed_scene(object : Spatial) -> PackedScene:
	var p := PackedScene.new()
	p.pack(object)
	return p

################################################################################
## Signal Functions

"""
	Need to figure out how to temporarily save the information needed for
	this whole thing. I need to remember which RegionArea a saved object or
	group of saved objects came from.
	
	I'm going to completely rework this later; it's late.
"""

func _on_detector_area_entered(area : Area):
	if not (area.get_parent() == self) and not (area.get_parent() == get_parent()) and area.name == "DetectionArea" and not (area.get_parent().get_node_or_null("RegionObjectStreamer")):
		if area.get_parent() is RegionObjectBlob:
			var _id = area.get_parent().get_instance_id()# + "_" + str(area.get_parent().get_children().find(area))
			if Array(_temp_ids).has(_id):
				var ps = _load_save(_id)
				
				
#				area.get_parent().queue_free()
		
		else:
			var _id = area.get_parent().get_object_instance_id()
			if Array(_temp_ids).has(_id):
				var ps = _load_save(_id)
				
				area.get_parent().object = ps.object
				
				
#				area.get_parent().object.queue_free()


func _on_detector_area_exited(area : Area):
	if not (area.get_parent() == self) and not (area.get_parent() == get_parent()) and area.name == "DetectionArea" and not (area.get_parent().get_node_or_null("RegionObjectStreamer")):
		if area.get_parent() is RegionObjectBlob:
			var _id = area.get_parent().get_instance_id()# + "_" + str(area.get_parent().get_children().find(area))
			if Array(_temp_ids).has(_id):
				_create_save(_id)
				
				for object in area.get_parent().objects:
					object.queue_free()
		
		else:
			var _id = area.get_parent().get_object_instance_id()
			if not Array(_temp_ids).has(_id):
				_create_save(area.get_parent())
				
				area.get_parent().object.queue_free()
