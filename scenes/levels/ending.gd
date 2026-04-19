extends Level

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()

  hud.hide_help_button()

const STORY_DIPLOMACY : String = """\
We can learn much from the senders of this mysterious message, as they can from us.

Envoys are being dispatched to the far-away planet. It will take many years, but some day \
we hope there can be [color=light_green]peace[/color] between our two civilizations.
"""

const STORY_CONFLICT : String = """\
[color=indian_red][shake]Fools[/shake][/color]! They gave us their exact location, \
and now we know there is a habitable, resource-rich world for the taking!

Battle fleets are being dispatched to the far-away planet. It will take many years, but \
some day, after [color=indian_red]glorious battle[/color], we will plant our flag on our new home world.
"""

func _on_btn_diplomacy_pressed() -> void:
  await story_dialog.show_dialog(STORY_DIPLOMACY)
  LevelManager.switch_to_next_level_or_quit()

func _on_btn_conflict_pressed() -> void:
  await story_dialog.show_dialog(STORY_CONFLICT)
  LevelManager.switch_to_next_level_or_quit()
