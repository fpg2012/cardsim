extends Node2D

var color = Color.WHITE
var color_selected = Color.BEIGE
var color_freezed = Color(Color.CORNFLOWER_BLUE, 0.5)
var square_width = 30
var square_height = 30
const RESIZE_THRESH = 3
var selected = false
var component_id_ = 0
var freezed = false
var dragging = false

func setup(pos: Vector2, wh: Vector2, color: Color = Color.WHITE, color_selected: Color = Color.BEIGE):
	self.position = pos
	self.square_width = wh[0]
	self.square_height = wh[1]
	self.color = color
	self.color_selected = color_selected;
	self.component_id_ = hash(Time.get_ticks_msec()) # temporal id, MUST be replaced by server assigned id later
	return self

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	draw_rect(Rect2(0, 0, square_width, square_width), self.color)
	if selected:
		draw_rect(Rect2(0, 0, square_width, square_width), self.color_selected, false, 3)
	if freezed:
		draw_rect(Rect2(0, 0, square_width, square_width), self.color_freezed, true)

func set_selected(sel: bool):
	self.selected = sel
	if sel:
		z_index = 10
	else:
		z_index = 0
	queue_redraw()

func set_freeze(fr: bool):
	self.freezed = fr
	queue_redraw()

func set_dragging(dr: bool):
	self.dragging = dr

func hovered(event_position: Vector2):
	var x = event_position[0] - floor(event_position[0] / square_width) * square_width
	var y = event_position[1] - floor(event_position[1] / square_height) * square_height
	if !selected:
		return 0
	var flag = 0
	if absf(x - 0) < RESIZE_THRESH:
		flag |= 1
	if absf(x - square_width) < RESIZE_THRESH:
		flag |= 2
	if absf(y - 0) < RESIZE_THRESH:
		flag |= 4
	if absf(y - square_height) < RESIZE_THRESH:
		flag |= 8
	return flag

func from_dict(model):
	self.component_id_ = int(model.component_id_)
	self.position = Vector2(model.pos.x, model.pos.y)
	self.z_index = model.pos.z
	self.rotation = rotation
	self.color = Color(model.color.r, model.color.g, model.color.b)
	return self

func to_dict():
	return {
		"extends": "Square",
		"component_id_": self.component_id_,
		"pos": {
			"x": self.position.x,
			"y": self.position.y,
			"z": self.z_index,
		},
		"rotation": self.rotation,
		"color": {
			"r": self.color.r,
			"g": self.color.g,
			"b": self.color.b,
		}
	}
