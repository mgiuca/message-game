class_name Level
extends Node

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

  InputManager.mouse_state = get_mouse_state()
  InputManager.input_mode_changed.connect(_on_input_mode_changed)
  _on_input_mode_changed(InputManager.input_mode)

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

func _process(delta: float) -> void:
  # Delta in real-world seconds.
  # TODO: Only relevant if this game changes Engine.time_scale.
  # If not, just use delta.
  var delta_real_s := delta / Engine.time_scale
  hud.set_framerate(1.0 / delta_real_s)

  if artificial_lag:
    # Artificial delay for testing.
    var x : float
    for i in randi_range(1000000, 4000000):
      x = sin(x)

## Gets the required mouse state based on the current game context.
## Called when closing the menu (which always shows the mouse) to let the game
## put the mouse back into its correct mode. Can also be called whenever the
## game context requires changing mouse state.
func get_mouse_state() -> InputManager.MouseState:
  # TODO: Modify this to reflect the needs of the game (either a hard-coded
  # value, or conditional). If the mouse will always be set to visible, this can
  # be deleted along with _on_menu_closed().
  return InputManager.MouseState.HIDDEN

func _on_input_mode_changed(new_mode: InputManager.InputMode) -> void:
  # TODO: Set the textures for all the button prompts.
  match new_mode:
    InputManager.InputMode.KEYBOARD:
      pass
    InputManager.InputMode.JOYSTICK:
      pass
    InputManager.InputMode.TOUCH:
      pass

func _on_menu_closed() -> void:
  InputManager.mouse_state = get_mouse_state()
