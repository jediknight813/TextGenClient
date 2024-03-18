extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed = 4.0
var jump_speed = 6.0 
var mouse_sensitivity = 0.002  
var health = 10
@onready var camera = $Camera3D


func _enter_tree():
	print(name.to_int())
	set_multiplayer_authority(name.to_int())


func take_damage(amount):
	if is_multiplayer_authority():
		health -= amount
		$Hud/TextureProgressBar.value -= amount


func _ready():
	if is_multiplayer_authority():
		self.position = $"../SpawnPostion".position
		$Hud/TextureProgressBar.value = health
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = is_multiplayer_authority()

func _physics_process(delta):
	if is_multiplayer_authority():
		velocity.y += -gravity * delta
		get_input()
		move_and_slide()
	
func get_input():
	if is_multiplayer_authority():
		var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var movement_dir = transform.basis * Vector3(input.x, 0, input.y)
		velocity.x = movement_dir.x * speed
		velocity.z = movement_dir.z * speed
	
	
func _unhandled_input(event):
	if is_multiplayer_authority():
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * mouse_sensitivity)
		
		if event.is_action_pressed("jump"):
			velocity.y = jump_speed
		
		if event.is_action_pressed("esc") and is_on_floor():
			$"../".exit_game(name.to_int())
			get_tree().quit()

