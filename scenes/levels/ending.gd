extends Level

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()

  hud.hide_help_button()

const STORY_DIPLOMACY : String = """\
DIPLOMACY ENDING
"""

const STORY_CONFLICT : String = """\
CONFLICT ENDING
"""

func _on_btn_diplomacy_pressed() -> void:
  await story_dialog.show_dialog(STORY_DIPLOMACY)
  LevelManager.switch_to_next_level_or_quit()

func _on_btn_conflict_pressed() -> void:
  await story_dialog.show_dialog(STORY_CONFLICT)
  LevelManager.switch_to_next_level_or_quit()
