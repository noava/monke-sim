extends PanelContainer

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect

var slot_data: SlotData = null  # Store the slot data

@onready var highlight: Panel = $Highlight

func _ready() -> void:
	highlight.visible = false

func set_slot_data(new_slot_data: SlotData) -> void:
	slot_data = new_slot_data  # Save the slot data
	
	var item_data = slot_data.item_data
	texture_rect.texture = item_data.texture
	tooltip_text = item_data.name

	
func get_slot_data() -> SlotData:
	return slot_data
