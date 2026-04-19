extends Level

@onready var image_width : int = roundi((%SldWidth as Slider).value)

@onready var source_image : Image = load('res://data/image.png')

@onready var image_rect : TextureRect = %ImageRect
@onready var lbl_size : Label = %LblSize

@onready var lbl_error : Label = %LblError

# Must be 1 byte per pixel for the below algorithm to work.
const IMAGE_FORMAT = Image.FORMAT_L8

const STORY_TEXT : String = """\
Using your code frequencies, we were able to convert each pulse in the entire \
signal into a 1 or a 0: a [color=orange]binary code[/color]! But what could it mean?

Perhaps a picture? What if we make each 0 a black pixel and each 1 a white pixel... \
we would just need to figure out how to arrange the pixels into a rectangular grid.

Try to figure out if there is any arrangement that makes a meaningful picture.
"""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  super._ready()

  update_display()

  await story_dialog.show_dialog(STORY_TEXT)
  show_help()

func update_display() -> void:
  var source_size := source_image.get_size()
  var pixel_count := source_size.x * source_size.y
  var image_height : int = ceili(float(pixel_count) / float(image_width))
  lbl_size.text = 'Image size: %dx%d' % [image_width, image_height]

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
  clear_error()

func _on_btn_confirm_pressed() -> void:
  if image_width == source_image.get_width():
    LevelManager.switch_to_next_level_or_quit()
  else:
    set_error("That doesn't look like a meaningful picture")

func set_error(message: String) -> void:
  lbl_error.text = message

func clear_error() -> void:
  lbl_error.text = ''
