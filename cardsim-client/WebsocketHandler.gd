extends Node

var socket = WebSocketPeer.new()
var url = "ws://localhost:8765"
var last_state = WebSocketPeer.STATE_CLOSED

var username = "username"
var id = 0
var token = 0
var room_id = 0

signal connection_failed(error: Error)
signal connection_successed()

func connect_to_server():
	print('connect to server ', url)
	var result = socket.connect_to_url(url)
	if result != Error.OK:
		printerr('Failed to connect the server')
		connection_failed.emit('?')
	last_state = WebSocketPeer.STATE_CONNECTING
	set_process(true)

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
			connection_successed.emit()
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
