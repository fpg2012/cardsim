extends Node

enum GameConnectionState {
	STATE_CONNECTING = 0,
	STATE_ESTABLISHED = 1,
	STATE_WAIT_FOR_ACK = 2,
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
var ack_seq = 0

signal connection_failed(error: Error)
signal connection_successed()

func connect_to_server():
	game_connection_state = GameConnectionState.STATE_CONNECTING
	print('connect to server ', url)
	var result = socket.connect_to_url(url)
	if result != Error.OK:
		printerr('Failed to connect the server')
		connection_failed.emit('?')
	last_state = WebSocketPeer.STATE_CONNECTING
	set_process(true)

func handle_accept(packet):
	if packet['ack_seq'] != self.seq:
		printerr('ack_seq(%d) != seq(%d):' % [packet['ack_seq'], self.seq])
		return
	seq += 1
	if game_connection_state == GameConnectionState.STATE_CONNECTING_WAIT_FOR_ACK:
		self.id = packet.data.id_
		self.token = packet.data.token
		connection_successed.emit()
	elif game_connection_state == GameConnectionState.STATE_WAIT_FOR_ACK:
		pass

func handle_event(packet):
	if game_connection_state == GameConnectionState.STATE_ESTABLISHED \
	 || game_connection_state == GameConnectionState.STATE_WAIT_FOR_ACK:
		pass

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
	send(request)

func send(request: String):
	socket.send_text(request)

func dispatch(packet: Dictionary):
	print(packet)
	if packet['action'] == 'event':
		handle_event(packet)
	elif packet['action'] == 'accept':
		handle_accept(packet)

func _on_start_connection():
	connect_to_server()

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
		while socket.get_available_packet_count():
			var response = JSON.parse_string(socket.get_packet().get_string_from_utf8())
			if response == null:
				continue
			dispatch(response)
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print('Websocket closed with code %d, reason %s. Clean %s' % [code, reason, code != -1])
		if last_state == WebSocketPeer.STATE_CONNECTING:
			connection_failed.emit(code)
		set_process(false)
	last_state = state
