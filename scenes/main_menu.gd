extends Node

const CREDITS_SCROLL_CONTINUOUS = 300
var txt_credits_focused : bool = false

@onready var settings : Settings = %Settings

@export_group('Settings')

## Starts the game in fullscreen mode.
@export var start_fullscreen : bool = true

## Default volume of the music bus (0.0-1.0).
@export var music_volume : float = 1.0

## Default volume of the sound effects bus (0.0-1.0).
@export var sound_effects_volume : float = 1.0

func _ready() -> void:
  if Main.ensure_main_and_load_file(self):
    return

  Globals.init_settings(start_fullscreen, music_volume, sound_effects_volume)

  if OS.has_feature('mobile') or OS.has_feature('web'):
    # Doesn't make sense to "quit" on mobile or web.
    # (Especially web, which just crashes.)
    (%BtnQuit as Control).hide()
  if OS.has_feature('web'):
    # Set up the "Exit Fullscreen" main menu button as a substitute for "Quit".
    Globals.fullscreen_changed.connect(_on_fullscreen_changed)
    _on_fullscreen_changed()
  else:
    (%BtnExitFullscreen as Control).hide()

  (%BtnStart as Control).grab_focus()

func _on_fullscreen_changed() -> void:
  (%BtnExitFullscreen as Control).visible = Globals.fullscreen

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed('ui_cancel'):
    if (%LevelChooser as Control).visible:
      levelchooser_back()
    elif (%Credits as Control).visible:
      credits_back()

func _process(delta: float) -> void:
  # Manually continuously scroll based on the up/down axes.
  # It is too janky to handle this as an input event, and the default handler
  # doesn't work with joystick at all for some reason.
  if txt_credits_focused:
    var motion : float = Input.get_axis('ui_up', 'ui_down')
    if motion != 0:
      var scroll := (%TxtCredits as RichTextLabel).get_v_scroll_bar()
      scroll.value += motion * CREDITS_SCROLL_CONTINUOUS * delta

func _on_btn_start_pressed() -> void:
  LevelManager.switch_to_level_index(0)

func _on_btn_level_select_pressed() -> void:
  populate_level_chooser()
  (%TopLevel as Control).hide()
  (%LevelChooser as Control).show()
  var lst_levels : ItemList = %LstLevels
  lst_levels.grab_focus()
  if lst_levels.item_count > 0:
    lst_levels.select(0)

func _on_btn_settings_pressed() -> void:
  (%TopLevel as Control).hide()
  (%Settings as Settings).show_dialog()

func _on_btn_credits_pressed() -> void:
  (%TopLevel as Control).hide()
  (%Credits as Control).show()
  (%TxtCredits as Control).grab_focus()

func _on_btn_quit_pressed() -> void:
  get_tree().quit()

func _on_btn_exit_fullscreen_pressed() -> void:
  Globals.fullscreen = false

func _on_settings_closed() -> void:
  (%TopLevel as Control).show()
  (%BtnStart as Control).grab_focus()

func _on_levelchooser_btn_back_pressed() -> void:
  levelchooser_back()

func levelchooser_back() -> void:
  (%TopLevel as Control).show()
  (%LevelChooser as Control).hide()
  (%BtnStart as Control).grab_focus()

func _on_lst_levels_item_activated(index: int) -> void:
  LevelManager.switch_to_level_index(index)

func _on_lst_levels_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
  LevelManager.switch_to_level_index(index)

func credits_back() -> void:
  (%Credits as Control).hide()
  (%TopLevel as Control).show()
  (%BtnStart as Control).grab_focus()

func _on_credits_btn_back_pressed() -> void:
  credits_back()

func _on_txt_credits_gui_input(event: InputEvent) -> void:
  # Simply mask ui_down and ui_up events to avoid the focus switching (see
  # _process for handling of scrolling).
  var txt : RichTextLabel = %TxtCredits
  if event.is_action_pressed('ui_down', true) or event.is_action_pressed('ui_up', true):
    txt.accept_event()
    return

func _on_txt_credits_focus_entered() -> void:
  txt_credits_focused = true

func _on_txt_credits_focus_exited() -> void:
  txt_credits_focused = false

func _on_txt_credits_meta_clicked(meta: Variant) -> void:
  OS.shell_open(str(meta))

func populate_level_chooser() -> void:
  var list : ItemList = %LstLevels
  list.clear()
  for level in LevelManager.LEVEL_NAMES:
    list.add_item(LevelManager.level_display_name(level))
