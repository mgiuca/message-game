extends Control

@onready var image : Image = load('res://data/image.png')
const PULSES_FILENAME : String = 'res://data/pulses.wav'
const NOISE_FILENAME : String = 'res://data/noise.wav'

var audio_stream : AudioStreamWAV
var save_filename : String

@onready var lbl_image : Label = %LblImage
@onready var lbl_status : Label = %LblStatus

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  lbl_image.text = 'Image loaded: %s' % image.resource_path

func _on_btn_convert_pressed() -> void:
  audio_stream = PulseGenerator.generate_audio_from_image(image)
  lbl_status.text = 'Conversion complete (%d samples)' % [audio_stream.data.size()]
  save_filename = PULSES_FILENAME

func _on_btn_save_pressed() -> void:
  if not save_filename:
    return
  audio_stream.save_to_wav(save_filename)
  lbl_status.text = 'Saved to %s' % save_filename

func _on_btn_noise_pressed() -> void:
  audio_stream = PulseGenerator.generate_audio_from_noise(
    image.get_data_size() * PulseGenerator.PULSE_LENGTH)
  lbl_status.text = 'Noise generation complete (%d samples)' % audio_stream.data.size()
  save_filename = NOISE_FILENAME
