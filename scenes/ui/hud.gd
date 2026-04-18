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

func set_level_properties(level_name: String) -> void:
  (%LblLevelName as Label).text = level_name

func set_framerate(framerate: float) -> void:
  if debug_visible:
    (%LblPerformance as Label).text = "FPS: %.1f" % framerate
