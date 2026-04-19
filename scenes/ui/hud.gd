class_name HUD
extends MarginContainer

@export_group('Debug')

signal show_help

## Determines whether "debug"-level information is visible.
@export var debug_visible : bool:
  set(value):
    debug_visible = value
    (%DebugItems as Control).visible = value

func _ready() -> void:
  debug_visible = debug_visible  # Ensure setter is called.

func set_level_properties(_level_name: String) -> void:
  pass

func set_framerate(framerate: float) -> void:
  if debug_visible:
    (%LblPerformance as Label).text = "FPS: %.1f" % framerate

func _on_btn_help_pressed() -> void:
  show_help.emit()
