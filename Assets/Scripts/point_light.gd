extends PointLight2D
@onready var bullet_body: Node2D = get_parent() as Node2D
@export var waitTimeMult = 1
@export var light_intensity = 0.0
@export var max_intensity = 0.9
@export var fade_speed = 4.5

var ready_to_check = false

func _ready() -> void:
	hide()
	light_intensity = 0.0
	energy = 0.0
	await get_tree().process_frame
	await get_tree().process_frame  # two frames to be safe
	ready_to_check = true

func _physics_process(_delta: float) -> void:
	if not ready_to_check:
		return
	if GameManager.localPlayer == null or bullet_body == null:
		visible = false
		return
		
	var from: Vector2 = GameManager.localPlayer.global_position
	var to: Vector2 = bullet_body.global_position
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.exclude = [GameManager.localPlayer]

	var result: Dictionary = space_state.intersect_ray(params)
	if result.is_empty():
		visible = false
		light_intensity = 0.0
		energy = 0.0
	else:
		var col: Node = result["collider"] as Node
		if col == bullet_body or col.is_in_group("bullet"):
			visible = false
			light_intensity = 0.0
			energy = 0.0
		else:
			visible = true
			if light_intensity < max_intensity:
				light_intensity += fade_speed * _delta
				energy = light_intensity
