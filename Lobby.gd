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
			
			
	if allowcodes:
		code = ip
		ip = " "+ip
		if ip.begins_with("192.168"):
			code = ip.replace(" 192.168", "a")
		elif ip.begins_with("10."):
			code = ip.replace(" 10.", "b")
		elif ip.begins_with("172."):
			code = ip.replace(" 172. ", "c")
		print(code)
		print(ip)
	else:
		code = ip
		
