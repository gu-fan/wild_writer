extends Node

var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_app_id: int = 3410040
var steam_id: int = 0
var steam_username: String = ""
var is_on_steam: bool = false


func _init():
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("GameAppId", str(steam_app_id))
func _ready():
	initialize_steam()

func _process(_delta: float) -> void:
	if is_on_steam:
		Steam.run_callbacks()

func initialize_steam() -> void:
	if Engine.has_singleton("Steam"):
		var initialize_response: Dictionary = Steam.steamInitEx()
		print("Did Steam initialize?: %s" % initialize_response)

		if initialize_response['status'] > 0:
			print("Failed to initialize Steam. %s" % initialize_response)
		else:
			# Gather additional data
			is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
			is_online = Steam.loggedOn()
			is_owned = Steam.isSubscribed()
			steam_id = Steam.getSteamID()
			steam_username = Steam.getPersonaName()

			# Check if account owns the game
			if is_owned == false:
				print("User does not own this game")
				# get_tree().quit()
			else:
				print("User has own this game")

		is_on_steam = true
	else:
		print("[NOTICE] This is the non-Steam version of the app!")
		is_on_steam = false
