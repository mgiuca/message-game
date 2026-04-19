extends Panel

@onready var btn_close_2 : Button = $VBoxContainer/BtnClose2

func _on_btn_close_pressed() -> void:
  hide()

func _on_visibility_changed() -> void:
  if visible and btn_close_2:
    btn_close_2.grab_focus()
