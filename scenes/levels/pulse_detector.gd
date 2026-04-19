extends Level

var playing : bool = false:
  set(value):
    playing = value
    update_play_button_text()

var source_image : Image = load('res://data/image.png')
var audio_stream : AudioStreamWAV

var playhead_time : float:
  set(value):
    playhead_time = value
    if playhead:
      update_playhead()

@onready var btn_play_stop : Button = %BtnPlayStop
@onready var tex_waveform : Waveform = %TexWaveform
@onready var audio_stream_player : AudioStreamPlayer = $AudioStreamPlayer

@onready var tag_span_pulse_width : TagSpan = %TexWaveform/TagSpanPulseWidth
@onready var tag_span_p2p_zero : TagSpan = %TexWaveform/TagSpanP2PZero
@onready var tag_span_p2p_one : TagSpan = %TexWaveform/TagSpanP2POne
@onready var playhead : VLine = %TexWaveform/PlayHead

@onready var lbl_pulse_freq : Label = %LblPulseFreq
@onready var lbl_zero_freq : Label = %LblZeroFreq
@onready var lbl_one_freq : Label = %LblOneFreq

# Note: start is not necessarily before end; start is just where you started
# clicking and end is where you finished clicking.
class TagRange extends RefCounted:
  var start : float
  var end : float

  var width : float:
    get():
      return absf(end - start)

  var freq : float:
    get():
      return 1 / width

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

  update_playhead()

  update_play_button_text()
  ($MarginContainer/VBoxContainer/GridContainer/ChkPlayhead as CheckBox).button_pressed = true
  update_tags()

func _process(_delta: float) -> void:
  if audio_stream_player.playing and not audio_stream_player.stream_paused:
    # Invalid when not playing.
    playhead_time = audio_stream_player.get_playback_position()

func update_playhead() -> void:
  playhead.position.x = tex_waveform.t_to_x(playhead_time)

func seek(time: float) -> void:
  if audio_stream_player.playing and not audio_stream_player.stream_paused:
    # Invalid when not playing.
    audio_stream_player.seek(time)
  else:
    playhead_time = time

func update_play_button_text() -> void:
  btn_play_stop.text = 'Pause' if playing else 'Play'

func _on_btn_confirm_pressed() -> void:
  # TODO: Check
  LevelManager.switch_to_next_level_or_quit()

func play() -> void:
  audio_stream_player.play(playhead_time)

  playing = true

func stop() -> void:
  audio_stream_player.stream_paused = true
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
  if selected_tag_range == null:
    seek(time)
    return

  selected_tag_range.start = time
  selected_tag_range.end = time
  update_tags()

func _on_tex_waveform_end_drag(time: float) -> void:
  if selected_tag_range == null:
    return

  selected_tag_range.end = time
  update_tags()

func _on_tex_waveform_continue_drag(time: float) -> void:
  if selected_tag_range == null:
    seek(time)
    return

  selected_tag_range.end = time
  update_tags()

func _on_tex_waveform_zoom_changed(_start_time: float, _end_time: float) -> void:
  update_tags()

func update_tags() -> void:
  update_tag(pulse_width_range, tag_span_pulse_width)
  update_tag(p2p_zero_range, tag_span_p2p_zero)
  update_tag(p2p_one_range, tag_span_p2p_one)

  lbl_pulse_freq.text = 'Pulse frequency: %.0f Hz' % pulse_width_range.freq
  lbl_zero_freq.text = 'Code #0 frequency: %.0f Hz' % p2p_zero_range.freq
  lbl_one_freq.text = 'Code #1 frequency: %.0f Hz' % p2p_one_range.freq

func update_tag(time_range: TagRange, span: TagSpan) -> void:
  var start_x := tex_waveform.t_to_x(time_range.start)
  var end_x := tex_waveform.t_to_x(time_range.end)
  if start_x > end_x:
    var temp := start_x
    start_x = end_x
    end_x = temp
  span.position.x = start_x
  span.size.x = end_x - start_x

func _on_chk_tagging_mode_toggled(toggled_on: bool, index: int) -> void:
  if not toggled_on:
    return
  match index:
    0:
      selected_tag_range = null
    1:
      selected_tag_range = pulse_width_range
    2:
      selected_tag_range = p2p_zero_range
    3:
      selected_tag_range = p2p_one_range
