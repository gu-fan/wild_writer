class_name SteamNetworkManager
extends Node

signal lobby_created(lobby_id: int)
signal lobby_joined(lobby_id: int)
signal lobby_left()
signal lobby_member_joined(steam_id: int, steam_name: String)
signal lobby_member_left(steam_id: int)
signal lobby_chat_message(sender_id: int, message: String)
signal lobby_data_updated(key: String, value: String)
signal message_received(sender_id: int, message_data: Dictionary)

const MAX_PLAYERS: int = 10
const MAX_MESSAGES: int = 32
const DEFAULT_CHANNEL: int = 0

var lobby_id: int = 0
var lobby_members: Array[Dictionary] = []

func _ready() -> void:
    if not Global.is_on_steam:
        push_error("Steam未初始化!")
        return
        
    _connect_steam_signals()

func _process(_delta: float) -> void:
    # Steam回调已经在Global中处理
    _check_messages()

func _connect_steam_signals() -> void:
    # 大厅信号
    Steam.lobby_created.connect(_on_lobby_created)
    Steam.lobby_joined.connect(_on_lobby_joined)
    Steam.lobby_chat_update.connect(_on_lobby_chat_update)
    Steam.lobby_data_update.connect(_on_lobby_data_update)
    Steam.lobby_message.connect(_on_lobby_message)
    Steam.join_requested.connect(_on_lobby_join_requested)
    
    # 网络消息信号
    Steam.network_messages_session_request.connect(_on_session_request)
    Steam.network_messages_session_failed.connect(_on_session_failed)

# 大厅管理
func create_lobby(lobby_type: int = Steam.LOBBY_TYPE_PUBLIC) -> void:
    if lobby_id == 0:
        Steam.createLobby(lobby_type, MAX_PLAYERS)

func join_lobby(target_lobby_id: int) -> void:
    if lobby_id == 0:
        Steam.joinLobby(target_lobby_id)

func leave_lobby() -> void:
    if lobby_id != 0:
        # 关闭所有会话
        for member in lobby_members:
            Steam.closeSessionWithUser(member.steam_id)
        
        Steam.leaveLobby(lobby_id)
        lobby_id = 0
        lobby_members.clear()
        emit_signal("lobby_left")

# 消息系统
func send_message(target_id: int, message_data: Dictionary, reliable: bool = true) -> int:
    var flags = 0  # 可以根据需要设置发送标志
    var data = var_to_bytes(message_data)
    return Steam.sendMessageToUser(target_id, data, flags, DEFAULT_CHANNEL)

func broadcast_message(message_data: Dictionary, reliable: bool = true) -> void:
    for member in lobby_members:
        if member.steam_id != Global.steam_id:
            send_message(member.steam_id, message_data, reliable)

func _check_messages() -> void:
    # 检查指定通道的消息
    var messages = Steam.receiveMessagesOnChannel(DEFAULT_CHANNEL, MAX_MESSAGES)
    for message in messages:
        if message.has("payload") and message.has("identity"):
            var sender_id = message.identity
            var data = bytes_to_var(message.payload)
            emit_signal("message_received", sender_id, data)

func _update_lobby_members() -> void:
    lobby_members.clear()
    var member_count = Steam.getNumLobbyMembers(lobby_id)
    
    for i in range(member_count):
        var member_steam_id = Steam.getLobbyMemberByIndex(lobby_id, i)
        lobby_members.append({
            "steam_id": member_steam_id,
            "name": Steam.getFriendPersonaName(member_steam_id)
        })

# 连接状态检查
func get_connection_state(remote_id: int) -> Dictionary:
    return Steam.getSessionConnectionInfo(remote_id, true, true)

# Steam信号处理
func _on_session_request(remote_id: int) -> void:
    # 自动接受来自大厅成员的会话请求
    for member in lobby_members:
        if member.steam_id == remote_id:
            Steam.acceptSessionWithUser(remote_id)
            return

func _on_session_failed(reason: int, remote_id: int, state: int, debug_msg: String) -> void:
    push_warning("会话失败 ID: %s, 原因: %s, 状态: %s\n调试信息: %s" % 
                [remote_id, reason, state, debug_msg])

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
    if connect == 1:
        lobby_id = this_lobby_id
        _update_lobby_members()
        emit_signal("lobby_created", lobby_id)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
    if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
        lobby_id = this_lobby_id
        _update_lobby_members()
        emit_signal("lobby_joined", lobby_id)

func _on_lobby_chat_update(this_lobby_id: int, changed_id: int, making_change_id: int, chat_state: int) -> void:
    if this_lobby_id == lobby_id:
        match chat_state:
            1:
                emit_signal("lobby_member_joined", changed_id, Steam.getFriendPersonaName(changed_id))
                _update_lobby_members()
            2:
                emit_signal("lobby_member_left", changed_id)
                _update_lobby_members()

func _on_lobby_message(_result: int, sender_id: int, message: String, chat_type: int) -> void:
    if chat_type == 1:
        emit_signal("lobby_chat_message", sender_id, message)

func _on_lobby_data_update(this_lobby_id: int, _member_id: int, key: String) -> void:
    if this_lobby_id == lobby_id:
        var value = Steam.getLobbyData(lobby_id, key)
        emit_signal("lobby_data_updated", key, value)

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
    join_lobby(this_lobby_id)
