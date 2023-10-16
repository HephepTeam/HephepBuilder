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

@onready var windowslist = $PlatformsSettings/MarginContainer/PlatformSettingsHbox/WindowsExportCfg/WindowsPresetList
@onready var maclist = $PlatformsSettings/MarginContainer/PlatformSettingsHbox/MacExportCfg/MacPresetList
@onready var linuxlist = $PlatformsSettings/MarginContainer/PlatformSettingsHbox/LinuxExportCfg/LinuxPresetList

@onready var windowsCheckbox = $PlatformsSettings/MarginContainer/PlatformSettingsHbox/WindowsExportCfg/WindowsPlatformSettings/WindowsCheckbox
@onready var macCheckbox = $PlatformsSettings/MarginContainer/PlatformSettingsHbox/MacExportCfg/MacPlatformSettings/MacCheckbox
@onready var linuxCheckbox = $PlatformsSettings/MarginContainer/PlatformSettingsHbox/LinuxExportCfg/LinuxPlatformSettings/LinuxCheckbox

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
	windowslist.get_popup().connect("id_pressed", _on_windowsPresetList_pressed)
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
	var cmd_line 
	

	if windowsCheckbox.button_pressed == true: #prepare windows build
		
		#get export preset name
		var preset_name = windowslist.text
		#get export path
		var export_path = temp_export_presets_list[preset_name]["export_path"]
		
		#construct command line
		cmd_line = empty_cmd_line.duplicate()
		cmd_line["executable_path"] = godot_path
		cmd_line["project_path"] = project_path
		cmd_line["preset_name"] = preset_name
		cmd_line["export_path"] = export_path
		job_list.append(cmd_line)
		
	if linuxCheckbox.button_pressed == true: #prepare linux build
		
		#get export preset name
		var preset_name = linuxlist.text
		#get export path
		var export_path = temp_export_presets_list[preset_name]["export_path"]
		
		#construct command line
		cmd_line = empty_cmd_line.duplicate()
		cmd_line["executable_path"] = godot_path
		cmd_line["project_path"] = project_path
		cmd_line["preset_name"] = preset_name
		cmd_line["export_path"] = export_path
		job_list.append(cmd_line)
		
	if macCheckbox.button_pressed == true: #prepare mac OSX build
		
		#get export preset name
		var preset_name = maclist.text
		#get export path
		var export_path = temp_export_presets_list[preset_name]["export_path"]
		
		#construct command line
		cmd_line = empty_cmd_line.duplicate()
		cmd_line["executable_path"] = godot_path
		cmd_line["project_path"] = project_path
		cmd_line["preset_name"] = preset_name
		cmd_line["export_path"] = export_path
		job_list.append(cmd_line)
		
		
	# launch first job
	start_job()
#	var err = OS.excute("C:/gamedev/tools/Godot/win64-godotSteam352-s156-gs3192/windows-352-editor-64bit.exe",["--no-window", "--path", "C:/gamedev/repo/7dif", "--export", "Windows", "C:/gamedev/repo/7dif/Test.exe"],false,output,  false, false)
	
	
func start_job():
		if thread == null:
#		if pid == null:
			var job = job_list.pop_front()
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
	var err: int = OS.execute(job["executable_path"],["--no-window", "--path", job["project_path"], "--export",job["preset_name"], job["export_path"]], output,true)
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
	# update checkboxes and lists
	windowslist.get_popup().clear()
	maclist.get_popup().clear()
	linuxlist.get_popup().clear()
	
	for preset in temp_export_presets_list.values():
		if preset["platform"] == "Windows Desktop":
			$PlatformsSettings/MarginContainer/PlatformSettingsHbox/WindowsExportCfg/WindowsPlatformSettings/WindowsCheckbox.disabled = false
			windowslist.get_popup().add_item(preset["name"])
		elif preset["platform"] == "Linux/X11":
			$PlatformsSettings/MarginContainer/PlatformSettingsHbox/LinuxExportCfg/LinuxPlatformSettings/LinuxCheckbox.disabled = false
			linuxlist.get_popup().add_item(preset["name"])
		elif preset["platform"] == "Mac OSX":
			$PlatformsSettings/MarginContainer/PlatformSettingsHbox/MacExportCfg/MacPlatformSettings/MacCheckbox.disabled = false
			maclist.get_popup().add_item(preset["name"])
			
	# populate lists and update first element
	windowslist.text = windowslist.get_popup().get_item_text(0)
	maclist.text = maclist.get_popup().get_item_text(0)
	linuxlist.text = linuxlist.get_popup().get_item_text(0)
	$GamePresetSaveButton.disabled = false
	$GamePresetDeleteButton.disabled = false
			

func _on_windowsPresetList_pressed(id):
	windowslist.text = windowslist.get_popup().get_item_text(id)
	

func _on_windows_checkbox_pressed():
	check_checkboxes()


func _on_linux_checkbox_pressed():
	check_checkboxes()


func _on_mac_checkbox_pressed():
	check_checkboxes()
	
func check_checkboxes():
	if windowsCheckbox.button_pressed == true or \
		linuxCheckbox.button_pressed == true or \
		macCheckbox.button_pressed == true:
		$BuildButton.disabled = false
		
	else:
		$BuildButton.disabled = false
		
		
func disable_all(val : bool):
	$ProjectSettings/ProjectPathLineEdit.editable = !val 
	$ProjectSettings/ProjectBrowseButton.disabled = val
	$GodotSettings/GododtPathLineEdit.editable = !val
	$GodotSettings/GodotBrowseButton.disabled = val
	$PlatformsSettings/MarginContainer/PlatformSettingsHbox/WindowsExportCfg/WindowsPlatformSettings/WindowsCheckbox.disabled = val
	$PlatformsSettings/MarginContainer/PlatformSettingsHbox/WindowsExportCfg/WindowsPresetList.disabled = val
	$PlatformsSettings/MarginContainer/PlatformSettingsHbox/LinuxExportCfg/LinuxPlatformSettings/LinuxCheckbox.disabled = val
	$PlatformsSettings/MarginContainer/PlatformSettingsHbox/LinuxExportCfg/LinuxPresetList.disabled = val
	$PlatformsSettings/MarginContainer/PlatformSettingsHbox/MacExportCfg/MacPlatformSettings/MacCheckbox.disabled = val
	$PlatformsSettings/MarginContainer/PlatformSettingsHbox/MacExportCfg/MacPresetList.disabled = val
	$BuildButton.disabled = val
	$GamePresetSaveButton.disabled = val

func delete_game_preset(path):
	var dir = DirAccess.open("user://presets")
	dir.remove(path)

func save_game_preset():
	var preset = GamePreset.new()
	
	var project_name = temp_project_name
	var godot_path = $GodotSettings/GododtPathLineEdit.text
	var project_path = $ProjectSettings/ProjectPathLineEdit.text
	var platform_checkboxes = [windowsCheckbox.button_pressed,macCheckbox.button_pressed, linuxCheckbox.button_pressed ]
	var platform_presets = [windowslist.text,maclist.text, linuxlist.text ]
	
	preset.create(project_name,project_path,godot_path,platform_checkboxes,platform_presets  )
	
	var filename = project_name.replace(":","-")
	
	var ret = ResourceSaver.save(preset, PRESET_FOLDER_PATH+filename+".res")
	emit_signal("preset_saved")
	
func load_game_preset(project_name : String):
	var path = PRESET_FOLDER_PATH+project_name+".res"
	var preset = ResourceLoader.load(path) as GamePreset
	
	if preset == null:
		delete_game_preset(path)
	else:
		#update fields
		ProjectPathLine.text = preset["project_path"]
		temp_export_presets_list = parse_export_presets_cfg(preset["project_path"])
		temp_project_name = parse_project_dot_godot(preset["project_path"])
		emit_signal("project_path_loaded")
		GodotPathLine.text = preset["godot_version_path"]
		windowsCheckbox.button_pressed = preset["platforms_checked"][0]
		macCheckbox.button_pressed = preset["platforms_checked"][1]
		linuxCheckbox.button_pressed = preset["platforms_checked"][2]
		windowslist.text = preset["export_presets"][0]
		maclist.text = preset["export_presets"][1]
		linuxlist.text = preset["export_presets"][2]
		


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


func _on_button_pressed():
	get_tree().quit()


func _on_game_preset_delete_button_pressed():
	var path = PRESET_FOLDER_PATH+ $GamePreset.text+".res"
	delete_game_preset(path)
	get_game_preset_list()
	$GamePreset.text = ""
	$ProjectSettings/ProjectPathLineEdit.text = ""
	$GodotSettings/GododtPathLineEdit.text = ""
	# update checkboxes and lists
	windowslist.get_popup().clear()
	windowslist.text = ""
	maclist.get_popup().clear()
	maclist.text = ""
	linuxlist.get_popup().clear()
	linuxlist.text = ""
	$GamePresetSaveButton.disabled = false
	$GamePresetDeleteButton.disabled = false
