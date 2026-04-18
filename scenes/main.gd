# Main scene: Root node of the game, embeds all other scenes.
#
# This is so we can smoothly transition scenes with fades, keep audio, etc.

class_name Main
extends Node

## The currently loaded scene.
@export var current_scene : PackedScene

## File path of scene to load when Main starts. Overrides `Main.current_scene`.
static var override_startup_scene : String

# The node holding the currently loaded scene.
var current_scene_node : Node

@export_group('Settings')

## Starts the game in fullscreen mode.
@export var start_fullscreen : bool = true

## Default volume of the music bus.
@export var music_volume : float = 1.0

# NOTE: This is separate to "music_volume" which controls the volume of the
# music bus. This controls the volume of the music player in dB, which can
# vary from one track to another.
const DEFAULT_MUSIC_VOLUME : float = -10.0

## Default volume of the sound effects bus.
@export var sound_effects_volume : float = 1.0

@onready var lbl_version: Label = %LblVersion
@onready var lbl_git_hash: Label = %LblGitHash
@onready var lbl_godot_version: Label = %LblGodotVersion

@onready var music_fader : MusicFader = $MusicFader
@onready var scrim_layer : CanvasLayer = $ScrimLayer
@onready var fade_scrim : ColorRect = $ScrimLayer/FadeScrim

# Seconds to complete fade-out or fade-in (double it for the full transition
# time).
const FADE_TIME : float = 0.2

var scrim_fade_tween : Tween

func _ready() -> void:
  if OS.has_feature('web'):
    # Web can't start in fullscreen (but it can go fullscreen later in response
    # to a user gesture).
    start_fullscreen = false

  Globals.init_settings(start_fullscreen, music_volume, sound_effects_volume)
  Globals.main = self
  if override_startup_scene != '':
    # This will be set if another scene was loaded by the editor.
    change_scene_to_file(override_startup_scene)
  else:
    change_scene_to_packed(current_scene)

  lbl_version.text = get_version_number()
  lbl_git_hash.text = get_git_hash()
  lbl_godot_version.text = get_godot_version()

func get_version_number() -> String:
  var ver : String = ProjectSettings.get_setting('application/config/version')
  var is_debug : bool = OS.is_debug_build()
  var is_debug_str : String = ' dbg' if is_debug else ''
  return ver + is_debug_str

func get_git_hash() -> String:
  var git_status : GitStatus.Info = GitStatus.get_status()
  var git_hash : String
  if git_status.hash == '':
    git_hash = '(no git)'
  else:
    git_hash = git_status.hash.substr(0, 8)
    if git_status.modified:
      git_hash += '+changes'
  return git_hash

func get_godot_version() -> String:
  var version_info := Engine.get_version_info()
  # Make a custom string (instead of using version_info.string) for brevity.
  var patch_str : String = \
    ('.%d' % version_info.patch) if version_info.patch != 0 else ''
  var status_str : String = \
    ('-' + version_info.status) if version_info.status != 'stable' else ''
  return 'godot %d.%d%s%s' % [version_info.major, version_info.minor,
                              patch_str, status_str]

func _unhandled_input(event: InputEvent) -> void:
  # Meta/UI inputs.
  if event.is_action_pressed('toggle_fullscreen'):
    Globals.fullscreen = not Globals.fullscreen

## Ensures that Main is the current top-level scene (which it always should be,
## but the use of the editor's F6 key to load another scene can cause some other
## scene to load).
##
## If it is not, switches the top-level scene to main, then loads the scene
## belonging to the given node. Returns true if this happened.
##
## Should be used by the _ready function of top-level scenes, passing self.
static func ensure_main_and_load_file(scene_node: Node) -> bool:
  if scene_node.get_tree().current_scene is Main:
    return false

  override_startup_scene = scene_node.scene_file_path
  scene_node.get_tree().call_deferred('change_scene_to_file',
                                      'res://scenes/main.tscn')
  return true

func change_scene_to_file(path: String) -> Error:
  if current_scene_node != null:
    await screen_fade_out()
    remove_child(current_scene_node)
    current_scene_node.queue_free()
    # Wait a frame, to ensure we completely fade out before we block the main
    # thread.
    await get_tree().process_frame

  var scene := load(path) as PackedScene
  if scene == null:
    # Either it couldn't be loaded, or the resource was not a PackedScene.
    return ERR_CANT_OPEN
  change_scene_to_packed_post_fadeout(scene)
  return OK

func change_scene_to_packed(packed_scene: PackedScene) -> void:
  if current_scene_node != null:
    await screen_fade_out()
    remove_child(current_scene_node)
    current_scene_node.queue_free()
    # Wait a frame, to ensure we completely fade out before we block the main
    # thread.
    await get_tree().process_frame

  change_scene_to_packed_post_fadeout(packed_scene)

func change_scene_to_packed_post_fadeout(packed_scene: PackedScene) -> void:
  var node := packed_scene.instantiate()
  current_scene = packed_scene
  current_scene_node = node
  add_child(node)

  # Reset the engine time scale (which could have been changed by a level).
  Engine.time_scale = 1.0

  # Wait two frames, so that the tween is created after any intensive loading
  # takes place. Without this, the tween will actually start ticking up at the
  # start of the load (even though it hasn't been created yet) due to the way
  # Godot calculates the start time of the tween. Even waiting one frame isn't
  # enough.
  await get_tree().process_frame
  await get_tree().process_frame
  await screen_fade_in()

## Fade out the entire game screen to black. Will stay black until [method
## fade_in] is called. Returns a signal that completes when the fade finishes.
func screen_fade_out(duration: float = FADE_TIME) -> Signal:
  scrim_layer.show()
  if scrim_fade_tween:
    scrim_fade_tween.kill()
  scrim_fade_tween = create_tween()
  scrim_fade_tween.set_ignore_time_scale(true)
  scrim_fade_tween.tween_property(fade_scrim, 'modulate', Color.WHITE, duration)
  return scrim_fade_tween.finished

## Fade in the entire game screen (after [method fade_out]). Returns a signal
## that completes when the fade finishes.
func screen_fade_in(duration: float = FADE_TIME) -> void:
  if scrim_fade_tween:
    scrim_fade_tween.kill()
  scrim_fade_tween = create_tween()
  scrim_fade_tween.set_ignore_time_scale(true)
  scrim_fade_tween.tween_property(fade_scrim, 'modulate', Color('ffffff00'), duration)
  await scrim_fade_tween.finished
  scrim_layer.hide()

func reload_current_scene() -> void:
  change_scene_to_packed(current_scene)

## Crossfade to a new music track.
func change_music(stream: AudioStream, from_position: float = 0.0,
                 fade_in: bool = false, volume_db: float = DEFAULT_MUSIC_VOLUME) -> void:
  music_fader.play_stream(stream, from_position, fade_in, volume_db)

func stop_music() -> void:
  change_music(null)
