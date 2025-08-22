extends Skeleton3D

@export var target_skeleton: Skeleton3D
@onready var sim: PhysicalBoneSimulator3D = $PhysicalBoneSimulator3D
var physics_bones: Array[PhysicalBone3D]

@export var linear_spring_stiffness: float = 1200.0
@export var linear_spring_damping: float = 40.0
@export var max_linear_force: float = 9999.0

@export var angular_spring_stiffness: float = 4000.0
@export var angular_spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0

func _ready() -> void:
	sim.physical_bones_start_simulation()
	physics_bones = []
	for c in sim.get_children():
		if c is PhysicalBone3D:
			physics_bones.append(c)

func _physics_process(delta: float) -> void:
	for b in physics_bones:
		var id := b.get_bone_id()
		
		# target (world) 目标变换
		# 目标骨骼（animation动画骨骼）的全局transform * 目前骨头的全局transform
		var target_transform: Transform3D = target_skeleton.global_transform * target_skeleton.get_bone_global_pose(id)
		# current (world) 当前骨骼变换 — 用4.4版本的 physical body transform
		var current_transform: Transform3D = b.global_transform
		# linear PD 线性
		# PD = Proportional–Derivative（比例-微分）
		# P（比例）项：按当前位置/姿态与目标的误差成比例施加力或力矩。系数 k_p。
		# D（微分）项：按误差的变化率（线性用速度、角度用角速度）施加“阻尼”。系数 k_d，主要用来抑制抖动与过冲。
		var position_error: Vector3 = target_transform.origin - current_transform.origin
		# 如果太远了，snap back
		if position_error.length_squared() > 1.0:
			b.global_position = target_transform.origin
		# 否则施以一个力让他回去
		else:
			var force := (linear_spring_stiffness * position_error) - (linear_spring_damping * b.linear_velocity)
			b.linear_velocity += force.limit_length(max_linear_force) * delta
		# angular PD (Euler ok if angles small; quats are safer if you like)
		# 
		var rotation_error: Basis = target_transform.basis * current_transform.basis.inverse()
		var torque := (angular_spring_stiffness * rotation_error.get_euler()) - (angular_spring_damping * b.angular_velocity)
		b.angular_velocity += torque.limit_length(max_angular_force) * delta
