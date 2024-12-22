class_name NetworkManager
extends Node

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal message_received(peer_id: int, message: Dictionary)
signal typing_stats_received(peer_id: int, stats: Dictionary)
signal duel_request_received(peer_id: int)
signal duel_accepted(peer_id: int)
signal duel_rejected(peer_id: int)

const DEFAULT_PORT = 7000
var peer: ENetMultiplayerPeer
var active_peers: Dictionary = {}
var current_duel_peer: int = 0

func host_game(port: int = DEFAULT_PORT) -> Error:
    peer = ENetMultiplayerPeer.new()
    var error = peer.create_server(port)
    if error == OK:
        multiplayer.multiplayer_peer = peer
        print("Server started on port ", port)
    return error

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
    peer = ENetMultiplayerPeer.new()
    var error = peer.create_client(address, port)
    if error == OK:
        multiplayer.multiplayer_peer = peer
        print("Connected to ", address, ":", port)
    return error

func disconnect_from_game():
    if peer:
        peer.close()
        active_peers.clear()
        current_duel_peer = 0

func send_typing_stats(stats: Dictionary):
    if current_duel_peer != 0:
        rpc_id(current_duel_peer, "receive_typing_stats", stats)

func send_duel_request(peer_id: int):
    if peer_id in active_peers:
        rpc_id(peer_id, "receive_duel_request", multiplayer.get_unique_id())

func accept_duel(peer_id: int):
    if peer_id in active_peers:
        current_duel_peer = peer_id
        rpc_id(peer_id, "duel_accepted_rpc", multiplayer.get_unique_id())

func reject_duel(peer_id: int):
    if peer_id in active_peers:
        rpc_id(peer_id, "duel_rejected_rpc", multiplayer.get_unique_id())

@rpc
func receive_typing_stats(stats: Dictionary):
    var sender_id = multiplayer.get_remote_sender_id()
    if sender_id == current_duel_peer:
        emit_signal("typing_stats_received", sender_id, stats)

@rpc
func receive_duel_request(peer_id: int):
    emit_signal("duel_request_received", peer_id)

@rpc
func duel_accepted_rpc(peer_id: int):
    current_duel_peer = peer_id
    emit_signal("duel_accepted", peer_id)

@rpc
func duel_rejected_rpc(peer_id: int):
    emit_signal("duel_rejected", peer_id)

@rpc("any_peer", "reliable")
func receive_message(message: Dictionary) -> void:
    var sender_id = multiplayer.get_remote_sender_id()
    emit_signal("message_received", sender_id, message)

func send_message(peer_id: int, message: Dictionary) -> void:
    if peer_id in active_peers:
        rpc_id(peer_id, "receive_message", message)

func broadcast_message(message: Dictionary) -> void:
    for peer_id in active_peers:
        if peer_id != multiplayer.get_unique_id():
            send_message(peer_id, message)

func _ready():
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int):
    active_peers[id] = {
        "name": "Player " + str(id),
        "stats": {}
    }
    print("Peer connected: ", id)
    emit_signal("peer_connected", id)

func _on_peer_disconnected(id: int):
    if id in active_peers:
        active_peers.erase(id)
    if current_duel_peer == id:
        current_duel_peer = 0
    print("Peer disconnected: ", id)
    emit_signal("peer_disconnected", id) 
