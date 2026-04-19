## Displays a waveform graph on a Control node.
class_name Waveform
extends Control

## The audio to display.
@export var audio_stream : AudioStreamWAV:
  set(value):
    audio_stream = value
    queue_redraw()

@export_group('Viewing parameters')

@export var start_time : float:
  set(value):
    start_time = value
    queue_redraw()

@export var end_time : float = 0.5:
  set(value):
    end_time = value
    queue_redraw()

func _ready() -> void:
  pass

func _draw() -> void:
  if not audio_stream:
    return

  var mix_rate := audio_stream.mix_rate
  var data := audio_stream.data
  var points : PackedVector2Array
  var canvas_size := get_rect().size
  print('Redraw: %.2f - %.2f' % [start_time, end_time])
  var st := clampi(roundi(start_time * mix_rate), 0, data.size() - 1)
  var et := clampi(roundi(end_time * mix_rate), 0, data.size() - 1)
  for i in range(st, et):
    var sample := data.decode_s8(i)
    var percent_sample := (float(sample) / 256.0) + 0.5
    var percent_time := float(i - st) / float(et - st)
    points.append(Vector2(percent_time, percent_sample) * canvas_size)
  const LINE_WIDTH = 1.0
  draw_polyline(points, Color.LIGHT_BLUE, LINE_WIDTH, true)
