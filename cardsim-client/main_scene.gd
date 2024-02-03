extends Node2D

const MIN_GRID_SIZE = 12
const DEFAULT_GRID_SIZE = 30
const DEBUG_DISABLE_SERVER = false

var grid_width = 30

var my_square_scene = preload("res://square.tscn")
@onready
var content = get_node("Content")
@onready
var grid = get_node("GridSystem")
@onready
var websocket_handler = get_node("WebsocketHandler")

var selected_squares = [] # list of component_id_
var squares = {} # component_id_ => square
var squares_last_state = {} # component_id_ => square

# dragging states
enum {
	STATE_NOT_DRAGGING = 0,
	STATE_START_DRAGGING = 1,
	STATE_DRAGGING = 2
}

var dragging_right = false
var dragging_left = false
var dragging_left_square = STATE_NOT_DRAGGING

var enable_input = false

# signals
# dragging
signal dragging_node_start(component_id_s)
signal dragging_node_end(nodes)
# add and remove
signal square_added(nodes)
signal square_removed(component_id_s)
signal square_modify(nodes)
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

func zoom(zoom_grid_width, center):
	grid_width = zoom_grid_width
	grid.grid_size = grid_width
	var factor = float(grid_width) / DEFAULT_GRID_SIZE
	content_scale(factor, center)

func query_square_by_pos(pos: Vector2):
	var chosen = null
	for component_id_ in squares.keys():
		var node = squares[component_id_]
		if (node.position == round_position(pos)) && (chosen == null || (chosen != null && chosen.z_index < node.z_index)):
			chosen = node
	return chosen

# selection related functions
func select(node):
	if node.component_id_ not in selected_squares:
		node.set_selected(true)
		selected_squares.append(node.component_id_)

func deselected(node):
	if node.component_id_ in selected_squares:
		node.set_selected(false)
		selected_squares.erase(node.component_id_)

func freeze(node):
	deselected(node)
	node.position = round_position(node.position + Vector2(node.square_width / 2, node.square_width / 2))
	node.set_freeze(true)

func unfreeze(node):
	node.set_freeze(false)

func deselect_all():
	for component_id_ in selected_squares:
		squares[component_id_].set_selected(false)
	selected_squares.clear()

func delete_selected():
	save_last_state(selected_squares)
	for component_id_ in selected_squares:
		_delete_square_by_id(component_id_, false)
	square_removed.emit(selected_squares.duplicate(true))
	selected_squares.clear()

func save_last_state(component_id_s):
	for component_id_ in component_id_s:
		squares_last_state[component_id_] = squares[component_id_].to_dict()

# add & delete
func _add_square(pos: Vector2):
	var new_square = my_square_scene.instantiate().setup(pos, Vector2(DEFAULT_GRID_SIZE, DEFAULT_GRID_SIZE))
	squares[new_square.component_id_] = new_square
	content.add_child(new_square)
	print(self.log_info() + 'add ' + JSON.stringify(new_square.to_dict()))
	return new_square

func add_square_remote(component_id_: int, node_model):
	node_model.component_id_ = component_id_
	var node = my_square_scene.instantiate().from_dict(node_model)
	squares[component_id_] = node
	content.add_child(node)
	print(self.log_info() + 'remote add ' + str(node_model))
	return node

func add_square_local(pos: Vector2):
	var new_square = _add_square(pos)
	square_added.emit([new_square])

func delete_square_by_pos_local(pos: Vector2):
	var node = query_square_by_pos(pos)
	delete_square_by_id_local(node.component_id_)

func _delete_square_by_id(component_id_: int, deselect: bool = true):
	var node = squares[component_id_]
	content.remove_child(node)
	squares.erase(component_id_)
	if deselect:
		selected_squares.erase(component_id_)

func delete_square_by_id_local(component_id_):
	save_last_state([component_id_])
	_delete_square_by_id(component_id_)
	square_removed.emit([component_id_])

# should not use this function to update component_id_
func update_square_by_id_remote(component_id_: int, node_model):
	node_model.component_id_ = component_id_ # important!
	var node = squares[component_id_]
	node.from_dict(node_model)
	print(self.log_info() + 'remote update ' + str(node_model))
	return node

func rollback(component_id_):
	print(self.log_info(), 'rollback: ', component_id_)
	if component_id_ not in squares_last_state.keys():
		_delete_square_by_id(component_id_)
	else:
		update_square_by_id_remote(component_id_, squares_last_state[component_id_])

func init_game_state(game_state):
	if game_state == null:
		return
	if 'components' in game_state:
		for component in game_state.components:
			add_square_remote(int(component.component_id_), component)
	if 'online' in game_state:
		for user in game_state.online:
			$UserListUI.add_user(user)

# dragging related functions
func set_dragging_right(is_enabled: bool):
	self.dragging_right = is_enabled # start dragging right

func set_dragging_left(is_enabled: bool):
	self.dragging_left = is_enabled # start dragging left

func set_dragging_left_sqaure(drag_state: int):
	self.dragging_left_square = drag_state

# input handlers
func handle_mouse_wheel(up: int, pos: Vector2):
	if up > 0 || (up < 0 && grid_width > MIN_GRID_SIZE):
		zoom(grid_width + up, pos)

func handle_right_click(is_pressed: bool):
	if dragging_left:
		return
	set_dragging_right(is_pressed)
	deselect_all()

func handle_left_click(pos: Vector2):
	if dragging_right:
		return
	var local_pos = round_position(content.to_local(pos))
	set_dragging_left(true)
	var node = query_square_by_pos(local_pos)
	print(node)
	if node == null: # click empty area
		if selected_squares.is_empty():
			add_square_local(local_pos)
		deselect_all()
	else: # click on square
		if !node.freezed:
			set_dragging_left_sqaure(STATE_START_DRAGGING)
			if !Input.is_key_pressed(KEY_CTRL):
				deselect_all()
			select(node)
		else:
			deselect_all()

func handle_left_release(pos: Vector2):
	set_dragging_left(false)
	if dragging_left_square == STATE_DRAGGING || dragging_left_square == STATE_START_DRAGGING:
		for component_id_ in selected_squares:
			var node = squares[component_id_]
			node.position = round_position(node.position + Vector2(node.square_width / 2, node.square_height / 2))
		if dragging_left_square == STATE_DRAGGING:
			var nodes = []
			for component_id_ in selected_squares:
				nodes.append(squares[component_id_])
			dragging_node_end.emit(nodes.duplicate()) # commit
		set_dragging_left_sqaure(STATE_NOT_DRAGGING)

func handle_mouse_motion(pos: Vector2, d_pos: Vector2):
	if dragging_right:
		content.position += d_pos
		grid.offset += d_pos
	elif dragging_left_square == STATE_DRAGGING || dragging_left_square == STATE_START_DRAGGING:
		for square in selected_squares:
			var node = squares[square]
			if !node.freezed:
				node.position = content.to_local(content.to_global(node.position) + d_pos)
		if dragging_left_square == STATE_START_DRAGGING:
			set_dragging_left_sqaure(STATE_DRAGGING)
			save_last_state(selected_squares)
			dragging_node_start.emit(selected_squares.duplicate()) # declare

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
		elif event.keycode == KEY_F5:
			zoom(DEFAULT_GRID_SIZE, Vector2(0, 0))
			content.position = Vector2(0, 0)
			grid.offset = Vector2(0, 0)

func log_info():
	return websocket_handler.log_info()

# Called when the node enters the scene tree for the first time.
func _ready():
	if DEBUG_DISABLE_SERVER:
		_on_connection_successed(null)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# callbacks
func _on_connection_failed(result):
	printerr('failed to connect to server, code', result)
	set_process(false)

func _on_connection_successed(game_state):
	set_process(true)
	enable_input = true
	init_game_state(game_state)
	$ConnectionUI.visible = false
	$UserListUI.visible = true

func _on_connection_ui_connect_button_pressed(server, username, room):
	websocket_handler.url = server
	websocket_handler.username = username
	websocket_handler.room_id = room
	start_connection.emit()

func _on_websocket_handler_event_operate_commited(id_, ops):
	for op in ops:
		if op.action == "add":
			add_square_remote(int(op.component_id_), op.changed)
		elif op.action == "remove":
			_delete_square_by_id(int(op.component_id_))
		elif op.action == "modify":
			update_square_by_id_remote(int(op.component_id_), op.changed)
		var component_id_ = int(op.component_id_)
		if component_id_ in squares.keys():
			unfreeze(squares[component_id_])

func _on_websocket_handler_event_operate_declared(id_, ops):
	for op in ops:
		var component_id_ = int(op.component_id_)
		if op.action == "modify" || op.action == "remove":
			if component_id_ in squares.keys():
				freeze(squares[component_id_])

func _on_websocket_handler_cancel_ops(ops):
	for op in ops:
		var component_id_: int = int(op.component_id_)
		if component_id_ in squares.keys():
			freeze(squares[component_id_])
		rollback(component_id_)
		if component_id_ in squares.keys():
			freeze(squares[component_id_])

func _on_websocket_handler_update_id(response_ops):
	for op in response_ops:
		var old_id = int(op.changed.component_id_)
		var new_id = int(op.component_id_)
		var node = squares[old_id]
		node.component_id_ = new_id
		squares.erase(old_id)
		squares[new_id] = node
		if old_id in selected_squares:
			deselected(node)

func _on_websocket_handler_event_join(username, id_):
	$UserListUI.add_user({
		"username": username,
		"id_": int(id_)
	})

func _on_websocket_handler_event_quit(id_):
	$UserListUI.remove_user(int(id_))
