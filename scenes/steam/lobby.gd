extends Node

const PACKET_READ_LIMIT: int = 32

var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 10
var lobby_vote_kick: bool = false
var steam_id: int = 0
var steam_username: String = ""

func _ready() -> void:

    Steam.join_requested.connect(_on_lobby_join_requested)
    Steam.lobby_chat_update.connect(_on_lobby_chat_update)
    Steam.lobby_created.connect(_on_lobby_created)
    Steam.lobby_data_update.connect(_on_lobby_data_update)
    Steam.lobby_invite.connect(_on_lobby_invite)
    Steam.lobby_joined.connect(_on_lobby_joined)
    Steam.lobby_match_list.connect(_on_lobby_match_list)
    Steam.lobby_message.connect(_on_lobby_message)
    Steam.persona_state_change.connect(_on_persona_change)


    $ChatInput.text_changed.connect(_on_chat_text_changed)
    $ChatInput.text_submitted.connect(_on_chat_text_entered)
    $SendChat.pressed.connect(_on_send_chat_pressed)
    $LobbyBtns/Create.pressed.connect(_on_create_lobby_pressed)
    $LobbyBtns/List.pressed.connect(_on_open_lobby_list_pressed)
    $LobbyBtns/Data.pressed.connect(_on_get_lobby_data_pressed)
    $LobbyBtns/Leave.pressed.connect(_on_leave_lobby_pressed)
    $LobbyBtns/Send.pressed.connect(_on_send_packet_pressed)
    $LobbyBtns/Back.pressed.connect(_on_back_pressed)
    $Close.pressed.connect(_on_close_lobbies_pressed)
    $Refresh.pressed.connect(_on_refresh_pressed)


    # Check for command line arguments
    check_command_line()

func check_command_line() -> void:
    var these_arguments: Array = OS.get_cmdline_args()

    # There are arguments to process
    if these_arguments.size() > 0:

        # A Steam connection argument exists
        if these_arguments[0] == "+connect_lobby":

            # Lobby invite exists so try to connect to it
            if int(these_arguments[1]) > 0:

                # At this point, you'll probably want to change scenes
                # Something like a loading into lobby screen
                print("Command line lobby ID: %s" % these_arguments[1])
                join_lobby(int(these_arguments[1]))


func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
    if connect == 1:
        # Set the lobby ID
        lobby_id = this_lobby_id
        print("Created a lobby: %s" % lobby_id)

        # Set this lobby as joinable, just in case, though this should be done by default
        Steam.setLobbyJoinable(lobby_id, true)

        # Set some lobby data
        Steam.setLobbyData(lobby_id, "name", "Gramps' Lobby")
        Steam.setLobbyData(lobby_id, "mode", "GodotSteam test")

        # Allow P2P connections to fallback to being relayed through Steam if needed
        var set_relay: bool = Steam.allowP2PPacketRelay(true)
        print("Allowing Steam to be relay backup: %s" % set_relay)


func _on_lobby_match_list(these_lobbies: Array) -> void:
    for this_lobby in these_lobbies:
        # Pull lobby data from Steam, these are specific to our example
        var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
        var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")

        # Get the current number of members
        var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)

        # Create a button for the lobby
        var lobby_button: Button = Button.new()
        lobby_button.set_text("Lobby %s: %s [%s] - %s Player(s)" % [this_lobby, lobby_name, lobby_mode, lobby_num_members])
        lobby_button.set_size(Vector2(800, 50))
        lobby_button.set_name("lobby_%s" % this_lobby)
        lobby_button.connect("pressed", Callable(self, "join_lobby").bind(this_lobby))

        # Add the new lobby to the list
        $Lobbies/List.add_child(lobby_button)

func join_lobby(this_lobby_id: int) -> void:
    print("Attempting to join lobby %s" % lobby_id)

    # Clear any previous lobby members lists, if you were in a previous lobby
    lobby_members.clear()

    # Make the lobby join request to Steam
    Steam.joinLobby(this_lobby_id)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
    # If joining was successful
    if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
        # Set this lobby ID as your lobby ID
        lobby_id = this_lobby_id

        # Get the lobby members
        get_lobby_members()

        # Make the initial handshake
        make_p2p_handshake()

    # Else it failed for some reason
    else:
        # Get the failure reason
        var fail_reason: String

        match response:
            Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
            Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
            Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
            Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
            Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
            Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
            Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
            Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
            Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
            Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."

        print("Failed to join this chat room: %s" % fail_reason)

        #Reopen the lobby list
        _on_open_lobby_list_pressed()

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
    # Get the lobby owner's name
    var owner_name: String = Steam.getFriendPersonaName(friend_id)

    print("Joining %s's lobby..." % owner_name)

    # Attempt to join the lobby
    join_lobby(this_lobby_id)

func get_lobby_members() -> void:
    # Clear your previous lobby list
    lobby_members.clear()

    # Get the number of members from this lobby from Steam
    var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)

    # Get the data of these players from Steam
    for this_member in range(0, num_of_members):
        # Get the member's Steam ID
        var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)

        # Get the member's Steam name
        var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

        # Add them to the list
        lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})

# A user's information has changed
func _on_persona_change(this_steam_id: int, _flag: int) -> void:
    # Make sure you're in a lobby and this user is valid or Steam might spam your console log
    if lobby_id > 0:
        print("A user (%s) had information change, update the lobby list" % this_steam_id)

        # Update the player list
        get_lobby_members()

func make_p2p_handshake() -> void:
    print("Sending P2P handshake to the lobby")

    send_p2p_packet(0, {"message": "handshake", "from": steam_id})

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
    # Get the user who has made the lobby change
    var changer_name: String = Steam.getFriendPersonaName(change_id)

    # If a player has joined the lobby
    if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
        print("%s has joined the lobby." % changer_name)

    # Else if a player has left the lobby
    elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
        print("%s has left the lobby." % changer_name)

    # Else if a player has been kicked
    elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
        print("%s has been kicked from the lobby." % changer_name)

    # Else if a player has been banned
    elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
        print("%s has been banned from the lobby." % changer_name)

    # Else there was some unknown change
    else:
        print("%s did... something." % changer_name)

    # Update the lobby now that a change has occurred
    get_lobby_members()

func _on_send_chat_pressed() -> void:
    # Get the entered chat message
    var this_message: String = $ChatInput.get_text()

    # If there is even a message
    if this_message.length() > 0:
        # Pass the message to Steam
        var was_sent: bool = Steam.sendLobbyChatMsg(lobby_id, this_message)

        # Was it sent successfully?
        if not was_sent:
            print("ERROR: Chat message failed to send.")

    # Clear the chat input
    $ChatInput.clear()

func leave_lobby() -> void:
    # If in a lobby, leave it
    if lobby_id != 0:
        # Send leave request to Steam
        Steam.leaveLobby(lobby_id)

        # Wipe the Steam lobby ID then display the default lobby ID and player list title
        lobby_id = 0

        # Close session with all users
        for this_member in lobby_members:
            # Make sure this isn't your Steam ID
            if this_member['steam_id'] != steam_id:

                # Close the P2P session
                Steam.closeP2PSessionWithUser(this_member['steam_id'])

        # Clear the local lobby list
        lobby_members.clear()


func _on_lobby_data_update(this_lobby_id: int, member_id: int, key: int) -> void:
    print("Success, lobby ID: %s, member ID: %s, key: %s" % [this_lobby_id, member_id, key])

func _on_lobby_invite(inviter: int, this_lobby_id: int, game_id: int) -> void:
    $Output.text  += "You have received an invite from %s to join lobby %s / game %s" % [Steam.getFriendPersonaName(inviter), this_lobby_id, game_id]

func _on_lobby_message(_result: int, user: int, message: String, type: int) -> void:
    # We are only concerned with who is sending the message and what the message is
    var this_sender = Steam.getFriendPersonaName(user)
    # If this is a message or host command
    if type == 1:
        # If the lobby owner and the sender are the same, check for commands
        if user == Steam.getLobbyOwner(lobby_id) and message.begins_with("/"):
            print("Message sender is the lobby owner.")
            # Get any commands
            if message.begins_with("/kick"):
                # Get the user ID for kicking
                var these_commands: PackedStringArray = message.split(":", true)
                # If this is your ID, leave the lobby
                if Global.steam_id == int(these_commands[1]):
                    _on_leave_lobby_pressed()
        # Else this is just chat message
        else:
            # Print the outpubt before showing the message
            print("%s says '%s'" % [this_sender, message])
            $Output.text +="%s says '%s'" % [this_sender, message]
    # Else this is a different type of message
    else:
        match type:
            2: $Output.text +="%s is typing..." % this_sender
            3: $Output.text +="%s sent an invite that won't work in this chat" % this_sender
            4: $Output.text +="%s sent a text emote that is deprecated" % this_sender
            6: $Output.text +="%s has left the chat" % this_sender
            7: $Output.text +="%s has entered the chat" % this_sender
            8: $Output.text +="%s was kicked" % this_sender
            9: $Output.text +="%s was banned" % this_sender
            10: $Output.text +="%s disconnected" % this_sender
            11: $Output.text +="%s sent an old, offline message" % this_sender
            12: $Output.text +="%s sent a link that was removed by the chat filter" % this_sender


func send_p2p_packet(target: int, packet_data: Dictionary) -> void:
    # Set the send_type and channel
    var send_type: int = Steam.P2P_SEND_RELIABLE
    var channel: int = 0
    # Create a data array to send the data through
    var this_packet_data: PackedByteArray = []
    this_packet_data.append_array(var_to_bytes(packet_data))
    # If sending a packet to everyone
    var send_response: bool
    if target == 0:
        # If there is more than one user, send packets
        if lobby_members.size() > 1:
            # Loop through all members that aren't you
            for this_member in lobby_members:
                if this_member['steam_id'] != Global.steam_id:
                    send_response = Steam.sendP2PPacket(this_member['steam_id'], this_packet_data, send_type, channel)
    # Else send the packet to a particular user
    else:
        # Send this packet
        send_response = Steam.sendP2PPacket(target, this_packet_data, send_type, channel)
    # The packets send response is...?
    $Output.text +="P2P packet sent successfully? %s" % send_response

# When the player leaves a lobby for whatever reason
func _on_leave_lobby_pressed() -> void:
    # If in a lobby, leave it
    if lobby_id != 0:
        # Append a new message
        $Output.text +="Leaving lobby %s" % lobby_id
        # Send leave request to Steam
        Steam.leaveLobby(lobby_id)
        # Wipe the Steam lobby ID then display the default lobby ID and player list title
        lobby_id = 0
        # $Frame/Main/Displays/Outputs/Titles/Lobby.set_text("Lobby ID: %s" % lobby_id)
        # $Frame/Main/Displays/PlayerList/Title.set_text("Player List (0)")
        # # Close session with all users
        # for these_members in lobby_members:
        #   var session_closed: bool = Steam.closeP2PSessionWithUser(these_members['steam_id'])
        #   print("P2P session closed with %s: %s" % [these_members['steam_id'], session_closed])
        # # Clear the local lobby list
        # lobby_members.clear()
        # for this_member in $Frame/Main/Displays/PlayerList/Players.get_children():
        #   this_member.hide()
        #   this_member.queue_free()
        # # Enable the create lobby button
        # $Frame/Sidebar/Options/List/CreateLobby.set_disabled(false)
        # # Disable the leave lobby button and all test buttons
        # change_button_controls(true)

func _on_chat_text_changed(new_text: String) -> void:
    if new_text.length() > 0:
        $SendChat.set_disabled(false)
    else:
        $SendChat.set_disabled(true)

func _on_chat_text_entered(new_text: String) -> void:
    if new_text.length() > 0:
        _on_send_chat_pressed()
    else:
        $SendChat.set_disabled(true)

func _on_create_lobby_pressed() -> void:
    # Attempt to create a lobby
    create_lobby()
    $Output.text += "Attempt to create a new lobby..."
    # Disable the create lobby button
    $LobbyBtns/Create.set_disabled(true)

func create_lobby() -> void:
    # Make sure a lobby is not already set
    if lobby_id == 0:
        Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)

# Open the lobby list
func _on_open_lobby_list_pressed() -> void:
    $Lobbies.show()
    # Set distance to worldwide
    Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
    # Request the list
    $Output.text +="Requesting a lobby list..."
    Steam.requestLobbyList()

func _on_get_lobby_data_pressed():
    lobby_data = Steam.getLobbyData(lobby_id, "name")
    $Output.text += "Lobby data, name: %s" % lobby_data
    lobby_data = Steam.getLobbyData(lobby_id, "mode")
    $Output.text += "Lobby data, mode: %s" % lobby_data

func _on_send_packet_pressed() -> void:
    $Output.text += "Sending test packet data...\n"
    var test_data: Dictionary = {"title":"This is a test packet", "player_id":Global.steam_id, "player_hp":"5", "player_coord":"56,40"}
    send_p2p_packet(0, test_data)

func _on_back_pressed() -> void:
    # Leave the lobby if in one
    if lobby_id > 0:
        _on_leave_lobby_pressed()

func _on_close_lobbies_pressed() -> void:
    $Lobbies.hide()

func _on_refresh_pressed() -> void:
    # Clear all previous server entries
    for this_server in $Lobbies/List.get_children():
        this_server.queue_free()
    # Disable the refresh button
    $Refresh.set_disabled(true)
    # Set distance to world (or maybe change this option)
    Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
    # Request a new server list
    Steam.requestLobbyList()
