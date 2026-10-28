extends Node3D
## Main game scene. Applies the difficulty and wires the player, The Hollow, the game
## manager, HUD, touch controls, audio and weather together.

@onready var player: LastLightPlayer = $Player
@onready var monster: TheHollowAI = $TheHollow
@onready var gm: LastLightGameManager = $GameManager
@onready var level: LevelBuilder = $Level
@onready var hud: LastLightHUD = $HUD
@onready var touch: MobileControls = $MobileControls/TouchLayer
@onready var audio: LastLightAudio = $AudioManager
@onready var weather: WeatherSystem = $Weather
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var moon: DirectionalLight3D = $Moon


func _ready() -> void:
	var diff := SaveSystem.difficulty()
	monster.apply_difficulty(diff)
	player.flashlight.drain_multiplier = float(diff["battery_drain"])
	player.inventory.apply_starting_supplies(int(diff["extra_supplies"]))
	monster.patrol_points = level.patrol_points

	player.died.connect(gm.player_died)
	gm.final_chase_started.connect(_on_final_chase_started)
	gm.game_won.connect(_on_game_won)

	touch.bind(player)
	audio.bind(player, monster)
	# Own copy, so the weather never edits the scene file's shared Environment between restarts.
	world_env.environment = world_env.environment.duplicate()
	weather.bind(player, world_env.environment, moon)
	hud.bind(player, gm, touch, weather, audio)


func _on_game_won(_title: String, _body: String) -> void:
	audio.escape_mode = true
	player.can_move = false
	player.set_mobile_movement(Vector2.ZERO)


func _on_final_chase_started() -> void:
	monster.set_enraged(true, level.final_chase_spawn)
