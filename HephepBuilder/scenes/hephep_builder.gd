extends Control

var empty_project_export_cfg = {
	"name" : "",
	"platform": "",
	"export_path": ""
}

var empty_cmd_line = {
	"executable_path" ="",
	"project_path" = "",
	"preset_name" = "",
	"export_path" = ""
}

var job_template = {
	"job_type"= "",
	"executable"="",
	"arguments"=["--no-window", "--path"],
	"project_path" = "",
	"preset_name" = "",
	"export_path" = ""
}

@onready var export_preset_item = preload("res://scenes/export_preset_item.tscn")

@onready var ProjectPathLine = $ProjectSettings/ProjectPathLineEdit
@onready var GodotPathLine = $GodotSettings/GododtPathLineEdit


signal project_path_loaded
signal preset_saved

const PRESET_FOLDER_PATH = "user://presets/"
var game_preset_list = []



var building = false
var pid_list = []

var temp_export_presets_list = {}
var temp_project_name = ""

var job_list = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open("user://")
	if !dir.dir_exists(PRESET_FOLDER_PATH):
		dir.make_dir_absolute(PRESET_FOLDER_PATH)
	get_game_preset_list()

# todo:
# when opening a godot project, I should store the path, and open the export_preset.cfg
# to check if any of the windows, linux and/or mac preset have been defined, to enable or 
# disable the corresponding checkbox OK

# show file explorer to get the project and the godot executable folder OK

# manage each export as an array of "job", probably I'll need to wait for one export to finish before
# starting another -> USE THREAD TO GET THE OUTPUT AND WRITE A LOG FILE THAT YOU OPEN AT THE END

# the tool should allow to save preset as Resource for each project and keep a list available to quick load

# C:/gamedev/tools/Godot/Godot_v3.5-stable_win64.exe/Godot_v3.5-stable_win64.exe --headless --path "C:/gamedev/repo/7dif" --export "Windows" "C:/gamedev/repo/7dif/test.exe"


var pid = null
var thread : Thread

func _process(delta):
	
	if building:
		if thread != null:
			if !thread.is_alive():
				$console.text += thread.wait_to_finish()
				$console.scroll_vertical = INF
				thread = null
		
		else:
			if !job_list.is_empty():
				start_job()
			else:
				$console.text += "All jobs done"
				$console.text += "\n"
				$console.scroll_vertical = INF
				building = false
				disable_all(false)

func _on_build_button_pressed():
	disable_all(true)
	
	var output = []
	
	var godot_path = $GodotSettings/GododtPathLineEdit.text
	var project_path = $ProjectSettings/ProjectPathLineEdit.text
	var job_todo
	
	var presets_checked = get_checked_export_presets()
	

	for preset in presets_checked.keys():
		if presets_checked[preset] == true:
			#get export preset name
			var preset_name = preset
			#get export path
			var export_path = temp_export_presets_list[preset_name]["export_path"]
			
			#construct command line
			job_todo = job_template.duplicate()
			job_todo["job_type"] = "godot_export"
			job_todo["executable"] = godot_path
			job_todo["project_path"] = project_path
			job_todo["preset_name"] = preset_name
			job_todo["export_path"] = export_path
			job_todo["arguments"] = ["--no-window", "--path"]
			job_todo["arguments"].append(project_path)
			job_todo["arguments"].append("--export")
			job_todo["arguments"].append(preset_name)
			job_todo["arguments"].append(export_path)
			
			job_list.append(job_todo)
	
	
	for line in $BatchList.scripts_list:
		# get script path
		var script_path = line[0]
		var args = line[1]
		#construct command line
		job_todo = job_template.duplicate()
		job_todo["job_type"] = "script"
		job_todo["executable"] = script_path
		job_todo["arguments"] = args.split(" ")
		job_list.append(job_todo)
			
		
	# launch first job
	start_job()
#	var err = OS.excute("C:/gamedev/tools/Godot/win64-godotSteam352-s156-gs3192/windows-352-editor-64bit.exe",["--no-window", "--path", "C:/gamedev/repo/7dif", "--export", "Windows", "C:/gamedev/repo/7dif/Test.exe"],false,output,  false, false)
	
	
func start_job():
		if thread == null:
#		if pid == null:
			var job = job_list.pop_front()
			if job["job_type"] == "godot_export":
				# todo: create export path folders
				var dir = DirAccess.open(job["project_path"])
				var export_folder = job["export_path"].get_base_dir() 
				if !dir.dir_exists(export_folder):
					DirAccess.make_dir_recursive_absolute(job["project_path"]+"/"+export_folder)
					
			$console.text += "Current job parameters: \n"
			$console.text += str(job)
			$console.text += "\n"
			$console.scroll_vertical = INF
			thread = Thread.new()
			thread.start(execute_job.bind(job),Thread.PRIORITY_NORMAL)
	#			pid = OS.create_process(job["executable_path"],["--no-window", "--path", job["project_path"], "--export",job["preset_name"], job["export_path"]], true)
			building = true


func execute_job(job) -> String:
	var output:= []
	var err: int = OS.execute(job["executable"],job["arguments"], output,true)
	if err != 0:
		printerr("Error occurred: %d" % err)
		return ("Error occurred: %d\n" % err) + "\n".join(PackedStringArray(output))

	return "\n".join(PackedStringArray(output))


func _on_project_browse_button_pressed():
	$ProjectDialog.visible = true


func _on_project_dialog_dir_selected(dir):
	var dirtemp = dir.get_base_dir()
	$ProjectSettings/ProjectPathLineEdit.text = dirtemp+"/"
	temp_export_presets_list = parse_export_presets_cfg(dirtemp)
	temp_project_name = parse_project_dot_godot(dirtemp)
	delete_scripts_display()
	$BatchList.scripts_list = []
	$BatchList/ScriptPathLineEdit.text = ""
	$BatchList/ScriptArgsLineEdit.text = ""
	emit_signal("project_path_loaded")
	

func _on_godot_browse_button_pressed():
	$GodotDialog.visible = true

func _on_godot_dialog_file_selected(path):
	$GodotSettings/GododtPathLineEdit.text = path
	
# parse export_presets.cfg file to get relevant informations for later
func parse_export_presets_cfg(project_path : String):
	var current_export_preset = {}
	var available_export_presets = {}
	var cfg_file_full_path = project_path+"/export_presets.cfg"
	
	#open file
	var file = FileAccess.open(cfg_file_full_path, FileAccess.READ)
	#read each line
	while file.get_position() < file.get_length():
		var line = file.get_line()
		
		#create an entry every [preset.X] in a dictionnary (use a class?)
		if line.contains("[preset."):
			if !line.contains(".options"):
				current_export_preset = empty_project_export_cfg.duplicate()
		
		#store for each entry:
		#name
		if line.begins_with("name="):
			var preset_name = line.split("=")[1].rstrip('"').lstrip('"')	
			current_export_preset["name"]= preset_name
		
		#platform (check platform type to enable checkboxes)	
		if line.begins_with("platform="):
			var preset_platform = line.split("=")[1].rstrip('"').lstrip('"')	
			if preset_platform in ["Windows Desktop","Mac OSX", "Linux/X11" ]:
				current_export_preset["platform"]= preset_platform
		
		#get export_path (allow to edit/override)
		if line.begins_with("export_path="):
			var preset_export_path = line.split("=")[1].rstrip('"').lstrip('"')	
			current_export_preset["export_path"]= preset_export_path
			
		if current_export_preset["platform"] != "":
			available_export_presets[current_export_preset["name"]]=current_export_preset
			
		
	return available_export_presets
	
	
	
	
func parse_project_dot_godot(path : String):
	var prj_file_full_path = path+"/project.godot"
	var project_name = ""
	#open file
	var file = FileAccess.open(prj_file_full_path, FileAccess.READ)
	#read each line
	while file.get_position() < file.get_length():
		var line = file.get_line()
		#create an entry every [preset.X] in a dictionnary (use a class?)
		if line.contains("config/name="):
			var temp = line.split("=")[1]
			var temp2 = temp.rstrip('"')
			project_name = temp2.lstrip('"')
			break
			
	return project_name


func _on_project_path_loaded():
	delete_export_preset_items()
	for preset in temp_export_presets_list.values():
		if preset["platform"] == "Windows Desktop":
			var item = export_preset_item.instantiate()
			item.connect("checkbox_pressed", check_checkboxes)
			$PlatformsSettings/MarginContainer/PlatformSettingsHbox/WindowsPreset.add_child(item)
			item.preset_name.text = preset["name"]
#			$PlatformsSettings/MarginContainer/PlatformSettingsHbox/WindowsExportCfg/WindowsPlatformSettings/WindowsCheckbox.disabled = false
#			windowslist.get_popup().add_item(preset["name"])
		elif preset["platform"] == "Linux/X11":
			var item = export_preset_item.instantiate()
			item.connect("checkbox_pressed", check_checkboxes)
			$PlatformsSettings/MarginContainer/PlatformSettingsHbox/LinuxPreset.add_child(item)
			item.preset_name.text = preset["name"]
		elif preset["platform"] == "Mac OSX":
			var item = export_preset_item.instantiate()
			item.connect("checkbox_pressed", check_checkboxes)
			$PlatformsSettings/MarginContainer/PlatformSettingsHbox/MacPreset.add_child(item)
			item.preset_name.text = preset["name"]
			
	$GamePresetSaveButton.disabled = false
	$GamePresetDeleteButton.disabled = false
			
	
func check_checkboxes():
	$BuildButton.disabled = true
	#if at least one checkbox is checked, allow build
	var presets = get_checked_export_presets()
	for preset in presets.values():
		if preset == true:
			$BuildButton.disabled = false
			return
	return

		
		
func disable_all(val : bool):
	$ProjectSettings/ProjectPathLineEdit.editable = !val 
	$ProjectSettings/ProjectBrowseButton.disabled = val
	$GodotSettings/GododtPathLineEdit.editable = !val
	$GodotSettings/GodotBrowseButton.disabled = val
	# TODO DISABLE ALL CHECKBOXES
	$BuildButton.disabled = val
	$GamePresetSaveButton.disabled = val

func delete_game_preset(path):
	var dir = DirAccess.open("user://presets")
	dir.remove(path)

func get_checked_export_presets() -> Dictionary:
	var presets = {}
	for column in $PlatformsSettings/MarginContainer/PlatformSettingsHbox.get_children():
		for preset in column.get_children():
			var checked = preset.checkbox.button_pressed
			presets[preset.preset_name.text] = checked
	return presets

func save_game_preset():
	var preset = GamePreset.new()
	
	var project_name = temp_project_name
	var godot_path = $GodotSettings/GododtPathLineEdit.text
	var project_path = $ProjectSettings/ProjectPathLineEdit.text
	var platform_presets = get_checked_export_presets()
	var list = $BatchList.scripts_list
	
	preset.create(project_name,project_path,godot_path,platform_presets, list  )
	
	var filename = project_name.replace(":","-")
	
	var ret = ResourceSaver.save(preset, PRESET_FOLDER_PATH+filename+".res")
	emit_signal("preset_saved")
	
func load_game_preset(project_name : String):
	var path = PRESET_FOLDER_PATH+project_name+".res"
	var preset = ResourceLoader.load(path) as GamePreset

	delete_export_preset_items()
	delete_scripts_display()
	$BatchList/ScriptPathLineEdit.text = ""
	$BatchList/ScriptArgsLineEdit.text = ""
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
			
	if preset == null:
		delete_game_preset(path)
	else:
		#update fields
		ProjectPathLine.text = preset["project_path"]
		temp_export_presets_list = parse_export_presets_cfg(preset["project_path"])
		temp_project_name = parse_project_dot_godot(preset["project_path"])
		emit_signal("project_path_loaded")
		GodotPathLine.text = preset["godot_version_path"]
		var presets_checked = preset["export_presets"].values()
		var i = 0
		for column in $PlatformsSettings/MarginContainer/PlatformSettingsHbox.get_children():
			for preset_item in column.get_children():
				preset_item.checkbox.button_pressed = presets_checked[i]
				i+=1
		$BatchList.scripts_list = preset["scripts_list"]
		$BatchList.update_item_list()
		
func delete_scripts_display():
	$BatchList/ScriptItemList.clear()

func delete_export_preset_items():
	for column in $PlatformsSettings/MarginContainer/PlatformSettingsHbox.get_children():
		for preset_item in column.get_children():
			preset_item.queue_free()


func _on_game_preset_save_button_pressed():
	$GamePreset.text = temp_project_name
	save_game_preset()
	get_game_preset_list()
	
	#update game preset list

func get_game_preset_list():
	var dir = DirAccess.open(PRESET_FOLDER_PATH)
	var presets_path = dir.get_files()
	$GamePreset.get_popup().clear()
	
	
	if !presets_path.is_empty():
		for path in presets_path:
			if path.contains(".res"):
				$GamePreset.get_popup().add_item(path.trim_suffix(".res"))
#		$GamePreset.text = $GamePreset.get_popup().get_item_text(0)
		
		$GamePreset.get_popup().connect("id_pressed", _on_GamePreset_item_pressed)
	
func _on_GamePreset_item_pressed(id):
	$GamePreset.get_popup().get_item_text(id)
	load_game_preset($GamePreset.get_popup().get_item_text(id))
	$GamePreset.text = $GamePreset.get_popup().get_item_text(id)
	$GamePresetSaveButton.disabled = false

func _on_game_preset_delete_button_pressed():
	var path = PRESET_FOLDER_PATH+ $GamePreset.text+".res"
	delete_game_preset(path)
	get_game_preset_list()
	$GamePreset.text = ""
	$ProjectSettings/ProjectPathLineEdit.text = ""
	$GodotSettings/GododtPathLineEdit.text = ""
	# delete export preset items
	delete_export_preset_items()
	$GamePresetSaveButton.disabled = false
	$GamePresetDeleteButton.disabled = false
	#empty script list and fields
	$BatchList/ScriptPathLineEdit.text = ""
	$BatchList/ScriptArgsLineEdit.text = ""
	$BatchList.scripts_list = []
	$BatchList.update_item_list()

