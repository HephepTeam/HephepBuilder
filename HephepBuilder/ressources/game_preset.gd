extends Resource
class_name GamePreset

@export var project_name = ""
@export var project_path = ""
@export var godot_version_path = ""
@export var	platforms_checked = {"Windows Desktop" : false, "Mac OSX": false, "Linux/X11": false}
@export var export_presets = {"Windows Desktop" : "", "Mac OSX": "", "Linux/X11": ""}

func create(prj, prjpath, godot_ver, platforms, presets):
	project_name = prj
	project_path = prjpath
	godot_version_path =godot_ver
	platforms_checked = platforms
	export_presets = presets
