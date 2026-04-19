class_name PulseGenerator
extends Object

# Format constants.

const EXPECTED_IMAGE_FORMAT := Image.FORMAT_L8
const WAV_FORMAT := AudioStreamWAV.FORMAT_8_BITS
const WAV_MIX_RATE : int = 44100
const WAV_STEREO : bool = false

# Encoding constants.

## Length of each pulse (s). This includes both the active and gap period.
const PULSE_LENGTH : float = 0.05
## Percentage of the pulse that is active.
const DUTY_CYCLE : float = 1.0
## Total amplitude (0-1) where 1.0 means full blast values.
const AMPLITUDE : float = 0.5
## Frequency (Hz) of the zero pulse.
const FREQ_ZERO : float = 440.0
## Frequency (Hz) of the one pulse.
const FREQ_ONE : float = 660.0

## Converts a monochrome image (L8 format) into a pulse coded WAV file with
## two tones, one for 0 and one for 1.
static func generate_audio_from_image(image: Image) -> AudioStreamWAV:
  var audio_stream := AudioStreamWAV.new()
  audio_stream.format = WAV_FORMAT
  audio_stream.mix_rate = WAV_MIX_RATE
  audio_stream.stereo = WAV_STEREO
  audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

  var data : PackedByteArray
  var pulse_length_samples : int = roundi(PULSE_LENGTH * WAV_MIX_RATE)
  var pulse_active_samples : int = roundi(pulse_length_samples * DUTY_CYCLE)
  assert(pulse_active_samples <= pulse_length_samples)
  var pulse_inactive_samples : int = pulse_length_samples - pulse_active_samples

  var source_data := image.get_data()
  data.resize(source_data.size() * pulse_length_samples)
  for i in source_data.size():
    var start_sample := i * pulse_length_samples
    var freq := FREQ_ONE if source_data[i] > 127 else FREQ_ZERO
    produce_sine_wave(data, start_sample, pulse_active_samples, freq)
    if pulse_inactive_samples > 0:
      produce_zeroes(data, start_sample + pulse_active_samples, pulse_inactive_samples)

  audio_stream.data = data
  audio_stream.loop_end = data.size() - 1
  return audio_stream

static func produce_sine_wave(buffer: PackedByteArray, start_idx : int,
                              length: int, freq: float) -> void:
  assert(start_idx + length <= buffer.size())

  for i in range(start_idx, start_idx + length):
    var t := float(i - start_idx) / WAV_MIX_RATE
    var value := sin(TAU * freq * t) * AMPLITUDE
    buffer.encode_s8(i, clampi(roundi(value * 127), -128, 127))

static func produce_zeroes(buffer: PackedByteArray, start_idx : int,
                           length: int) -> void:
  assert(start_idx + length <= buffer.size())

  for i in range(start_idx, start_idx + length):
    buffer.encode_s8(i, 0)
