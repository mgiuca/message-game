## Internal class used by MusicFader.
class_name MusicFaderPlayer
extends AudioStreamPlayer

enum State {
  NULL,  # Stream must be null.
  FADING_IN, # fade_tween must be non-null.
  FULL_VOLUME,
  FADING_OUT, # fade_tween must be non-null.
}

var current_fade_time : float
var fade_tween : Tween
var state : State

## Whether this is in one of the "active" states (fading in, or full volume).
var is_active : bool:
  get():
    return state in [State.FADING_IN, State.FULL_VOLUME]

## The volume as a percentage of the assigned full volume.[br]
## [br]
## This is not the same as [member volume_level]; this is essentially the
## percentage progress of the fader, except that a fade out takes this in
## reverse from 1.0 to 0.0.
var volume_percent : float:
  get():
    match state:
      State.FADING_IN:
        return fade_tween.get_total_elapsed_time() / current_fade_time
      State.FULL_VOLUME:
        return 1.0
      State.FADING_OUT:
        return 1 - (fade_tween.get_total_elapsed_time() / current_fade_time)
    return 0.0

func _ready() -> void:
  AudioManager.audio_volume_changed.connect(_on_audio_volume_changed)
  _on_audio_volume_changed(AudioManager.AudioType.MUSIC, AudioManager.music_volume)

## Plays the stream, optionally fading in.
func fade_in(fade_time: float, volume_db_: float = 0.0,
             from_position: float = 0.0, from_silent: bool = false) -> void:
  if fade_tween != null:
    fade_tween.kill()

  if fade_time == 0.0:
    volume_db = volume_db_
    state = State.FULL_VOLUME
    current_fade_time = 0.0

  else:
    if from_silent:
      volume_db = -40
    fade_tween = create_tween()
    fade_tween.set_ignore_time_scale(true)
    fade_tween.tween_property(self, 'volume_db', volume_db_, fade_time)
    fade_tween.tween_callback(func() -> void:
      state = State.FULL_VOLUME)
    state = State.FADING_IN
    current_fade_time = fade_time

  # We don't play if the music is completely muted. If the music is unmuted,
  # MusicFader handles it.
  if not playing and AudioManager.music_volume > 0:
    play(from_position)

func fade_out(fade_time: float) -> void:
  if fade_tween != null:
    fade_tween.kill()

  if fade_time == 0.0:
    silence_instantly()
    return

  fade_tween = create_tween()
  fade_tween.set_ignore_time_scale(true)
  fade_tween.tween_property(self, 'volume_db', -40.0, fade_time)
  fade_tween.tween_callback(silence_instantly)
  state = State.FADING_OUT
  current_fade_time = fade_time

func silence_instantly() -> void:
  stop()
  stream = null
  state = State.NULL
  current_fade_time = 0.0

func _on_audio_volume_changed(type: AudioManager.AudioType, volume: float) -> void:
  # Start and stop the music if the volume is at zero.
  if type != AudioManager.AudioType.MUSIC:
    return
  if volume > 0:
    # Resume, but only if we weren't already fading out. We restart from the
    # beginning.
    if is_active:
      # Check before assigning, to avoid restarting already-playing music.
      if not playing:
        playing = true
  else:
    playing = false
