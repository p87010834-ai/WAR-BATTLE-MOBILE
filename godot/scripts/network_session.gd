extends Node
class_name WbmNetworkSession

signal connection_status_changed(connected: bool, message: String)
signal player_count_changed(count: int)

const DEFAULT_PORT := 24560
const MAX_CLIENTS := 10
var is_host := false
var connected := false
var connecting := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT, max_clients: int = MAX_CLIENTS) -> Error:
	leave_session()
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(port, clampi(max_clients, 1, MAX_CLIENTS))
	if result != OK:
		connection_status_changed.emit(false, "Не удалось запустить сервер: %s" % error_string(result))
		return result
	multiplayer.multiplayer_peer = peer
	is_host = true
	connected = true
	connection_status_changed.emit(true, "Локальный сервер создан")
	player_count_changed.emit(1)
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	leave_session()
	if address.strip_edges().is_empty():
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(address.strip_edges(), port)
	if result != OK:
		connection_status_changed.emit(false, "Не удалось подключиться: %s" % error_string(result))
		return result
	multiplayer.multiplayer_peer = peer
	is_host = false
	connected = false
	connecting = true
	connection_status_changed.emit(false, "Подключение к серверу...")
	return OK

func leave_session() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_host = false
	connected = false
	connecting = false

func _on_peer_connected(_id: int) -> void:
	player_count_changed.emit(multiplayer.get_peers().size() + 1)

func _on_peer_disconnected(_id: int) -> void:
	player_count_changed.emit(multiplayer.get_peers().size() + 1)

func _on_connected() -> void:
	connecting = false
	connected = true
	connection_status_changed.emit(true, "Подключено к серверу")

func _on_connection_failed() -> void:
	connecting = false
	connected = false
	connection_status_changed.emit(false, "Соединение не установлено")

func _on_server_disconnected() -> void:
	connecting = false
	connected = false
	connection_status_changed.emit(false, "Соединение с сервером потеряно")
