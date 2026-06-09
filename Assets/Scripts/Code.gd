extends Control

var ip
var code
var port
var allowcodes = true

var list1 = "ABC"
var list2 = "DEF"
var list3 = "GHJ"
var list4 = "KMNPQRTUVW"
var list5 = "XYZ"

func _ready() -> void:
	
	print(GameManager.ip)
	print(GameManager.port)
	print(GameManager.lobbyCode)

func _process(_delta: float) -> void:
	pass
	
func lobbyCode():
	for _address in IP.get_local_addresses():
		if _address.begins_with("192.168") or _address.begins_with("10.") or _address.begins_with("172."):
			ip = _address
			print(ip)
	
	if ip == null:
		return
	if allowcodes:
		code = ip + str(GameManager.port)
		if ip.begins_with("192.168"):
			code = code.replace("192.168", list1.substr(randi() % list1.length(), 1))
		elif ip.begins_with("10."):
			code = code.replace("10.", list2.substr(randi() % list2.length(), 1))
		elif ip.begins_with("172."):
			code = code.replace("172.", list3.substr(randi() % list3.length(), 1))
		if code.contains("."):
			code = code.replace(".", list4.substr(randi() % list4.length(), 1))
		if code.contains("8910"):
			code = code.replace("8910", list5.substr(randi() % list5.length(), 1))
		else:
			return
	else:
		code = ip
	GameManager.lobbyCode = code
	print("Encoded code: ", code)
	

func deLobbyCode(_code: String) -> void:
	if allowcodes == true:
		code = _code
		print("RAW CODE INPUT: ", code)
		var first = code.left(1)
		print("FIRST CHAR: ", first)
		print("list1: ", list1, " contains: ", list1.contains(first))
		print("list2: ", list2, " contains: ", list2.contains(first))
		print("list3: ", list3, " contains: ", list3.contains(first))
		if list1.contains(first):
			code = code.replace(first, "192.168")
		elif list2.contains(first):
			code = code.replace(first, "10.")
		elif list3.contains(first):
			code = code.replace(first, "172.")
		print("AFTER PREFIX DECODE: ", code)
		for i in list4.length():
			code = code.replace(list4.substr(i, 1), ".")
		print("AFTER DOT DECODE: ", code)
		for i in list5.length():
			code = code.replace(list5.substr(i, 1), "8910")
		print("AFTER PORT DECODE: ", code)
		print("RIGHT(4): ", code.right(4))
		print("LEFT(len-4): ", code.left(code.length() - 4))
		port = int(code.right(4))
		ip = code.left(code.length() - 4)
		GameManager.ip = ip
		GameManager.port = port
		print("FINAL - IP: '", ip, "' Port: ", port)
	else:
		GameManager.ip = _code
		port = GameManager.port

func _on_host_button_down() -> void:
		
		lobbyCode()
		$"/root/Control/HostScreen/CODE".text = str(GameManager.lobbyCode)
		
		

func _on_join_button_down() -> void:
	get_tree().get_first_node_in_group("MultiplayerController").playAudio()
	$"/root/Control/JoinScreen/ERRORS".hide()
	deLobbyCode($"/root/Control/JoinScreen/CODE".text.to_upper())
	print("Decoded - IP: ", GameManager.ip, " Port: ", GameManager.port)
	
	if GameManager.ip == null or GameManager.ip == "":
		print("ERROR: IP is null after decode!")
		return
	
	await get_tree().process_frame
	var mp_controller = get_tree().get_first_node_in_group("MultiplayerController")
	mp_controller.join_with_ip(GameManager.ip, GameManager.port)
	


func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		allowcodes = false
		print("toggled on")
		
	else:
		allowcodes = true
		
