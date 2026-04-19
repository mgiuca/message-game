## Displays a waveform graph on a Control node.
class_name Waveform
extends Control

const ZOOM_TICK_PERCENT : float = 1.1
const MIN_DURATION : float = 0.005
const MAX_DURATION : float = 5.0

## The audio to display. Must be either AudioStreamWAV or
## AudioStreamSynchronized featuring WAVs as the sub-streams.
@export var audio_stream : AudioStream:
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

# For middle-mouse scroll drag.
var scrolling : bool = false
var scroll_start_t : float

# Only for left-mouse / external drag (see [member scrolling]).
var dragging : bool = false
var drag_last_position : Vector2

signal start_drag(time: float)
signal continue_drag(time: float)
signal end_drag(time: float)

signal zoom_changed(start_time: float, end_time: float)

func _ready() -> void:
  gui_input.connect(_on_gui_input)
  mouse_exited.connect(_on_mouse_exited)

func _draw() -> void:
  if not audio_stream:
    return

  if audio_stream is AudioStreamWAV:
    draw_wavs([audio_stream], [1])
  elif audio_stream is AudioStreamSynchronized:
    draw_wavs(sync_get_wavs(audio_stream as AudioStreamSynchronized),
              sync_get_volumes(audio_stream as AudioStreamSynchronized))
  else:
    push_error('Stream is not WAV or Sync')

func draw_wavs(streams: Array[AudioStreamWAV], volumes: PackedFloat32Array) -> void:
  if streams.is_empty():
    push_error('Stream has no sub-streams')
    return
  if volumes.size() != streams.size():
    push_error('volumes != streams')
    return

  var datas : Array[PackedByteArray]
  for stream in streams:
    datas.append(stream.data)

  var mix_rate := streams[0].mix_rate
  var num_samples := streams[0].data.size()
  var points : PackedVector2Array
  var canvas_size := get_rect().size
  var st := clampi(roundi(start_time * mix_rate), 0, num_samples - 1)
  var et := clampi(roundi(end_time * mix_rate), 0, num_samples - 1)
  for i in range(st, et):
    var sample : float = 0
    for j in streams.size():
      sample += float(datas[j].decode_s8(i)) / 128.0 * volumes[j]
    sample = clampf(sample, -1, 1)
    var percent_sample := sample * 0.5 + 0.5
    var percent_time := float(i - st) / float(et - st)
    points.append(Vector2(percent_time, percent_sample) * canvas_size)
  const LINE_WIDTH = 1.0
  draw_polyline(points, Color.LIGHT_BLUE, LINE_WIDTH, true)

func sync_get_wavs(stream: AudioStreamSynchronized) -> Array[AudioStreamWAV]:
  var result : Array[AudioStreamWAV]
  for i in stream.stream_count:
    result.append(stream.get_sync_stream(i))
  return result

## Returns the volumes of each sub-stream, in linear (not db). 1.0 is therefore
## the full volume.
func sync_get_volumes(stream: AudioStreamSynchronized) -> PackedFloat32Array:
  var result : PackedFloat32Array
  for i in stream.stream_count:
    result.append(db_to_linear(stream.get_sync_stream_volume(i)))
  return result

func _on_gui_input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    var mouse_event := event as InputEventMouseButton
    if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
      change_zoom(1, mouse_event.position)
    elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
      change_zoom(-1, mouse_event.position)
    elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
      if mouse_event.is_pressed():
        start_drag.emit(x_to_t(mouse_event.position.x))
        dragging = true
        drag_last_position = mouse_event.position
      elif dragging:
        end_drag.emit(x_to_t(mouse_event.position.x))
        dragging = false
    elif mouse_event.button_index == MOUSE_BUTTON_MIDDLE or mouse_event.button_index == MOUSE_BUTTON_RIGHT:
      scrolling = mouse_event.is_pressed()
      if scrolling:
        scroll_start_t = x_to_t(mouse_event.position.x)
  elif event is InputEventMouseMotion:
    var mouse_event := event as InputEventMouseMotion
    if dragging:
      continue_drag.emit(x_to_t(mouse_event.position.x))
      drag_last_position = mouse_event.position
    elif scrolling:
      # Change start_time such that scroll_start_t is at position x.
      var duration := end_time - start_time
      var t_at_x := (mouse_event.position.x / size.x) * duration
      start_time = scroll_start_t - t_at_x
      end_time = start_time + duration
      zoom_changed.emit(start_time, end_time)

func _on_mouse_exited() -> void:
  if dragging:
    end_drag.emit(x_to_t(drag_last_position.x))
    dragging = false
  scrolling = false

func x_to_t(x: float) -> float:
  return (x / size.x) * (end_time - start_time) + start_time

func t_to_x(t: float) -> float:
  return ((t - start_time) / (end_time - start_time)) * size.x

func change_zoom(dir: float, pos: Vector2) -> void:
  var old_dur := end_time - start_time

  var pos_time := x_to_t(pos.x)

  # Aim to keep pos_time the same before and after.
  var new_dur := old_dur / ZOOM_TICK_PERCENT if dir > 0 else old_dur * ZOOM_TICK_PERCENT
  new_dur = clampf(new_dur, MIN_DURATION, MAX_DURATION)
  start_time = pos_time - (pos.x / size.x) * new_dur
  end_time = start_time + new_dur

  zoom_changed.emit(start_time, end_time)
