extends Control

var ip
var code
var port
var allowcodes = true

var list1 = "ABC"
var list2 = "DEF"
var list3 = "GHI"
var list4 = "JKLMNOPQRSTUVW"
var list5 = "XYZ"

func _ready() -> void:
	lobbyCode()
	deLobbyCode(code)
	print(GameManager.ip)
	print(GameManager.port)
	print(GameManager.lobbyCode)

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
			code = code.replace("192.168", list1[randi() % list1.length()])
		elif ip.begins_with("10."):
			code = code.replace("10.", list2[randi() % list2.length()])
		elif ip.begins_with("172."):
			code = code.replace("172.", list3[randi() % list3.length()])

		if code.contains("."):
			code = code.replace(".", list4[randi() % list4.length()])

		if code.contains("8910"):
			code = code.replace("8910", list5[randi() % list5.length()])
		else:
			return
	else:
		code = ip
	GameManager.lobbyCode = code
	

func deLobbyCode(_code: String) -> void:
	code = _code

	var first = code.left(1)
	if list1.contains(first):
		code = code.replace(first, "192.168")
	elif list2.contains(first):
		code = code.replace(first, "10.")
	elif list3.contains(first):
		code = code.replace(first, "172.")

	for i in list4.length():
		code = code.replace(list4[i], ".")

	for i in list5.length():
		code = code.replace(list5[i], "8910")

	port = int(code.right(4))
	ip = code.left(code.length() - 4)

	GameManager.ip = ip
	GameManager.port = port
