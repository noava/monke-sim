extends PanelContainer

const Slot = preload("res://inventory/slot.tscn")

@onready var item_grid: HBoxContainer = $MarginContainer/ItemGrid

@onready var hook_controller: HookController = $"../../HookController"
@onready var banana_gun: Node3D = $"../../Head/Camera3D/banana_gun"
@onready var interact_ray: RayCast3D = $"../../Head/Camera3D/Grab Ray"

var equipped_item: SlotData = null
var bananas: int = 42

func populate_item_grid(slot_datas: Array[SlotData]) -> void:
	for child in item_grid.get_children():
		child.queue_free()
		
	for slot_data in slot_datas:
		var slot = Slot.instantiate()
		item_grid.add_child(slot)
		
		if slot_data:
			slot.set_slot_data(slot_data)


func _ready() -> void:	
	var inv_data = preload("res://inventory/player_inv.tres")
	populate_item_grid(inv_data.slot_datas)
	
func _input(_event: InputEvent) -> void:
	if not is_multiplayer_authority(): return

	for number in range(10):
		if Input.is_action_just_pressed("number_%d" % number):
			equip_item(number)
	
	if Input.is_action_just_pressed("interact"):
		try_purchase()

func equip_item(slot_index: int) -> void:
	for i in item_grid.get_child_count():
		var s = item_grid.get_child(i)
		s.get_node("Highlight").visible = false
		
	if slot_index < item_grid.get_child_count():
		var slot = item_grid.get_child(slot_index - 1) as PanelContainer
		slot.get_node("Highlight").visible = true
		
		if slot and slot.has_method("get_slot_data"):
			equipped_item = slot.get_slot_data()
			
			var item_name = equipped_item.item_data.name if equipped_item and equipped_item.item_data else ""

			# Vine Grapple
			hook_controller.is_enabled = (item_name == "Vine Grapple")
			
			# Gun
			var is_gun: bool = item_name == "Gun"
			banana_gun.rpc("set_enabled", is_gun)

			
			# Debugging
			print("Equipped item from slot:", slot_index)
			print("Equipped item:", item_name)

func try_purchase():
	if interact_ray.is_colliding():
		var shop_item = interact_ray.get_collider()
		if shop_item and shop_item.has_method("get_item_price"):
			var price = shop_item.item_price
			var item_id = shop_item.item_id
			
			if bananas >= price:
					bananas -= price
					add_to_hotbar(item_id)

					shop_item.queue_free()
			else:
					# TODO: Show UI message. A console?
					print("Not enough bananas!")

func add_to_hotbar(item_id: String):
	for i in range(item_grid.get_child_count()):
		var slot = item_grid.get_child(i)
		if slot.get_slot_data() == null:
			var new_data = SlotData.new()
			new_data.item_id = item_id
			new_data.item_data = load("res://inventory/items/%s.tres" % item_id)
			slot.set_slot_data(new_data)
			print("Added ", item_id, " to hotbar at slot ", i + 1)
			return
	# TODO: Show UI message. A console?
	print("Hotbar full!")
