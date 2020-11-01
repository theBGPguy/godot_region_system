tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("Region_System_Global",
							"res://addons/region_system_plugin/region_system_global.gd")
	
#	RegionObject.editor_description = "The base node for all RegionObjects. Provides the base functionality for all RegionObjects."
#	ActiveRegionObject.editor_description = "An 'Active' RegionObject. This has influence over other RegionObjects, as well as PassiveRegionObjects."
#	PassiveRegionObject.editor_description = "A 'Passive' RegionObject. This has no influence over other RegionObjects."


func _exit_tree():
	remove_autoload_singleton("Region_System_Global")
