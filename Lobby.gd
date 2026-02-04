extends Control
var ip
var code
var allowcodes = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lobbyCode()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func lobbyCode():
	for _address in IP.get_local_addresses():
		if _address.begins_with("192.168") or _address.begins_with("10.") or _address.begins_with("172."):
			ip = _address

	if ip == null:
		return

	if allowcodes:
		code = ip + str(GameManager.port)

		if ip.begins_with("192.168"):
			code = code.replace("192.168", "a")
		elif ip.begins_with("10."):
			code = code.replace("10.", "b")
		elif ip.begins_with("172."):
			code = code.replace("172.", "c")
		
		if code.contains("8910"):
			code = code.replace("8910", "A")
		else:
			return

		print(code)
		print(ip)
	else:
		code = ip

		
