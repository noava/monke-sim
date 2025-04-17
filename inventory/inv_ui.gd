extends PanelContainer

const Slot = preload("res://inventory/slot.tscn")

@onready var item_grid: HBoxContainer = $MarginContainer/ItemGrid

@onready var hook_controller: HookController = $"../../HookController"
@onready var banana_gun: Node3D = $"../../Head/Camera3D/banana_gun"

var equipped_item: SlotData = null


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
	for number in range(10):
		if Input.is_action_just_pressed("number_%d" % number):
			equip_item(number)

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
