extends Skeleton3D

@export_range(0.0, 1.0) var physics_interpolation: float = 0.5
@export var physics_skeleton: Skeleton3D
@export var animated_skeleton: Skeleton3D

@onready var sim: PhysicalBoneSimulator3D = physics_skeleton.get_node("PhysicalBoneSimulator3D")
# name as ID???
var physicalBone3D_by_name: Dictionary = {} # bone_id -> PhysicalBone3D
var pb3d_joint_transform: Dictionary = {}   # bone_name -> Transform3D ( = inverse(M) )
										  # 把 PhysicalBone3D 的 transform 转成“关节坐标系”
var physics_bones

func _ready() -> void:
	
	# build physics map: bone name -> PhysicalBone3D
	for c in sim.get_children():
		if c is PhysicalBone3D:
			var pb3d := c as PhysicalBone3D
			# var physics_bone_id := pb3d.get_bone_id()
			var bone_name := physics_skeleton.get_bone_name(pb3d.get_bone_id())
			physicalBone3D_by_name[bone_name] = pb3d

func _physics_process(delta: float) -> void:
	var inv_world := global_transform.affine_inverse()
	for bone_index: int in get_bone_count():
		var bone_name = get_bone_name(bone_index)
		# pre-set the animated_transform to be animated skeleton's current bone's ORIGINAL, DEFAULT transform
		var animated_transform: Transform3D = animated_skeleton.global_transform \
			 * animated_skeleton.get_bone_global_pose(bone_index)
		# If the current bone (in physics skeleton) not among the pb dictionary's keys (没物理骨头的就用animation骨头的transform)
		var physics_transform: Transform3D = animated_transform # physics_skeleton.global_transform * physics_skeleton.get_bone_global_pose(bone_index)
		# else, apply the physicalBone's transform to the current bone (in physics skeleton)
		if physicalBone3D_by_name.has(bone_name):
			var pb := physicalBone3D_by_name[bone_name] as PhysicalBone3D
			var body_offset : Transform3D = pb.body_offset
			physics_transform = (physicalBone3D_by_name[bone_name] as PhysicalBone3D).global_transform * body_offset.affine_inverse() # physics_skeleton.global_transform * physics_skeleton.get_bone_global_pose(bone_index)
		
		var blended_w := animated_transform.interpolate_with(physics_transform, physics_interpolation)
		# set override expects skeleton-space; convert from world:
		var blended_skel_space := global_transform.affine_inverse() * blended_w
		set_bone_global_pose(bone_index, blended_skel_space)

# On a Skeleton3D, FORMERLY: Dictonary: idx -> bone_name
func bone_names(skeleton: Skeleton3D) -> PackedStringArray:
	var names := PackedStringArray()
	for i in skeleton.get_bone_count(): # 0 .. count-1
		names.append(skeleton.get_bone_name(i))
	return names
	
# 计算骨头的全局rest关节点坐标（Skeleton空间沿父链累乘）
func _bone_global_rest(skel: Skeleton3D, id: int) -> Transform3D:
	var t := skel.get_bone_rest(id)
	var p := skel.get_bone_parent(id)
	while p != -1:
		t = skel.get_bone_rest(p) * t
		p = skel.get_bone_parent(p)
	return t
	
"""
In _ready:
	physics_bones <- all children who is a PhysicalBone3D under physics_skeleton
	
In _profess:
	do nothing
	
In _physics_process:
	for bone count:
		animated_transform transform3D global*bone_global_pose
		physics_transform transform3D global*bone_global_pose
		
		set_bone_global_pose_override(i, global_transform.affine_inverse() * animated_transform.interpolate_with(physics_transform, physics_interpolation), 1.0, true)
"""
