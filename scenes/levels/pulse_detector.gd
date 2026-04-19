extends Level

var playing : bool = false:
  set(value):
    playing = value
    update_play_button_text()

var source_image : Image = load('res://data/image.png')
var audio_stream : AudioStreamWAV

@onready var btn_play_stop : Button = %BtnPlayStop
@onready var tex_waveform : Waveform = %TexWaveform
@onready var audio_stream_player : AudioStreamPlayer = $AudioStreamPlayer

@onready var tag_span_pulse_width : TagSpan = %TexWaveform/TagSpanPulseWidth
@onready var tag_span_p2p_zero : TagSpan = %TexWaveform/TagSpanP2PZero
@onready var tag_span_p2p_one : TagSpan = %TexWaveform/TagSpanP2POne

# Note: start is not necessarily before end; start is just where you started
# clicking and end is where you finished clicking.
class TagRange extends RefCounted:
  var start : float
  var end : float

@onready var pulse_width_range := TagRange.new()
@onready var p2p_zero_range := TagRange.new()
@onready var p2p_one_range := TagRange.new()

var selected_tag_range : TagRange  # alias one of the above

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()

  audio_stream = PulseGenerator.generate_audio_from_image(source_image)
  audio_stream_player.stream = audio_stream
  tex_waveform.audio_stream = audio_stream

  update_play_button_text()

  _on_opt_tag_mode_item_selected(0)

func update_play_button_text() -> void:
  btn_play_stop.text = 'Pause' if playing else 'Play'

func _on_btn_confirm_pressed() -> void:
  # TODO: Check
  LevelManager.switch_to_next_level_or_quit()

func play() -> void:
  audio_stream_player.play()
  playing = true

func stop() -> void:
  audio_stream_player.playing = false
  playing = false

func _on_btn_play_stop_pressed() -> void:
  playing = not playing
  if playing:
    play()
  else:
    stop()

func _on_audio_stream_player_finished() -> void:
  playing = false

func _on_tex_waveform_start_drag(time: float) -> void:
  selected_tag_range.start = time
  selected_tag_range.end = time
  update_tags()

func _on_tex_waveform_end_drag(time: float) -> void:
  selected_tag_range.end = time
  update_tags()

func _on_tex_waveform_continue_drag(time: float) -> void:
  selected_tag_range.end = time
  update_tags()

func _on_tex_waveform_zoom_changed(_start_time: float, _end_time: float) -> void:
  update_tags()

func update_tags() -> void:
  update_tag(pulse_width_range, tag_span_pulse_width)
  update_tag(p2p_zero_range, tag_span_p2p_zero)
  update_tag(p2p_one_range, tag_span_p2p_one)

func update_tag(time_range: TagRange, span: TagSpan) -> void:
  var start_x := tex_waveform.t_to_x(time_range.start)
  var end_x := tex_waveform.t_to_x(time_range.end)
  if start_x > end_x:
    var temp := start_x
    start_x = end_x
    end_x = temp
  span.position.x = start_x
  span.size.x = end_x - start_x

func _on_opt_tag_mode_item_selected(index: int) -> void:
  match index:
    0:
      selected_tag_range = pulse_width_range
    1:
      selected_tag_range = p2p_zero_range
    2:
      selected_tag_range = p2p_one_range
