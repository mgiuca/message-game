## Singleton manager concerned with detecting which input device is active and
## notifying of input device changes.
extends Node

## Describes the general input scheme being used.
enum InputMode {
  ## Keyboard and/or mouse.
  KEYBOARD,
  ## Game controller or joystick.
  JOYSTICK,
  ## Touch screen.
  TOUCH,
}

## Emitted when [member input_mode] changes.
signal input_mode_changed(new_mode: InputMode)

## Which device we last received input from.
## Used for various things like whether to show the cursor, tutorial prompts,
## and any other aspect of the user interface that needs to differ depending on
## the control scheme.
var input_mode : InputMode:
  set(value):
    if input_mode != value:
      input_mode = value
      input_mode_changed.emit(value)

## The behaviour of the mouse. Kind of like the Input.MouseMode enum but a bit
## higher level. Specifically, the VISIBLE state is conditional on whether the
## game is in keyboard+mouse mode.
enum MouseState {
  VISIBLE,
  HIDDEN,
  LOCKED,
}
# NOTE: Which mouse states are needed depends on the type of game. These can
# be removed as needed, and then mouse_state could be converted into a bool, or
# removed entirely.
# For example, most games do not need the LOCKED state (other than games with a
# mouse-controlled camera). A game that uses the mouse cursor for gameplay (such
# as an RTS) could remove the HIDDEN state, though it's likely still useful for
# cutscenes, etc.
# Rarely, a game might want to show the mouse when the player is actively using
# the mouse, but hide it when they use the keyboard. That is not supported here;
# in that case, MOUSE should be added as a third separate input mode.

## The behaviour of the mouse, to be set contextually by the game.
var mouse_state : MouseState = MouseState.VISIBLE:
  set(value):
    if mouse_state != value:
      mouse_state = value
      set_mouse_mode()

func _ready() -> void:
  set_initial_input_mode()

  process_mode = Node.PROCESS_MODE_ALWAYS  # So _input works when paused.
  set_mouse_mode()

  Input.joy_connection_changed.connect(_on_joy_connection_changed)

func set_initial_input_mode() -> void:
  if OS.has_feature('mobile') or OS.has_feature("web_android") or \
     OS.has_feature("web_ios"):
    input_mode = InputMode.TOUCH
  elif Input.get_connected_joypads().is_empty():
    input_mode = InputMode.KEYBOARD
  else:
    input_mode = InputMode.JOYSTICK

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
  if Input.get_connected_joypads().is_empty():
    # Unplugged the last joystick; go back to either touch or keyboard.
    set_initial_input_mode()
  else:
    # Plugged in a joystick, switch to this input mode.
    input_mode = InputMode.JOYSTICK

func _input(event : InputEvent) -> void:
  # Just used to detect input mode changes (not actually handle input).
  if event is InputEventKey:
    input_mode = InputMode.KEYBOARD
  elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
    input_mode = InputMode.JOYSTICK
  elif event is InputEventScreenTouch or event is InputEventScreenDrag or \
    (event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION):
    # The last of these conditions is for simulated mouse inputs that actually
    # come from a touch event.
    input_mode = InputMode.TOUCH
  elif event is InputEventMouse and mouse_state != MouseState.HIDDEN:
    # Logic is a bit tricky: if the mouse state is HIDDEN then the mouse is
    # not currently relevant, so mouse inputs should not change the input mode.
    # If the mouse is VISIBLE but we're in non-KEYBOARD mode, we can't actually
    # see the mouse, so we need to switch to KEYBOARD mode which will show the
    # mouse.
    input_mode = InputMode.KEYBOARD
  set_mouse_mode()

func set_mouse_mode() -> void:
  if mouse_state == MouseState.LOCKED:
    DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
  elif mouse_state == MouseState.VISIBLE and input_mode == InputMode.KEYBOARD:
    DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
  else:
    DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
