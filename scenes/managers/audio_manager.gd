# Singleton manager for controlling audio volume.

extends Node

enum AudioType {
  MUSIC,
  FX,
}

func audio_type_to_bus_name(type: AudioType) -> StringName:
  match type:
    AudioType.MUSIC:
      return &'Music'
    AudioType.FX:
      return &'FX'
    _:
      return &''

func get_audio_volume(type: AudioType) -> float:
  var bus_name := audio_type_to_bus_name(type)
  var bus_index := AudioServer.get_bus_index(bus_name)
  return AudioServer.get_bus_volume_linear(bus_index)

func set_audio_volume(type: AudioType, volume: float) -> void:
  var bus_name := audio_type_to_bus_name(type)
  var bus_index := AudioServer.get_bus_index(bus_name)
  AudioServer.set_bus_volume_linear(bus_index, volume)
  audio_volume_changed.emit(type, volume)

var music_volume : float:
  get():
    return get_audio_volume(AudioType.MUSIC)
  set(value):
    set_audio_volume(AudioType.MUSIC, value)

var fx_volume : float:
  get():
    return get_audio_volume(AudioType.FX)
  set(value):
    set_audio_volume(AudioType.FX, value)

## Emitted when an audio volume level changes.
signal audio_volume_changed(type: AudioType, volume: float)
