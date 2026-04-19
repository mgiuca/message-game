extends Level

const SIGNAL_FREQUENCY : float = 673

# Percent tolerance for getting the correct answer.
const VERIFY_TOLERANCE_PCT : float = 1.15

var source_image : Image = load('res://data/image.png')
var signal_audio_stream : AudioStreamWAV
var audio_stream : AudioStreamWAV

var playing : bool = false:
  set(value):
    playing = value
    update_play_button_text()
var playhead_time : float:
  set(value):
    playhead_time = value
    if playhead:
      update_playhead()

@onready var audio_stream_player : AudioStreamPlayer = $AudioStreamPlayer
@onready var btn_play_stop : Button = %BtnPlayStop
@onready var waveform : Waveform = %Waveform
@onready var playhead : VLine = %Waveform/PlayHead

var filter_frequency : float = 50:
  set(value):
    update_filter_frequency()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()
  signal_audio_stream = PulseGenerator.generate_audio_from_image(source_image)
  update_play_button_text()

  update_filter_frequency()

func _process(_delta: float) -> void:
  if audio_stream_player.playing and not audio_stream_player.stream_paused:
    # Invalid when not playing.
    playhead_time = audio_stream_player.get_playback_position()

func update_playhead() -> void:
  playhead.position.x = waveform.t_to_x(playhead_time)

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

func update_filter_frequency() -> void:
  audio_stream = signal_audio_stream # TODO
  audio_stream_player.stream = audio_stream
  waveform.audio_stream = audio_stream

func _on_sld_tune_freq_value_changed(value: float) -> void:
  filter_frequency = value

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
