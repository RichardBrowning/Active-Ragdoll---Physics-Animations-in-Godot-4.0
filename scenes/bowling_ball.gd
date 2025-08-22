extends RigidBody3D

func fire(force: float):
	# -Z is the model’s forward in Godot
	apply_central_impulse(-global_transform.basis.z * force)
