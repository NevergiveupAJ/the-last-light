extends Node
class_name LastLightGameManager

signal objective_updated(text: String)
signal game_won
signal game_lost

enum GameState { MENU, PLAYING, PAUSED, WON, LOST }
var state: GameState = GameState.MENU
var fuses_found: int = 0
var required_fuses: int = 3
var gate_powered: bool = false

func start_game() -> void:
    fuses_found = 0
    gate_powered = false
    state = GameState.PLAYING
    objective_updated.emit("Find 3 power fuses.")

func collect_fuse() -> void:
    if state != GameState.PLAYING:
        return
    fuses_found = mini(required_fuses, fuses_found + 1)
    if fuses_found < required_fuses:
        objective_updated.emit("Power fuses: %d / %d" % [fuses_found, required_fuses])
    else:
        objective_updated.emit("All fuses found. Restore power at the emergency gate.")

func restore_gate() -> void:
    if fuses_found < required_fuses:
        objective_updated.emit("The gate needs 3 fuses.")
        return
    gate_powered = true
    objective_updated.emit("Gate powered. Reach the exit and escape!")

func reach_exit() -> void:
    if gate_powered:
        state = GameState.WON
        game_won.emit()

func player_died() -> void:
    state = GameState.LOST
    game_lost.emit()

func pause_game() -> void:
    if state == GameState.PLAYING:
        state = GameState.PAUSED
        get_tree().paused = true

func resume_game() -> void:
    if state == GameState.PAUSED:
        get_tree().paused = false
        state = GameState.PLAYING
