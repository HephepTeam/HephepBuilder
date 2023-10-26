extends HBoxContainer

signal checkbox_pressed

@onready var checkbox = $CheckBox as CheckBox
@onready var preset_name = $preset_name as Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_check_box_pressed():
	emit_signal("checkbox_pressed")
