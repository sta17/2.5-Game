extends Player
class_name PlayerCharacter

#region Variables
@export_subgroup("Properties")
@export var movement_speed = 250
@export var jump_strength = 7

## Main [InventoryHandler] node.
@export_node_path("InventoryHandler") var InventoryHandler_path := NodePath("InventoryHandler")
@onready var inventoryHandler := get_node(InventoryHandler_path)
@export_node_path("InventorySystemUI") var InventorySystemUI_path := NodePath("InventorySystemUI")
@onready var inventorySystemUI := get_node(InventorySystemUI_path)
var interactableInv
var interactableInvBody:BoxInventory

#PLAYER NODES
@onready var raycast = $"RayCast or Area 3D/RayCast3D"
@onready var camera = $CameraMount/Camera3D
@onready var player_AnimatedSprite3D:AnimatedSprite3D = $AnimatedSprite3D
@onready var interact_message_position : Control = $"../UI/InteractMessagePosition"
@onready var interact_message : Label = $"../UI/InteractMessagePosition/InteractMessage"
@onready var interact_message_object : Node

#ACTION BOOLS
var mouse_sensitivity = 700
var mouse_captured := true
var display_interact:bool = true
var is_mouse_free:bool = false

#MOVEMENT HANDLING
var movement_velocity: Vector3
var rotation_target: Vector3
var input: Vector3
var input_mouse: Vector2
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var previously_floored := false
var jump_single := true
var jump_double := true

enum WALK_DIRECTION {
	RIGHT,
	LEFT,
	UP,
	DOWN,
	IDLE,
}
var _WALK_DIRECTION_STATE:WALK_DIRECTION = WALK_DIRECTION.IDLE
#endregion

#region Ready and Process
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player_AnimatedSprite3D.play("idle-down")
	raycast.rotation_degrees = Vector3(0, 180 ,0)
	_WALK_DIRECTION_STATE = WALK_DIRECTION.DOWN

func _physics_process(delta):
	interact()

func _process(delta):
	handle_sprites(delta)
	# Handle functions
	handle_controls(delta)
	handle_gravity(delta)
	
	# Movement
	var applied_velocity: Vector3
	
	movement_velocity = transform.basis * movement_velocity # Move forward
	
	applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	applied_velocity.y = -gravity
	
	velocity = applied_velocity
	move_and_slide()
	
	# Rotation
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 1.25, delta * 5)	
	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 25)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)
	
	#container.position = lerp(container.position, container_offset - (applied_velocity / 30), delta * 10)
	
	# Movement sound
	#particles_trail.emitting = false
	#sound_footsteps.stream_paused = true
	
	if is_on_floor():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			#particles_trail.emitting = true
			#sound_footsteps.stream_paused = false
			pass
	
	# Landing after jump or falling
	camera.position.y = lerp(camera.position.y, 0.0, delta * 5)
	
	if is_on_floor() and gravity > 1 and !previously_floored: # Landed
		#Audio.play("assets/audio/land.ogg")
		camera.position.y = -0.1
	
	previously_floored = is_on_floor()
	
# Mouse movement
func _input(event):
	if event is InputEventMouseMotion and mouse_captured:
		
		input_mouse = event.relative / mouse_sensitivity
		
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity
	
func handle_sprites(delta):
	var input_dir = Input.get_vector("move_left","move_right","move_up","move_down")

	if input_dir.y == -1:
		player_AnimatedSprite3D.play("walk-up")
		raycast.rotation_degrees = Vector3(0,0,0)
		_WALK_DIRECTION_STATE = WALK_DIRECTION.UP
	if input_dir.y == 1:
		player_AnimatedSprite3D.play("walk-down")
		raycast.rotation_degrees = Vector3(0, 180 ,0)
		_WALK_DIRECTION_STATE = WALK_DIRECTION.DOWN
	if input_dir.x == 1:
		player_AnimatedSprite3D.play("walk-right")
		raycast.rotation_degrees = Vector3(0, -90,0)
		_WALK_DIRECTION_STATE = WALK_DIRECTION.LEFT
	if input_dir.x == -1:
		player_AnimatedSprite3D.play("walk-left")
		raycast.rotation_degrees = Vector3(0, 90,0)
		_WALK_DIRECTION_STATE = WALK_DIRECTION.RIGHT

	if input_dir.x > 0.5 and input_dir.y < -0.5:
		player_AnimatedSprite3D.play("walk-right")#north east
		raycast.rotation_degrees = Vector3(0, -90,0)
		_WALK_DIRECTION_STATE = WALK_DIRECTION.RIGHT
	if input_dir.x > 0.5 and input_dir.y > 0.5:
		player_AnimatedSprite3D.play("walk-right")#south east
		raycast.rotation_degrees = Vector3(0, -90,0)
		_WALK_DIRECTION_STATE = WALK_DIRECTION.RIGHT
	if input_dir.x < -0.5 and input_dir.y > 0.5:
		player_AnimatedSprite3D.play("walk-left")#south west
		raycast.rotation_degrees = Vector3(0, 90,0)
		_WALK_DIRECTION_STATE = WALK_DIRECTION.LEFT
	if input_dir.x < -0.5 and input_dir.y < -0.5:
		player_AnimatedSprite3D.play("walk-left")#north west
		raycast.rotation_degrees = Vector3(0, 90,0)
		_WALK_DIRECTION_STATE = WALK_DIRECTION.LEFT

	if input_dir.x == 0 and input_dir.y == 0:
		match _WALK_DIRECTION_STATE:
			WALK_DIRECTION.LEFT:
				player_AnimatedSprite3D.play("idle-left")
			WALK_DIRECTION.RIGHT:
				player_AnimatedSprite3D.play("idle-right")
			WALK_DIRECTION.UP:
				player_AnimatedSprite3D.play("idle-up")
			WALK_DIRECTION.DOWN:
				player_AnimatedSprite3D.play("idle-down")

#endregion

#region Controls
func handle_controls(delta):
	
	if Input.is_action_just_pressed("interact"):
		if interactableInv != null:
			open_inventory(interactableInv)
	
	if Input.is_action_just_pressed("toggle_hotbar_next"):
		inventoryHandler.hotbar.next_item()
	if Input.is_action_just_pressed("toggle_hotbar_previous"):
		inventoryHandler.hotbar.previous_item()
	
	# Mouse capture
	if Input.is_action_just_pressed("mouse_capture") and !is_mouse_free:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	
	if Input.is_action_just_pressed("mouse_capture_exit") and !is_mouse_free:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
		
		input_mouse = Vector2.ZERO
	
	# Movement
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_up", "move_down")
	#print(input.x," - ",input.z)
	
	movement_velocity = input.normalized() * movement_speed * delta
	#print(movement_velocity)
	
	# Rotation
	var rotation_input := Vector3.ZERO
	
	rotation_input.y = Input.get_axis("camera_left", "camera_right")
	rotation_input.x = Input.get_axis("camera_up", "camera_down") / 2
	
	rotation_target -= rotation_input.limit_length(1.0) * 5 * delta
	rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))
	
	# Jumping
	if Input.is_action_just_pressed("jump"):
		
		if jump_single or jump_double:
			#Audio.play("assets/audio/jump_a.ogg, assets/audio/jump_b.ogg, assets/audio/jump_c.ogg")
			pass
		
		if jump_double:
			
			gravity = -jump_strength
			jump_double = false
			
		if(jump_single): action_jump()

# Handle gravity
func handle_gravity(delta):
	gravity += 20 * delta
	if gravity > 0 and is_on_floor():
		jump_single = true
		gravity = 0

# Jumping
func action_jump():
	gravity = -jump_strength
	jump_single = false;
	jump_double = true;
#endregion

#region Item Handling
func allowUI(status:bool):
	if status:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#is_weapons_disabled = true
		mouse_captured = false
		is_mouse_free = true
		display_interact = false
		interact_message.visible = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		#is_weapons_disabled = false
		mouse_captured = true
		is_mouse_free = false
		display_interact = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is PickUpItem:
		if body.autoCollect:
			body.Collect(self)
	if body is BoxInventory:
		interactableInv = body.get_inventory()
		interactableInvBody = body

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is BoxInventory and body == interactableInvBody:
		interactableInvBody = null
		interactableInv = null
	if body == interact_message_object:
		interact_message_status_off(false)

func _on_inventory_system_ui_opened_inventory_ui(opened) -> void:
	allowUI(opened)

func open_inventory(inventory : Inventory):
	if not inventoryHandler.is_open(inventory):
		inventoryHandler.open(inventory)
		inventorySystemUI.open_inventory()
	else:
		inventorySystemUI.open_inventory()

func interact():
	if raycast.is_colliding():
		var object = raycast.get_collider()
		var node = object as Node
		var box := node as BoxInventory
		if box != null:
			var inv = box.get_inventory()
			if inv != null:
				if display_interact:
					interact_message.visible = !inventoryHandler.is_open(inv)
				interact_message_status_on("E to Open Inventory",object)
				if interactableInv != inv:
					if Input.is_action_just_pressed("interact"):
						open_inventory(inv)
				return
		var dropped_item := node as PickUpItem
		if dropped_item != null:
			if dropped_item.is_pickable:
				interact_message_status_on("E to Pickup",object)
				if Input.is_action_just_pressed("interact"):
					dropped_item.Collect(self)
				return
		interact_message_status_off(false)

func interact_message_status_off(status:bool):
	interact_message.visible = status
	
func interact_message_status_on(message:String,object:Node3D):
	interact_message.visible = true
	interact_message.text = message
	interact_message_position.position = camera.unproject_position(object.position)
	interact_message_object = object
#endregion
