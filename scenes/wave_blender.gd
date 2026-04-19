class_name WaveBlender
extends Object

# Format constants.

const WAV_FORMAT := AudioStreamWAV.FORMAT_8_BITS
const WAV_MIX_RATE : int = 44100
const WAV_STEREO : bool = false

## Generates an AudioStreamWAV from a source AudioStreamWAV blending with white
## noise.
static func mix_noise(waveform: AudioStreamWAV, signal_percent: float) -> AudioStreamWAV:
  var audio_stream := AudioStreamWAV.new()
  audio_stream.format = WAV_FORMAT
  audio_stream.mix_rate = WAV_MIX_RATE
  audio_stream.stereo = WAV_STEREO
  audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

  var data := waveform.data
  for i in data.size():
    var sample := data.decode_s8(i)
    sample = roundi((sample * signal_percent) + (randi_range(-128, 127) * (1 - signal_percent)))
    data.encode_s8(i, clampi(sample, -128, 127))

  audio_stream.data = data
  audio_stream.loop_end = data.size() - 1
  return audio_stream
