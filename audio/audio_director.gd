class_name AudioDirector
extends Node

const MIX_RATE := 22050.0
const CUE_PROFILES := {
	"silence": {"frequency": 110.0, "harmony": 1.5, "pulse": 0.0, "ambience": 0.0},
	"title": {"frequency": 146.83, "harmony": 1.5, "pulse": 0.16, "ambience": 0.08},
	"valdoria": {"frequency": 164.81, "harmony": 1.25, "pulse": 0.22, "ambience": 0.12},
	"catacombs": {"frequency": 98.0, "harmony": 1.5, "pulse": 0.12, "ambience": 0.2},
	"eira": {"frequency": 123.47, "harmony": 1.333, "pulse": 0.09, "ambience": 0.24},
	"world": {"frequency": 130.81, "harmony": 1.5, "pulse": 0.14, "ambience": 0.14},
	"city": {"frequency": 174.61, "harmony": 1.25, "pulse": 0.2, "ambience": 0.12},
	"battle": {"frequency": 110.0, "harmony": 1.667, "pulse": 0.34, "ambience": 0.08},
	"victory": {"frequency": 196.0, "harmony": 1.5, "pulse": 0.18, "ambience": 0.1},
	"council": {"frequency": 146.83, "harmony": 1.5, "pulse": 0.1, "ambience": 0.16},
	"forge_bell": {"frequency": 110.0, "harmony": 2.0, "pulse": 0.24, "ambience": 0.11},
	"himno_del_leon": {"frequency": 164.81, "harmony": 1.5, "pulse": 0.18, "ambience": 0.1},
	"martillos_de_ceniza": {"frequency": 110.0, "harmony": 1.25, "pulse": 0.28, "ambience": 0.13},
	"mareas_de_cristal": {"frequency": 196.0, "harmony": 1.333, "pulse": 0.12, "ambience": 0.18},
	"nombres_bajo_las_hojas": {"frequency": 130.81, "harmony": 1.5, "pulse": 0.1, "ambience": 0.22},
	"phase10_story": {"frequency": 155.56, "harmony": 1.5, "pulse": 0.11, "ambience": 0.14},
}
const EVENT_PROFILES := {
	"ui_move": {"frequency": 660.0, "duration": 0.045, "gain": 0.13, "bus": "UI"},
	"ui_accept": {"frequency": 880.0, "duration": 0.075, "gain": 0.16, "bus": "UI"},
	"ui_cancel": {"frequency": 330.0, "duration": 0.08, "gain": 0.14, "bus": "UI"},
	"dialogue_advance": {"frequency": 520.0, "duration": 0.035, "gain": 0.08, "bus": "UI"},
	"interaction": {"frequency": 740.0, "duration": 0.1, "gain": 0.14, "bus": "SFX"},
	"battle_impact": {"frequency": 92.0, "duration": 0.18, "gain": 0.28, "bus": "SFX"},
	"weakness": {"frequency": 1046.5, "duration": 0.16, "gain": 0.2, "bus": "SFX"},
	"heal": {"frequency": 784.0, "duration": 0.24, "gain": 0.16, "bus": "SFX"},
	"save": {"frequency": 987.77, "duration": 0.14, "gain": 0.11, "bus": "UI"},
}

var current_cue := "silence"
var target_cue := "silence"
var current_frequency := 110.0
var target_frequency := 110.0
var transition_gain := 0.0
var music_phase := 0.0
var harmony_phase := 0.0
var ambience_phase := 0.0
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var music_playback: AudioStreamGeneratorPlayback
var ambience_playback: AudioStreamGeneratorPlayback

func _ready() -> void:
	ensure_buses()
	if DisplayServer.get_name() != "headless":
		music_player = create_generator_player("MusicLayer", "Music")
		ambience_player = create_generator_player("AmbienceLayer", "Ambience")
		music_playback = music_player.get_stream_playback() as AudioStreamGeneratorPlayback
		ambience_playback = ambience_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(delta: float) -> void:
	current_frequency = lerpf(current_frequency, target_frequency, 1.0 - exp(-delta * 2.8))
	transition_gain = move_toward(transition_gain, 1.0 if target_cue != "silence" else 0.0, delta * 1.8)
	if absf(current_frequency - target_frequency) < 0.05:
		current_cue = target_cue
	fill_music()
	fill_ambience()

func transition_to(cue_id: String) -> void:
	var safe_cue := cue_id if CUE_PROFILES.has(cue_id) else "silence"
	if safe_cue == target_cue:
		return
	target_cue = safe_cue
	target_frequency = float((CUE_PROFILES[safe_cue] as Dictionary)["frequency"])

func sync_context(game_state: String, city_id: String, dungeon_id: String, directed_cue: String = "", city_cue: String = "") -> void:
	transition_to(cue_for_context(game_state, city_id, dungeon_id, directed_cue, city_cue))

static func cue_for_context(game_state: String, city_id: String = "", dungeon_id: String = "", directed_cue: String = "", city_cue: String = "") -> String:
	if not directed_cue.is_empty() and CUE_PROFILES.has(directed_cue):
		return directed_cue
	match game_state:
		"title", "settings", "save_menu", "load_menu": return "title"
		"valdoria_explore": return "valdoria"
		"dungeon": return "catacombs"
		"dungeon_crawl": return "eira" if dungeon_id == "eira_ruins" else "catacombs"
		"world_map", "landmark", "explore": return "world"
		"city": return city_cue if CUE_PROFILES.has(city_cue) else "city"
		"battle": return "battle"
		"victory": return "victory"
	return "silence"

func play_event(event_id: String) -> void:
	if DisplayServer.get_name() == "headless" or not EVENT_PROFILES.has(event_id):
		return
	var profile: Dictionary = EVENT_PROFILES[event_id]
	var player := AudioStreamPlayer.new()
	player.name = "Event_" + event_id
	player.bus = str(profile["bus"])
	player.stream = synthesize_event(event_id)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

static func synthesize_event(event_id: String) -> AudioStreamWAV:
	var profile: Dictionary = EVENT_PROFILES.get(event_id, EVENT_PROFILES["ui_move"])
	var duration := float(profile["duration"])
	var frequency := float(profile["frequency"])
	var gain := float(profile["gain"])
	var frame_count := maxi(1, int(MIX_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in frame_count:
		var progress := float(frame) / float(frame_count)
		var envelope := sin(progress * PI) * exp(-progress * 2.4)
		var overtone := sin(TAU * frequency * 2.01 * float(frame) / MIX_RATE) * 0.22
		var sample := clampf((sin(TAU * frequency * float(frame) / MIX_RATE) + overtone) * envelope * gain, -1.0, 1.0)
		var encoded := int(round(sample * 32767.0))
		bytes[frame * 2] = encoded & 0xff
		bytes[frame * 2 + 1] = (encoded >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(MIX_RATE)
	stream.stereo = false
	stream.data = bytes
	return stream

static func validate() -> Array[String]:
	var errors: Array[String] = []
	for required_cue in ["title", "valdoria", "catacombs", "eira", "world", "city", "battle", "victory"]:
		if not CUE_PROFILES.has(required_cue):
			errors.append("Falta el cue %s." % required_cue)
	for cue_id in CUE_PROFILES:
		var profile: Dictionary = CUE_PROFILES[cue_id]
		if float(profile.get("frequency", 0.0)) <= 0.0 or float(profile.get("harmony", 0.0)) <= 0.0:
			errors.append("Cue inválido: %s." % cue_id)
	for event_id in EVENT_PROFILES:
		var event: Dictionary = EVENT_PROFILES[event_id]
		if float(event.get("duration", 0.0)) <= 0.0 or str(event.get("bus", "")) not in ["SFX", "UI"]:
			errors.append("Evento inválido: %s." % event_id)
	return errors

func ensure_buses() -> void:
	for bus_name in ["Music", "Ambience", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func create_generator_player(node_name: String, bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = bus_name
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.3
	player.stream = generator
	add_child(player)
	player.play()
	return player

func fill_music() -> void:
	if music_playback == null:
		return
	var profile: Dictionary = CUE_PROFILES.get(target_cue, CUE_PROFILES["silence"])
	var frames := mini(music_playback.get_frames_available(), 1024)
	for frame in frames:
		var pulse := 0.72 + sin(ambience_phase * float(profile["pulse"]) + 0.4) * 0.12
		var sample := (sin(music_phase) + sin(harmony_phase) * 0.31) * 0.055 * transition_gain * pulse
		music_playback.push_frame(Vector2(sample, sample))
		music_phase = fmod(music_phase + TAU * current_frequency / MIX_RATE, TAU)
		harmony_phase = fmod(harmony_phase + TAU * current_frequency * float(profile["harmony"]) / MIX_RATE, TAU)

func fill_ambience() -> void:
	if ambience_playback == null:
		return
	var profile: Dictionary = CUE_PROFILES.get(target_cue, CUE_PROFILES["silence"])
	var frames := mini(ambience_playback.get_frames_available(), 1024)
	for frame in frames:
		var movement := sin(ambience_phase) * 0.7 + sin(ambience_phase * 0.37) * 0.3
		var sample := movement * float(profile["ambience"]) * 0.06 * transition_gain
		ambience_playback.push_frame(Vector2(sample, sample))
		ambience_phase = fmod(ambience_phase + TAU * (0.33 + current_frequency / 900.0) / MIX_RATE, TAU)
