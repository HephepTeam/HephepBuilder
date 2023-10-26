extends Control

var enabled = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_itch_dialog_file_selected(path):
	$ScriptPathLineEdit.text = path
	$AddScriptButton.disabled = false


func _on_itch_script_browse_button_pressed():
	$ScriptDialog.visible = true
