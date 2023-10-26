extends Resource
class_name GamePreset

@export var project_name = ""
@export var project_path = ""
@export var godot_version_path = ""
@export var export_presets = {}
@export var scripts_list = []

func create(prj, prjpath, godot_ver, presets, list):
	project_name = prj
	project_path = prjpath
	godot_version_path =godot_ver
	export_presets = presets
	scripts_list = list
