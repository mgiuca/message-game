class_name StoryDialog
extends PanelContainer

@onready var lbl_story : RichTextLabel = %LblStory
@onready var btn_close : Button = $MarginContainer/VBoxContainer/BtnClose

signal closed

func show_dialog(text: String) -> Signal:
  lbl_story.text = text
  get_tree().paused = true
  show()
  set_process_unhandled_input(true)
  btn_close.grab_focus()
  return closed

func _on_btn_close_pressed() -> void:
  get_tree().paused = false
  hide()
  set_process_unhandled_input(false)
  closed.emit()
