extends Node2D

var offset = Vector2(0, 0)
var grid_size = 30
var line_width = 1
var line_color = Color(1, 1, 1, 0.1)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()

func _draw():
	var w = get_viewport_rect().size[0]
	var h = get_viewport_rect().size[1]
	var real_offset_w = offset[0] - int(offset[0] / grid_size) * grid_size
	var real_offset_h = offset[1] - int(offset[1] / grid_size) * grid_size
	var num_grids_w = int(w / grid_size) + 2
	var num_grids_h = int(h / grid_size) + 2
	
	for i in range(num_grids_w):
		var f = Vector2(real_offset_w + i * grid_size, 0)
		var t = Vector2(real_offset_w + i * grid_size, h)
		draw_line(f, t, line_color, line_width, true)
	for i in range(num_grids_h):
		var f = Vector2(0, real_offset_h + i * grid_size)
		var t = Vector2(w, real_offset_h + i * grid_size)
		draw_line(f, t, line_color, line_width, true)
