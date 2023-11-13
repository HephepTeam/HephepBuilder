extends Control

var enabled = false

@onready var item_list = $ScriptItemList

var scripts_list = []
var script_selected_idx = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func update_item_list():
	$ScriptItemList.clear()
	if scripts_list != []:
		for line in scripts_list:
			var idx_tmp = $ScriptItemList.add_item(line[0])
			$ScriptItemList.set_item_tooltip(idx_tmp, line[0]+" "+line[1])
			idx_tmp = $ScriptItemList.add_item(line[1],null,false)
			$ScriptItemList.set_item_tooltip(idx_tmp, line[0]+" "+line[1])
			

func switch_items(from_idx : int, to_idx : int):
	var temp = scripts_list[to_idx]
	scripts_list[to_idx] = scripts_list[from_idx] 
	scripts_list[from_idx] = temp
	


func _on_itch_dialog_file_selected(path):
	$ScriptPathLineEdit.text = path
	$AddScriptButton.disabled = false


func _on_itch_script_browse_button_pressed():
	$ScriptDialog.visible = true


func _on_list_up_button_pressed():
	if script_selected_idx > 0:
		switch_items(script_selected_idx, script_selected_idx-1)
	update_item_list()

func _on_list_down_button_pressed():
	if script_selected_idx < scripts_list.size()-1:
		switch_items(script_selected_idx, script_selected_idx+1)
	update_item_list()

func _on_add_script_button_pressed():
	var line = [$ScriptPathLineEdit.text, $ScriptArgsLineEdit.text]
	scripts_list.append(line)
	update_item_list()


func _on_del_script_button_pressed():
	#remove script line from the array and update list
	scripts_list.remove_at(script_selected_idx)
	update_item_list()
	$DelScriptButton.disabled = true
	$ListUpButton.disabled = true
	$ListDownButton.disabled = true


func _on_script_item_list_item_selected(index):
	index = int(index / 2) * 2 
	script_selected_idx = index/2
	$DelScriptButton.disabled = false
	$ListUpButton.disabled = false
	$ListDownButton.disabled = false



