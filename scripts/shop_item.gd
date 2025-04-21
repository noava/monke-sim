extends Node3D

@export var item_id: String:
	get = get_item_id
	
@export var item_price: int:
	get = get_item_price
	

func _ready() -> void:
	# Checks if the item exists in the items list
	var path = "res://inventory/items/%s.tres" % item_id
	if not ResourceLoader.exists(path):
		push_error("Item ID '%s' does not exist at path: %s" % [item_id, path])
		queue_free()
		return
		
func get_item_id():
	return item_id
	
func get_item_price():
	return item_price
	
