class_name StoryDialog
extends PanelContainer

@onready var lbl_story : RichTextLabel = %LblStory

signal closed

func show_dialog(text: String) -> Signal:
  lbl_story.text = text
  get_tree().paused = true
  show()
  set_process_unhandled_input(true)
  return closed

func _on_btn_close_pressed() -> void:
  get_tree().paused = false
  hide()
  set_process_unhandled_input(false)
  closed.emit()
