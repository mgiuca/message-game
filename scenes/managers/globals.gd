extends Node

## Singleton for the Main scene which is responsible for embedding other scenes.
var main : Main

func _ready() -> void:
  # The best signal we have of fullscreen state changing at the OS level.
  get_viewport().size_changed.connect(update_fullscreen_state)

var fullscreen : bool = false:
  get():
    return DisplayServer.window_get_mode() in \
      [DisplayServer.WINDOW_MODE_FULLSCREEN,
       DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
  set(value):
    if value:
      DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
      DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    update_fullscreen_state()

var _last_known_fullscreen : bool = false

func update_fullscreen_state() -> void:
  var fullscreen_state := fullscreen
  if _last_known_fullscreen != fullscreen_state:
    _last_known_fullscreen = fullscreen_state
    fullscreen_changed.emit()

var inited : bool = false

## Emitted when fullscreen changes.
signal fullscreen_changed

## Initialize settings. Only works once (so changing levels doesn't
## override your fullscreen setting).
func init_settings(start_fullscreen: bool, start_music_volume: float,
                   start_fx_volume: float) -> void:
  if inited:
    return
  fullscreen = start_fullscreen
  AudioManager.music_volume = start_music_volume
  AudioManager.fx_volume = start_fx_volume
  inited = true
