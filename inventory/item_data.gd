extends Resource
class_name ItemData

@export var name: String = ""
@export var texture: Texture2D
@export var damage: float
enum ItemType { NONE, GUN, FOOD, OTHER }
@export var item_type: ItemType = ItemType.NONE
