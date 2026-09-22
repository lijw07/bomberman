extends Node

const SFX_DIR := "res://assets/audio/sfx/%s.wav"
const MUSIC_DIR := "res://assets/audio/music/%s.ogg"
const POOL_SIZE := 8

var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var sfx_cache: Dictionary = {}
var current_music := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)
	music_player = AudioStreamPlayer.new()
	music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	music_player.volume_db = -6.0
	add_child(music_player)


func play_sfx(sfx_name: String) -> void:
	var stream: AudioStream = sfx_cache.get(sfx_name)
	if stream == null:
		stream = load(SFX_DIR % sfx_name)
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		sfx_cache[sfx_name] = stream
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	sfx_players[0].stream = stream
	sfx_players[0].play()


func play_music(track: String, loop := true) -> void:
	if current_music == track and music_player.playing:
		return
	current_music = track
	var stream: AudioStreamOggVorbis = load(MUSIC_DIR % track)
	stream.loop = loop
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	current_music = ""
	music_player.stop()


func silence() -> void:
	stop_music()
	for player in sfx_players:
		player.stop()
