# Singleton manager for switching between levels.

extends Node

# List of levels, in order, by base filename (no dir or extension).
const LEVEL_NAMES : Array[String] = [
  'radio_tuner',
  'pulse_detector',
  'image_decoder',
]

# List of test levels that won't show up in the level picker or rotation.
# Put them here to suppress the warning about a level not being in rotation.
const TEST_LEVEL_NAMES = [
]

# Mapping from level basename to display name. If the name is missing, the
# game will display the basename with a warning.
const LEVEL_DISPLAY_NAMES : Dictionary[String, String] = {
  'radio_tuner': 'Radio Tuner',
  'pulse_detector': 'Pulse Detector',
  'image_decoder': 'Image Decoder',
}

var current_level : Level:
  set(value):
    if current_level == value:
      return
    current_level = value
    # Update current_level_idx to match.
    current_level_name = current_level.scene_file_path.get_file().get_basename()
    current_level_idx = LEVEL_NAMES.find(current_level_name)
    if current_level_idx == -1 and TEST_LEVEL_NAMES.find(current_level_name) == -1:
      push_warning('Level "%s" not found in level names list.' % current_level_name)

# Index into LEVEL_NAMES array.
var current_level_idx : int = -1

var current_level_name : String

var current_level_display_name : String:
  get():
    return level_display_name(current_level_name)

func switch_to_level_index(index: int) -> void:
  assert(index >= 0 and index < LEVEL_NAMES.size())
  var level_name : String = LEVEL_NAMES[index]
  var path : String = 'res://scenes/levels/%s.tscn' % level_name
  current_level_idx = index
  Globals.main.change_scene_to_file(path)

## Returns true if the level switched, false if this was the last level.
func switch_to_next_level() -> bool:
  if current_level_idx == LEVEL_NAMES.size() - 1:
    return false

  switch_to_level_index(current_level_idx + 1)
  return true

## Returns true if the level switched, false if this was the last level.
func switch_to_prev_level() -> bool:
  if current_level_idx == 0:
    return false

  switch_to_level_index(current_level_idx - 1)
  return true

## Switches to next level, or to the main menu if this is the last level.
func switch_to_next_level_or_quit() -> void:
  if not switch_to_next_level():
    quit_to_main_menu()

func quit_to_main_menu() -> void:
  Globals.main.change_scene_to_file('res://scenes/main_menu.tscn')

## Gets the display name for a given level name.
func level_display_name(basename: String) -> String:
  if basename in LEVEL_DISPLAY_NAMES:
    return LEVEL_DISPLAY_NAMES[basename]
  else:
    push_warning('Level %s has no display name' % basename)
    return basename
