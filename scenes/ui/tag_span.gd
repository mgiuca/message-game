class_name TagSpan
extends Control

const LINE_WIDTH : float = 2.0

@export var color : Color:
  set(value):
    color = value
    queue_redraw()

func _draw() -> void:
  var canvas_size := get_rect().size
  draw_line(Vector2(0, 0.5) * canvas_size, Vector2(1, 0.5) * canvas_size, color, LINE_WIDTH, true)
  draw_line(Vector2(0, 0) * canvas_size, Vector2(0, 1) * canvas_size, color, LINE_WIDTH, true)
  draw_line(Vector2(1, 0) * canvas_size, Vector2(1, 1) * canvas_size, color, LINE_WIDTH, true)
