extends Level


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()


func _on_btn_confirm_pressed() -> void:
  # TODO: Check
  LevelManager.switch_to_next_level_or_quit()
