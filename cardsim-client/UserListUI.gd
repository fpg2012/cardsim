extends Node2D

@onready
var item_list = $MarginContainer/VBoxContainer/ItemList
var user_list = []

func user_to_string(user: Dictionary):
	return '%s' % [user.username]

func add_user(user: Dictionary):
	user_list.append(user)
	item_list.add_item(user_to_string(user))

func remove_user(user_id_: int):
	var index = 0
	for i in range(user_list.size()):
		if int(user_list[i].id_) == user_id_:
			index = i
			break
	user_list.remove_at(index)
	item_list.remove_item(index)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
