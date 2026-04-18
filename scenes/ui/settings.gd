# Settings dialog.
class_name Settings
extends PanelContainer

## Emitted when the dialog closes.
signal closed

func _ready() -> void:
  Globals.fullscreen_changed.connect(update_fullscreen_state)

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed('ui_cancel') or event.is_action_pressed('ui_menu'):
    close_dialog()

func show_dialog() -> void:
  update_fullscreen_state()
  (%SldMusicVolume as Slider).value = AudioManager.music_volume
  (%SldSoundVolume as Slider).value = AudioManager.fx_volume
  show()
  set_process_unhandled_input(true)
  (%ChkFullscreen as Control).grab_focus()

func close_dialog() -> void:
  hide()
  set_process_unhandled_input(false)
  closed.emit()

func update_fullscreen_state() -> void:
  (%ChkFullscreen as CheckBox).button_pressed = Globals.fullscreen

func _on_chk_fullscreen_toggled(toggled_on: bool) -> void:
  Globals.fullscreen = toggled_on

func _on_btn_back_pressed() -> void:
  close_dialog()

func _on_sld_music_volume_value_changed(value: float) -> void:
  AudioManager.music_volume = value

func _on_sld_sound_volume_value_changed(value: float) -> void:
  AudioManager.fx_volume = value
