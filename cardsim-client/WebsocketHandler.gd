extends Node

enum GameConnectionState {
	STATE_CONNECTING = 0,
	STATE_ESTABLISHED = 1,
	STATE_CONNECTING_WAIT_FOR_ACK = 3,
	STATE_DISCONNECTED = -1,
	STATE_ERROR = -2,
}

var game_connection_state: GameConnectionState = GameConnectionState.STATE_DISCONNECTED

var socket = WebSocketPeer.new()
var url = "ws://localhost:8765"
var last_state = WebSocketPeer.STATE_CLOSED

var username = "username"
var id = 0
var token = 0
var room_id = 0
var seq = randi_range(0, 10000)
var wait_for_ack_seq = seq

var request_queue = []
var request_buffer = {} # seq => request
var request_callback = {} # seq => callable

signal connection_failed(error: Error)
signal connection_successed(game_state)
# operate signals
#signal operate_declared(ok: bool, request)
#signal operate_commited(ok: bool, data: Array[Dictionary], request)
signal cancel_ops(ops)
signal update_id(response_ops)
signal event_operate_declared(id_: int, ops)
signal event_operate_commited(id_: int, ops)
signal event_join(username: String, id_: int)
signal event_quit(id_: int)

func check_ack_seq(packet):
	if packet['ack_seq'] != self.wait_for_ack_seq:
		printerr(self.log_info(), 'ack_seq(%d) != wait_for_ack_seq(%d):' % [packet['ack_seq'], self.wait_for_ack_seq])
		return false
	wait_for_ack_seq += 1
	return true

func connect_to_server():
	game_connection_state = GameConnectionState.STATE_CONNECTING
	print(self.log_info(), 'connect to server ', url)
	var result = socket.connect_to_url(url)
	if result != Error.OK:
		printerr(self.log_info(), 'Failed to connect the server')
		connection_failed.emit('?')
	last_state = WebSocketPeer.STATE_CONNECTING
	set_process(true)

func handle_accept(packet):
	if !check_ack_seq(packet):
		return
	if game_connection_state == GameConnectionState.STATE_CONNECTING_WAIT_FOR_ACK:
		self.id = packet.data.id_
		self.token = packet.data.token
		game_connection_state = GameConnectionState.STATE_ESTABLISHED
		connection_successed.emit(packet.data.game_state)
	elif game_connection_state == GameConnectionState.STATE_ESTABLISHED:
		var request = request_buffer[int(packet.ack_seq)]
		if request.action == 'operate':
			var callback = request_callback[int(request.seq)]
			if request.op_state == 'declare':
				callback.call(true)
			elif request.op_state == 'commit':
				callback.call(true, packet.data.ops)
			else:
				pass # error
		request_buffer.erase(request.seq)
		request_callback.erase(request.seq)

func handle_reject(packet):
	if !check_ack_seq(packet):
		return
	if game_connection_state == GameConnectionState.STATE_CONNECTING_WAIT_FOR_ACK:
		connection_failed.emit(null)
	elif game_connection_state == GameConnectionState.STATE_ESTABLISHED:
		var request = request_buffer[int(packet.ack_seq)]
		if request.action == 'operate':
			var callback = request_callback[int(request.seq)]
			if request.op_state == 'declare':
				callback.call(false)
			elif request.op_state == 'commit':
				callback.call(false, null)
			else:
				pass # error
		request_buffer.erase(request.seq)
		request_callback.erase(request.seq)

func handle_event(packet):
	if game_connection_state == GameConnectionState.STATE_ESTABLISHED:
		if packet.event == 'operate':
			if packet.data.op_state == 'declare':
				event_operate_declared.emit(int(packet.data.id_), packet.data.ops)
			elif packet.data.op_state == 'commit':
				event_operate_commited.emit(int(packet.data.id_), packet.data.ops)
		elif packet.event == 'join':
			event_join.emit(packet.data.username, packet.data.id_)
		elif packet.event == 'quit':
			event_quit.emit(packet.data.id_)

# only invoke this function when the connection opened
func send_join_packet():
	var request = JSON.stringify({
		"action": "join",
		"username": username,
		"id_": id,
		"token": token,
		"seq": seq,
		"room_id_": room_id,
	})
	seq += 1
	send(request)

func send_quit_packet():
	var request = JSON.stringify({
		"action": "quit",
		"id_": id,
		"token": token,
		"seq": seq,
		"room_id_": room_id
	})
	seq += 1
	send(request)

func queue_request(request):
	request_queue.append(request)
	request_buffer[seq] = request
	var old_seq = seq
	seq += 1
	return old_seq

func queue_operate_packet_declare(ops):
	var request = {
		"action": "operate",
		"id_": id,
		"token": token,
		"room_id_": room_id,
		"ops": ops,
		"op_state": "declare",
		"seq": seq
	}
	return queue_request(request)

func queue_operate_packet_commit(ops):
	var request = {
		"action": "operate",
		"id_": id,
		"token": token,
		"room_id_": room_id,
		"ops": ops,
		"op_state": "commit",
		"seq": seq
	}
	return queue_request(request)

func send(request: String):
	print(self.log_info(), 'send: ', request)
	socket.send_text(request)

func dispatch(packet: Dictionary):
	print(self.log_info(), 'recv: ', packet)
	if packet['action'] == 'event':
		handle_event(packet)
	elif packet['action'] == 'accept':
		handle_accept(packet)
	elif packet['action'] == 'reject':
		handle_reject(packet)
	else:
		pass # error

func log_info():
	return '[\"%s\"=%d @%s] ' % [self.username, self.id, Time.get_time_string_from_system()]

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if last_state == WebSocketPeer.STATE_CONNECTING:
			send_join_packet()
			game_connection_state = GameConnectionState.STATE_CONNECTING_WAIT_FOR_ACK
		while socket.get_available_packet_count() > 0:
			var response = JSON.parse_string(socket.get_packet().get_string_from_utf8())
			if response == null:
				continue
			dispatch(response)
		if game_connection_state == GameConnectionState.STATE_ESTABLISHED:
			# send
			if !request_queue.is_empty():
				var request = request_queue.pop_front()
				send(JSON.stringify(request))
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		printerr(self.log_info(), 'Websocket closed with code %d, reason %s. Clean %s' % [code, reason, code != -1])
		if last_state == WebSocketPeer.STATE_CONNECTING:
			connection_failed.emit(code)
		set_process(false)
	last_state = state

func _exit_tree():
	send_quit_packet()
	socket.close()

func _on_start_connection():
	connect_to_server()

func _on_main_scene_square_added(nodes):
	var ops = []
	for node in nodes:
		ops.append({
			"action": "add",
			"component_id_": node.component_id_,
			"op_state": "declare",
			"changed": node.to_dict()
		})
	var seq = queue_operate_packet_commit(ops)
	request_callback[seq] = func (ok, response_ops):
		if !ok:
			cancel_ops.emit(ops)
		else:
			update_id.emit(response_ops)

func _on_main_scene_square_removed(component_id_s):
	var ops = []
	for component_id_ in component_id_s:
		ops.append({
			"action": "remove",
			"component_id_": component_id_,
			"changed": null
		})
	var seq = queue_operate_packet_declare(ops)
	request_callback[seq] = func (ok):
		if !ok:
			cancel_ops.emit(ops)
		else:
			var seq2 = self.queue_operate_packet_commit(ops)
			request_callback[seq2] = func (ok, response_ops):
				if !ok:
					cancel_ops.emit(ops)
				else:
					pass

func _on_main_scene_dragging_node_end(nodes):
	var ops = []
	for node in nodes:
		ops.append({
			"action": "modify",
			"component_id_": node.component_id_,
			"changed": node.to_dict()
		})
	var seq = queue_operate_packet_commit(ops)
	request_callback[seq] = func (ok, response_ops):
		if !ok:
			cancel_ops.emit(ops)
		else:
			pass

func _on_main_scene_dragging_node_start(component_id_s):
	var ops = []
	for component_id_ in component_id_s:
		ops.append({
			"action": "modify",
			"component_id_": component_id_,
			"changed": null
		})
	var seq = queue_operate_packet_declare(ops)
	request_callback[seq] = func (ok):
		if !ok:
			cancel_ops.emit(ops)
