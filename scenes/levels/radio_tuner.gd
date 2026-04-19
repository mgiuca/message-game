extends Level

# Percent tolerance for getting the correct answer.
const VERIFY_TOLERANCE_PCT : float = 1.15

var playing : bool = false:
  set(value):
    playing = value
    update_play_button_text()

var source_image : Image = load('res://data/image.png')
var signal_audio_stream : AudioStreamWAV
var noise_audio_stream : AudioStreamWAV

var playhead_time : float:
  set(value):
    playhead_time = value
    if playhead:
      update_playhead()

@onready var btn_play_stop : Button = %BtnPlayStop
@onready var chk_only_visible : CheckBox = %ChkOnlyVisible
@onready var waveform : Waveform = %Waveform
@onready var audio_stream_player : AudioStreamPlayer = $AudioStreamPlayer
@onready var audio_stream : AudioStreamSynchronized = audio_stream_player.stream

@onready var playhead : VLine = %Waveform/PlayHead

var filter_frequency : float = 50:
  set(value):
    update_filter_frequency()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()

  signal_audio_stream = PulseGenerator.generate_audio_from_image(source_image)
  noise_audio_stream = PulseGenerator.generate_audio_from_noise(signal_audio_stream.get_length())
  waveform.audio_stream = audio_stream

  set_up_streams()

  update_playhead()

  update_play_button_text()

  update_filter_frequency()

func set_up_streams() -> void:
  audio_stream.stream_count = 2
  audio_stream.set_sync_stream(0, noise_audio_stream)
  audio_stream.set_sync_stream(1, signal_audio_stream)

func _process(_delta: float) -> void:
  if audio_stream_player.playing and not audio_stream_player.stream_paused:
    if chk_only_visible.button_pressed:
      var t := audio_stream_player.get_playback_position()
      if t < waveform.start_time or t > waveform.end_time:
        audio_stream_player.seek(waveform.start_time)

    # Invalid when not playing.
    playhead_time = audio_stream_player.get_playback_position()

func update_playhead() -> void:
  playhead.position.x = waveform.t_to_x(playhead_time)

func update_filter_frequency() -> void:
  audio_stream_player.stream = audio_stream
  waveform.audio_stream = audio_stream

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

func _on_waveform_start_drag(time: float) -> void:
  seek(time)

func _on_waveform_continue_drag(time: float) -> void:
  seek(time)

func _on_sld_tune_freq_value_changed(value: float) -> void:
  filter_frequency = value
