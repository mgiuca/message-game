extends Level

# How many Hz from the correct frequency to win.
const VERIFY_TOLERANCE_RANGE : float = 2

# At this many Hz from the signal frequency, its volume will (just) be reduced
# to 0.
const FREQ_PICKUP_RANGE : float = 5

## Frequencies at which all the different sounding signals reside. #0 is the
## "correct" one. These are not necessarily in order.
const SIGNAL_FREQUENCIES : PackedFloat32Array = [
  673,
  237,
  78,
  892,
  340,
  791,
]

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
@onready var lbl_filter_freq : Label = %LblFilterFreq
@onready var lbl_error : Label = %LblError

const STORY_TEXT : String = """\
A few days ago, we picked up a [color=light_green][wave]strange signal[/wave][/color] from a nearby star. \
We now believe it was produced by intelligent life.

You must [color=sky_blue]decode[/color] the signal and learn its message.

First, scan the radio spectrum, looking for an [color=orange]irregular \
pulse[/color]. Simple repeating patterns are of no interest, but only intelligent \
life could make [color=orange]irregular[/color] patterns.
"""

var filter_frequency : float = 50:
  set(value):
    filter_frequency = value
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

  await story_dialog.show_dialog(STORY_TEXT)
  show_help()

func set_up_streams() -> void:
  audio_stream.stream_count = 7
  audio_stream.set_sync_stream(0, noise_audio_stream)
  # The 6 signals. Corresponding to SIGNAL_FREQUENCIES but offset by 1.
  audio_stream.set_sync_stream(1, signal_audio_stream)
  # The "other" ones.
  var other_streams : Array[AudioStreamWAV] = [
    load('res://data/noise-001.wav'),
    load('res://data/noise-002.wav'),
    load('res://data/noise-003.wav'),
    load('res://data/noise-004.wav'),
    load('res://data/noise-005.wav'),
  ]
  for i in other_streams.size():
    audio_stream.set_sync_stream(i + 2, other_streams[i])

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
  lbl_filter_freq.text = 'Tuning frequency: %.0f MHz' % filter_frequency

  # Adjust the relative volumes of the sub-streams.
  var remaining_amplitude_lin : float = 1.0
  for i in SIGNAL_FREQUENCIES.size():
    var signal_frequency := SIGNAL_FREQUENCIES[i]
    var dist_to_signal := absf(filter_frequency - signal_frequency)
    var signal_volume_lin := clampf(1 - dist_to_signal / FREQ_PICKUP_RANGE, 0, 1)
    remaining_amplitude_lin -= signal_volume_lin
    audio_stream.set_sync_stream_volume(i + 1, linear_to_db(signal_volume_lin))

  # Noise is the remaining volume.
  remaining_amplitude_lin = clampf(remaining_amplitude_lin, 0, 1)
  audio_stream.set_sync_stream_volume(0, linear_to_db(remaining_amplitude_lin))

  waveform.queue_redraw()

func seek(time: float) -> void:
  if audio_stream_player.playing and not audio_stream_player.stream_paused:
    # Invalid when not playing.
    audio_stream_player.seek(time)
  else:
    playhead_time = time

const TEX_PLAY = preload('res://images/play.svg')
const TEX_PAUSE = preload('res://images/pause.svg')

func update_play_button_text() -> void:
  btn_play_stop.icon = TEX_PAUSE if playing else TEX_PLAY
  btn_play_stop.tooltip_text = 'Pause (Space)' if playing else 'Play (Space)'

func _on_btn_confirm_pressed() -> void:
  const correct_frequency := SIGNAL_FREQUENCIES[0]
  if absf(filter_frequency - correct_frequency) > VERIFY_TOLERANCE_RANGE:
    set_error('There is no irregular pattern at that frequency')
    return

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
  clear_error()

func set_error(message: String) -> void:
  lbl_error.text = message

func clear_error() -> void:
  lbl_error.text = ''
