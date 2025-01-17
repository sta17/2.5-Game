@icon("res://assets/Icons/pixel-boy/node_3D/icon_money_bag.png")
extends Node3D
class_name BoxInventory

## The name of the inventory, to be displayed in UI
@export var inventory_name := "Inventory"
## Array of [Slot] that stores items and their quantities
## The slot uses [b]"item"[/b] to store item id information
## and [b]"amount"[/b] for your quantity
@export var slots : Array[Slot]
## Sets the initial amount of slots in the inventory in the [code]_ready[/code] function
@export var slot_amount := 16
## Creates a slot when use  [code]add[/code]  for adding item to inventory when it is full
@export var create_missing_slots := true
@export var recreate_slots_on_ready := true

func _ready():
	$Inventory.inventory_name = inventory_name
	$Inventory.slots = slots
	$Inventory.slot_amount = slot_amount
	$Inventory.create_missing_slots = create_missing_slots
	$Inventory.recreate_slots_on_ready = recreate_slots_on_ready
	$Inventory._ready()

func get_inventory() -> Inventory:
	return $Inventory

func set_Label_Text(text:String):
	$Inventory.inventory_name = text

func _on_inventory_closed():
	_on_close()

func _on_inventory_opened():
	_on_open()


func _on_open():
	#$box.visible = false
	$box.visible = false
	$boxOpen.visible = true
	#Audio.play("res://assets/audio/coin.ogg") # Play sound
	#$Open.play()


func _on_close():
	#$box.visible = true
	$boxOpen.visible = false
	$box.visible = true
	#Audio.play("res://assets/audio/coin.ogg") # Play sound
	#$Close.play()
