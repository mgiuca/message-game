extends Level


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()

func _on_btn_diplomacy_pressed() -> void:
  LevelManager.switch_to_next_level_or_quit()

func _on_btn_conflict_pressed() -> void:
  LevelManager.switch_to_next_level_or_quit()
