extends Control

@onready var image : Image = load('res://data/image.png')
const WAV_FILENAME : String = 'res://data/pulses.wav'

var audio_stream : AudioStreamWAV

@onready var lbl_image : Label = %LblImage
@onready var lbl_status : Label = %LblStatus

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  lbl_image.text = 'Image loaded: %s' % image.resource_path

func _on_btn_convert_pressed() -> void:
  audio_stream = PulseGenerator.generate_audio_from_image(image)
  lbl_status.text = 'Conversion complete (%d samples)' % [audio_stream.data.size()]

func _on_btn_save_pressed() -> void:
  audio_stream.save_to_wav(WAV_FILENAME)
  lbl_status.text = 'Saved to %s' % WAV_FILENAME
