## Displays a waveform graph on a Control node.
class_name Waveform
extends Control

const ZOOM_TICK_PERCENT : float = 1.1
const MIN_DURATION : float = 0.005
const MAX_DURATION : float = 5.0

## The audio to display.
@export var audio_stream : AudioStreamWAV:
  set(value):
    audio_stream = value
    queue_redraw()

@export_group('Viewing parameters')

@export var start_time : float:
  set(value):
    start_time = clampf(value, 0.0, audio_stream.get_length())
    queue_redraw()

@export var end_time : float = 0.5:
  set(value):
    end_time = clampf(value, 0.0, audio_stream.get_length())
    queue_redraw()

func _ready() -> void:
  gui_input.connect(_on_gui_input)

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

func _on_gui_input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    var mouse_event := event as InputEventMouseButton
    if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
      change_zoom(1, mouse_event.position)
    elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
      change_zoom(-1, mouse_event.position)

func change_zoom(dir: float, pos: Vector2) -> void:
  var old_dur := end_time - start_time

  var pos_x := pos.x
  var pos_time := (pos.x / size.x) * old_dur + start_time

  # Aim to keep pos_time the same before and after.
  var new_dur := old_dur / ZOOM_TICK_PERCENT if dir > 0 else old_dur * ZOOM_TICK_PERCENT
  new_dur = clampf(new_dur, MIN_DURATION, MAX_DURATION)
  start_time = pos_time - (pos.x / size.x) * new_dur
  end_time = start_time + new_dur
