extends Level

const IMAGE_TOTAL_PIXELS : int = 1679
const CORRECT_WIDTH : int = 23

var image_width : int = 1

@onready var source_image : Image = load('res://data/image.png')

@onready var image_rect : TextureRect = %ImageRect
@onready var lbl_size : Label = %LblSize

# Must be 1 byte per pixel for the below algorithm to work.
const IMAGE_FORMAT = Image.FORMAT_L8

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()

  update_display()

func update_display() -> void:
  var image_height : int = roundi(float(IMAGE_TOTAL_PIXELS) / float(image_width))
  lbl_size.text = '%dx%d' % [image_width, image_height]

  # Redraw the image with the given width and height. Just copy the pixels from
  # src to dst, ignoring height.
  assert(source_image.get_format() == IMAGE_FORMAT)
  var src_data := source_image.get_data()
  var src_size := source_image.get_data_size()
  var data : PackedByteArray
  data.resize(image_width * image_height)
  for y in image_height:
    for x in image_width:
      var idx := y * image_width + x
      var value : int = 0
      if idx < src_size:
        value = src_data[idx]
      data[idx] = value
  var rearranged_image := Image.create_from_data(image_width, image_height, false,
                                                 IMAGE_FORMAT, data)
  var image_tex := ImageTexture.create_from_image(rearranged_image)
  image_rect.texture = image_tex

func _on_sld_width_value_changed(value: float) -> void:
  # TODO: Make this scale evenly biased to width and height (i.e. the left end
  # affects width the same as the right end affects height).
  image_width = roundi(value)
  update_display()

func _on_btn_confirm_pressed() -> void:
  if image_width == CORRECT_WIDTH:
    LevelManager.switch_to_next_level_or_quit()
  else:
    print("That doesn't look quite right")
