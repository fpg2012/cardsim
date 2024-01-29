extends Node2D

const MIN_GRID_SIZE = 12
const DEFAULT_GRID_SIZE = 30

var grid_width = 30

var my_square_scene = preload("res://square.tscn")
@onready
var content = get_node("Content")
@onready
var grid = get_node("GridSystem")
@onready
var websocket_handler = get_node("WebsocketHandler")

var selected_squares = []
var squares = {}

# dragging states
var dragging_right = false
var dragging_left = false
var dragging_left_square = false

var enable_input = false

# signals
# dragging
signal dragging_node_start(nodes)
signal dragging_node_end(nodes)
# network
signal start_connection(url)

# utility functions
func round_position(pos: Vector2):
	var new_pos = Vector2(0, 0)
	new_pos[0] = floor(pos[0] / DEFAULT_GRID_SIZE) * DEFAULT_GRID_SIZE
	new_pos[1] = floor(pos[1] / DEFAULT_GRID_SIZE) * DEFAULT_GRID_SIZE
	return new_pos

func content_scale(scale_factor: float, center: Vector2):
	var local_center = content.to_local(center)
	var old_scale_factor = content.scale.x
	var t_prime = (old_scale_factor - scale_factor) * local_center
	content.scale = Vector2(scale_factor, scale_factor)
	content.position += t_prime
	grid.offset = content.position

# selection related functions
func deselect_all():
	for square in selected_squares:
		squares[square].set_selected(false)
	selected_squares.clear()

func delete_selected():
	for square in selected_squares:
		var node = squares[square]
		content.remove_child(node)
		node.queue_free()
		squares.erase(square)
	selected_squares.clear()

# add & delete
func add_square(pos: Vector2):
	var new_square = my_square_scene.instantiate().setup(pos, Vector2(DEFAULT_GRID_SIZE, DEFAULT_GRID_SIZE))
	squares[pos] = new_square
	content.add_child(new_square)
	print('add ' + str(new_square))

func delete_square(pos: Vector2):
	var node = squares[pos]
	content.remove_child(node)
	node.queue_free()
	squares.erase(pos)
	selected_squares.erase(pos)

# dragging related functions
func set_dragging_right(is_enabled: bool):
	dragging_right = is_enabled # start dragging right

func set_dragging_left(is_enabled: bool):
	dragging_left = is_enabled # start dragging left

func set_dragging_left_sqaure(is_enabled: bool):
	dragging_left_square = is_enabled

# input handlers
func handle_mouse_wheel(up: int, pos: Vector2):
	if up > 0:
		grid_width += up
		grid.grid_size = grid_width
		var factor = float(grid_width) / DEFAULT_GRID_SIZE
		content_scale(factor, pos)
	elif up < 0 && grid_width > MIN_GRID_SIZE:
		grid_width += up
		grid.grid_size = grid_width
		var factor = float(grid_width) / DEFAULT_GRID_SIZE
		content_scale(factor, pos)
	else:
		pass

func handle_right_click(is_pressed: bool):
	set_dragging_right(is_pressed)
	deselect_all()

func handle_left_click(pos: Vector2):
	var local_pos = round_position(content.to_local(pos))
	set_dragging_left(true)
	if !squares.has(local_pos): # click empty area
		if selected_squares.is_empty():
			add_square(local_pos)
		deselect_all()
	else: # click on square
		set_dragging_left_sqaure(true)
		var node = squares[local_pos]
		if !Input.is_key_pressed(KEY_CTRL):
			deselect_all()
		node.set_selected(true)
		if !selected_squares.has(local_pos):
			selected_squares.append(local_pos)

func handle_left_release(pos: Vector2):
	print('left_release')
	set_dragging_left(false)
	if dragging_left_square:
		set_dragging_left_sqaure(false)
		print('before', selected_squares)
		var new_selected = []
		for square in selected_squares:
			print('processing', square)
			var node = squares[square]
			node.position = round_position(node.position + Vector2(node.square_width / 2, node.square_height / 2))
			print('erase', square, node)
			squares.erase(square)
			print('add', node.position, node)
			squares[node.position] = node
			new_selected.append(node.position)
		selected_squares = new_selected
		print('after', selected_squares)

func handle_mouse_motion(pos: Vector2, d_pos: Vector2):
	if dragging_right:
		content.position += d_pos
		grid.offset += d_pos
	if dragging_left_square:
		for square in selected_squares:
			var node = squares[square]
			node.position = content.to_local(content.to_global(node.position) + d_pos)

# callbacks
func _on_connection_failed(result):
	print('failed to connect to server, code', result)
	set_process(false)

func _on_connection_successed():
	set_process(true)
	enable_input = true
	$ConnectionUI.visible = false

func _on_connection_ui_connect_button_pressed(server, username, room):
	websocket_handler.url = server
	websocket_handler.username = username
	websocket_handler.room_id = room
	start_connection.emit()

func _unhandled_input(event):
	if !enable_input:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click(event.is_pressed())
		elif event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
			handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT && event.is_released():
			handle_left_release(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			handle_mouse_wheel(+1, event.position);
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			handle_mouse_wheel(-1, event.position);
	if event is InputEventMouseMotion:
		handle_mouse_motion(event.position, event.relative)
	if event is InputEventKey:
		if event.keycode == KEY_DELETE:
			delete_selected()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
