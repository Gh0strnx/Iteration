extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

var _owner_peer_id: int = 1

func _ready() -> void:
	_owner_peer_id = int(str(get_parent().name))
	sync.set_multiplayer_authority(_owner_peer_id)

func _process(_delta: float) -> void:
	if multiplayer.get_unique_id() != _owner_peer_id:
		return

	var aim_dir: Vector2 = get_global_mouse_position() - global_position
	if aim_dir == Vector2.ZERO:
		aim_dir = Vector2.RIGHT

	rotation = aim_dir.angle()

	var deg := wrapf(rad_to_deg(rotation), -180.0, 180.0)
	sprite.flip_v = not (deg > -90.0 and deg < 90.0)
