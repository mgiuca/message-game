extends Level

const IMAGE_TOTAL_PIXELS : int = 1679
var image_width : int = 1

@onready var image_rect : TextureRect = %ImageRect
@onready var lbl_size : Label = %LblSize

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()
  update_display()

func update_display() -> void:
  var image_height := roundi(float(IMAGE_TOTAL_PIXELS) / float(image_width))
  lbl_size.text = '%dx%d' % [image_width, image_height]

  # TODO: Redraw the image with the given width and height.

func _on_sld_width_value_changed(value: float) -> void:
  # TODO: Make this scale evenly biased to width and height (i.e. the left end
  # affects width the same as the right end affects height).
  image_width = roundi(value)
  update_display()
