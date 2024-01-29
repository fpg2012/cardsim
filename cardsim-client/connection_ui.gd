extends Node2D

signal connect_button_pressed(server: String, username: String, room: int)

const random_name_set = [
	'🍇', '🍈', '🍉', '🍊', '🍋', '🥝', '🍐', '🍎', '🥮', '🥑', '🧂'
]

@onready
var username_edit = $VBoxContainer/GridContainer/UsernameEditor
@onready
var server_edit = $VBoxContainer/GridContainer/ServerEditor
@onready
var room_edit = $VBoxContainer/GridContainer/RoomEditor
@onready
var connect_button = $VBoxContainer/Button

var valid_username = r'^\S{2,}$'
var valid_server = r'^((wss)|(ws))://[\w\.]+(:\d{1,5}){0,1}$'
var valid_room = r'^\d+$'

var regex_username = RegEx.new()
var regex_server = RegEx.new()
var regex_room = RegEx.new()

var label_press_count = 0

func validate_information():
	return validate_username() && validate_server() && validate_room()

func validate_username():
	return regex_username.search(username_edit.text) != null

func validate_server():
	return regex_server.search(server_edit.text) != null

func validate_room():
	return regex_room.search(room_edit.text) != null

# Called when the node enters the scene tree for the first time.
func _ready():
	username_edit.text = random_name_set.pick_random() + str(randi_range(100, 233))
	regex_username.compile(valid_username)
	regex_server.compile(valid_server)
	regex_room.compile(valid_room)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_label_gui_input(event):
	if (event is InputEventMouseButton && event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT):
		label_press_count += 1
		if label_press_count % 6 == 5:
			server_edit.text = "ws://localhost:8765"

func _on_button_pressed():
	if validate_information():
		connect_button_pressed.emit(server_edit.text, username_edit.text, int(room_edit.text))

func _on_server_editor_text_changed(new_text):
	server_edit.text = new_text.strip_edges()
	if not validate_server():
		server_edit.add_theme_color_override("font_color", Color.LIGHT_CORAL)
	else:
		server_edit.remove_theme_color_override("font_color")
	server_edit.caret_column = server_edit.text.length()

func _on_username_editor_text_changed(new_text):
	username_edit.text = new_text.strip_edges()
	if not validate_username():
		username_edit.add_theme_color_override("font_color", Color.LIGHT_CORAL)
	else:
		username_edit.remove_theme_color_override("font_color")
	username_edit.caret_column = username_edit.text.length()

func _on_room_editor_text_changed(new_text):
	room_edit.text = new_text.strip_edges()
	if not validate_room():
		room_edit.add_theme_color_override("font_color", Color.LIGHT_CORAL)
	else:
		room_edit.remove_theme_color_override("font_color")
	room_edit.caret_column = room_edit.text.length()
