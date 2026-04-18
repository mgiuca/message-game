class_name Level
extends Control

@onready var hud : HUD = $UI/HUD

@export_group('Debug')

## If true, UI shows lots of extra debugging info.
@export var debug_info : bool

## Bypass the menu and immediately exit.
@export var esc_immediately_quits : bool = false

## Introduces an artificial random lag each (actual) frame to simulate a
## low-performance device.
@export var artificial_lag : bool

func _ready() -> void:
  if Main.ensure_main_and_load_file(self):
    return

  LevelManager.current_level = self

  hud.set_level_properties(LevelManager.current_level_display_name)
  hud.debug_visible = debug_info

func _unhandled_input(event: InputEvent) -> void:
  # Meta/UI inputs.
  if event.is_action_pressed('menu'):
    if esc_immediately_quits:
      get_tree().quit()
    else:
      (%Menu as Menu).show_menu()
  elif event.is_action_pressed('toggle_fullscreen'):
    Globals.fullscreen = not Globals.fullscreen
  elif event.is_action_pressed('debug_prev_level'):
    LevelManager.switch_to_prev_level()
  elif event.is_action_pressed('debug_next_level'):
    LevelManager.switch_to_next_level()
