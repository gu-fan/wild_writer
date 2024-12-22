class_name DuelUI
extends Control

signal duel_started(peer_id: int)
signal duel_ended(peer_id: int)

@onready var peer_list: ItemList = $PeerList
@onready var stats_container: VBoxContainer = $StatsContainer
@onready var duel_request_dialog: AcceptDialog = $DuelRequestDialog

var editor_core: EditorCore

func _ready():
    editor_core.network_manager.peer_connected.connect(_on_peer_connected)
    editor_core.network_manager.peer_disconnected.connect(_on_peer_disconnected)
    editor_core.network_manager.typing_stats_received.connect(_on_typing_stats_received)
    editor_core.network_manager.duel_request_received.connect(_on_duel_request_received)
    editor_core.network_manager.duel_accepted.connect(_on_duel_accepted)
    editor_core.network_manager.duel_rejected.connect(_on_duel_rejected)

func _on_peer_connected(peer_id: int):
    var idx = peer_list.add_item("Player " + str(peer_id))
    peer_list.set_item_metadata(idx, peer_id)

func _on_peer_disconnected(peer_id: int):
    for i in peer_list.item_count:
        if peer_list.get_item_metadata(i) == peer_id:
            peer_list.remove_item(i)
            break

func _on_typing_stats_received(peer_id: int, stats: Dictionary):
    update_opponent_stats(stats)

func _on_duel_request_received(peer_id: int):
    duel_request_dialog.dialog_text = "Player " + str(peer_id) + " wants to duel!"
    duel_request_dialog.show()
    
    if duel_request_dialog.confirmed:
        editor_core.network_manager.accept_duel(peer_id)
    else:
        editor_core.network_manager.reject_duel(peer_id)

func update_opponent_stats(stats: Dictionary):
    # Update UI with opponent's typing stats
    pass 

func _on_duel_accepted(peer_id: int):
    emit_signal("duel_started", peer_id)

func _on_duel_rejected(peer_id: int):
    duel_request_dialog.hide()
    # Optional: Show rejection message
    OS.alert("Player " + str(peer_id) + " rejected the duel.")
