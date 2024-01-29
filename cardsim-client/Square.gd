extends Node2D

var color = Color.WHITE
var color_selected = Color.BEIGE
var square_width = 30
var square_height = 30
const RESIZE_THRESH = 3
var selected = false

func setup(pos: Vector2, wh: Vector2, color: Color = Color.WHITE, color_selected: Color = Color.BEIGE):
	self.position = pos
	self.square_width = wh[0]
	self.square_height = wh[1]
	self.color = color
	self.color_selected = color_selected;
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

func set_selected(sel: bool):
	self.selected = sel
	if sel:
		z_index = 10
	else:
		z_index = 0
	queue_redraw()

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
