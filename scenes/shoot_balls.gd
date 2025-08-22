extends Camera3D

@export var bullet_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("fire"):
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_length = 100
		var from = project_ray_origin(mouse_pos)
		var to = from + project_ray_normal(mouse_pos) * ray_length
		
		var bullet = bullet_scene.instantiate() as RigidBody3D
		# Add to the scene (not as a child of the camera) and place/orient in world space
		get_tree().current_scene.add_child(bullet)
		bullet.top_level = true
		bullet.look_at_from_position(from, to, Vector3.UP)  # sets both position and rotation
		bullet.fire(10.0)         
