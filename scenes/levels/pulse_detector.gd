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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()

  audio_stream = PulseGenerator.generate_audio_from_image(source_image)
  audio_stream_player.stream = audio_stream
  tex_waveform.audio_stream = audio_stream

  update_play_button_text()


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
