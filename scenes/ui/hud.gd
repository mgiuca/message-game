class_name HUD
extends MarginContainer

@export_group('Debug')

## Determines whether "debug"-level information is visible.
@export var debug_visible : bool:
  set(value):
    debug_visible = value
    (%DebugItems as Control).visible = value

func _ready() -> void:
  debug_visible = debug_visible  # Ensure setter is called.
  InputManager.input_mode_changed.connect(_on_input_mode_changed)
  _on_input_mode_changed(InputManager.input_mode)

func set_level_properties(level_name: String) -> void:
  (%LblLevelName as Label).text = level_name

func set_framerate(framerate: float) -> void:
  if debug_visible:
    (%LblPerformance as Label).text = "FPS: %.1f" % framerate

func _on_input_mode_changed(new_mode: InputManager.InputMode) -> void:
  var input_device_str : String
  match new_mode:
    InputManager.InputMode.KEYBOARD:
      input_device_str = 'keyboard'
    InputManager.InputMode.JOYSTICK:
      input_device_str = 'joystick'
    InputManager.InputMode.TOUCH:
      input_device_str = 'touch'
  (%LblInputMode as Label).text = 'Input device: %s' % input_device_str

  # TODO: Set the textures for all the button prompts.
  match new_mode:
    InputManager.InputMode.KEYBOARD:
      pass
    InputManager.InputMode.JOYSTICK:
      pass
    InputManager.InputMode.TOUCH:
      pass
