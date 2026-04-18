## [AudioStreamPlayer]-like interface that switches music by cross-fading.
class_name MusicFader
extends Node

## The amount of time it takes to transition from one music to another.
@export_range(0.0, 10.0, 0.1, 'or_greater') var crossfade_time : float = 1.0

@onready var player1 : MusicFaderPlayer = $Player1
@onready var player2 : MusicFaderPlayer = $Player2

# Fader player invariant:
# If one stream is FADING_IN or FULL_VOLUME, the other must be NULL or
# FADING_OUT.

# TODO: Allow individual choice of bus per stream. Complicated by the logic
# that stops and resumes the player when the Music bus is muted.

## Start playing an audio stream. Cross-fade from whatever is currently playing
## to this. [param stream] may be null, which fades out whatever is playing to
## silence.[br]
## [br]
## If [param fade_in] is [code]true[/code], the new stream is faded in. If it is
## [code]false[/code] (default), the new stream starts at full volume, while
## the old one fades out.
## [br]
## If the given stream is already playing (or fading out as the
## second-most-recent stream), it will fade back up and resume instead of
## starting again, and in this case, [param from_position] and [param volume_db]
## will be ignored.[br]
## [br]
## If the player is in the middle of a fade, whichever stream is currently
## the quietest will be cut short abruptly, to avoid having three streams
## playing simultaneously.
func play_stream(stream: AudioStream, from_position: float = 0.0,
                 fade_in: bool = false, volume_db: float = 0.0) -> void:
  if stream == null:
    fade_out()
    return

  # Check if the given stream is already playing.
  if player1.stream == stream:
    assert(player1.state != MusicFaderPlayer.State.NULL)
    if player1.state == MusicFaderPlayer.State.FADING_OUT:
      # Bring it back up.
      player1.fade_in(crossfade_time, volume_db)
    # Else: It's already playing or fading in, so do nothing.
    if player2.is_active:
      player2.fade_out(crossfade_time)
    return
  elif player2.stream == stream:
    assert(player2.state != MusicFaderPlayer.State.NULL)
    if player2.state == MusicFaderPlayer.State.FADING_OUT:
      # Bring it back up.
      player2.fade_in(crossfade_time, volume_db)
    # Else: It's already playing or fading in, so do nothing.
    if player1.is_active:
      player1.fade_out(crossfade_time)
    return

  # Try to find an available player.
  var chosen_player := _make_player_available()
  var other_player := _get_other_player(chosen_player)
  chosen_player.stream = stream
  var fade_in_time := crossfade_time if fade_in else 0.0
  chosen_player.fade_in(fade_in_time, volume_db, from_position, true)
  if other_player.is_active:
    other_player.fade_out(crossfade_time)

## Fades out the currently playing stream.
func fade_out() -> void:
  # Just fade out both players (only one can be active anyway).
  if player1.is_active:
    player1.fade_out(crossfade_time)
  if player2.is_active:
    player2.fade_out(crossfade_time)

## Gets an available MusicFaderPlayer. If none is available, makes one available
## by instantly silencing it. The returned player is guaranteed to have state
## null.
func _make_player_available() -> MusicFaderPlayer:
  if player1.state == MusicFaderPlayer.State.NULL:
    return player1
  if player2.state == MusicFaderPlayer.State.NULL:
    return player2
  if player1.volume_percent < player2.volume_percent:
    player1.silence_instantly()
    return player1
  else:
    player2.silence_instantly()
    return player2

func _get_other_player(p: MusicFaderPlayer) -> MusicFaderPlayer:
  if p == player1:
    return player2
  else:
    return player1
