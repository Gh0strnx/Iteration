extends PointLight2D

@onready var player: Node2D = get_tree().get_first_node_in_group("Player") as Node2D
@onready var bullet_body: Node2D = get_parent() as Node2D
@export var waitTimeMult = 1

func _ready() -> void:
	hide()



func _physics_process(_delta: float) -> void:
	# Safety: if something is missing, keep the light on
	if player == null or bullet_body == null:
		visible = true
		return

	var from: Vector2 = player.global_position
	var to: Vector2 = bullet_body.global_position

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.exclude = [player]  # ignore the player itself

	var result: Dictionary = space_state.intersect_ray(params)

	if result.is_empty():
		# Nothing between player and bullet → directly visible → hide light
		visible = false
	else:
		var col: Node = result["collider"] as Node
		if col == bullet_body or col.is_in_group("bullet"):
			# First thing hit is the bullet → still directly visible
			visible = false
		else:
			# First thing hit is NOT the bullet (wall, obstacle, etc.) → in shadow
			visible = true
			await get_tree().create_timer(0.15*waitTimeMult).timeout
			energy = 0.6
