extends PanelContainer

const Slot = preload("res://inventory/slot.tscn")

@onready var item_grid: HBoxContainer = $MarginContainer/ItemGrid

@onready var hook_controller: HookController = $"../../HookController"
@onready var weapons_holder: Node3D = $"../../player_model/rig/Skeleton3D/BoneAttachment3D/WeaponsHolder"
@onready var interact_ray: RayCast3D = $"../../Head/Camera3D/Grab Ray"
@onready var banana_count: Label = $"../BananaUI/BananaCount"
@onready var player: CharacterBody3D = $"../.."

var equipped_item: SlotData = null
var bananas: int = 0:
	get:
		return bananas
	set(value):
		bananas = value
		print(bananas)
		banana_count.text = str(bananas).pad_zeros(5)
		
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
	
	# Updates the banana count in UI
	bananas = bananas
	
	if is_multiplayer_authority():
		$"..".show()
	else:
		$"..".hide()
	
func _input(_event: InputEvent) -> void:
	if not is_multiplayer_authority(): return

	for number in range(10):
		if Input.is_action_just_pressed("number_%d" % number):
			equip_item(number)
	
	if Input.is_action_just_pressed("interact"):
		interact_item()

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
			var item_data = equipped_item.item_data if equipped_item and equipped_item.item_data else null
			
			# Hold Item Pose
			var is_holdingitem: bool = item_name != ""
			player.rpc("set_holditem_enabled", is_holdingitem)
			
			# Vine Grapple
			var is_grapple: bool = item_name == "Vine Grapple"
			hook_controller.is_enabled = is_grapple
			%vine_grapple.rpc("set_enabled", is_grapple)
			
			# Gun
			var is_gun: bool = item_data and item_data.item_type == ItemData.ItemType.GUN
			weapons_holder.rpc("set_enabled", is_gun)
			if is_gun:
				weapons_holder.set_item_data(item_data)
			
			# Debugging
			print("Equipped item from slot:", slot_index)
			print("Equipped item:", item_name)

func interact_item():
	if interact_ray.is_colliding():
		var item = interact_ray.get_collider()
		
		# Buy item
		if item and item.has_method("get_item_price"):
			var price = item.item_price
			var item_id = item.item_id
			
			if bananas >= price:
					bananas -= price
					add_to_hotbar(item_id)
					item.queue_free()
			else:
					# TODO: Show UI message. A console?
					print("Not enough bananas!")
		
		# Give Money
		if item and item.has_method("get_banana_value"):
			var banana_value = item.banana_value
			
			bananas += banana_value
			item.queue_free()


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
