extends Node
var clips = {}
var pool: Array[AudioStreamPlayer2D] = []
var cursor = 0
var music: AudioStreamPlayer

func _exit_tree():
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for p in pool:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	clips.clear()

func _ready():
	for name_ in ["SFX", "Music"]:
		if AudioServer.get_bus_index(name_) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, name_)
	if DisplayServer.get_name()=="headless": return
	var types = ["pistol","smg","rifle","shotgun","dmr","reload","step","pickup","wood","metal","hit","heal","zone","grenade","melee"]
	for i in types.size(): clips[types[i]] = synth(i)
	for i in 32:
		var p = AudioStreamPlayer2D.new()
		p.bus = "SFX"
		p.max_distance = 1000
		p.attenuation = 1.7
		add_child(p)
		pool.append(p)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.stream = synth(20)
	music.volume_db = -17
	add_child(music)
	music.play()

func play(id: String, pos: Vector2, gain: float = 0.0):
	if pool.is_empty(): return
	var p = pool[cursor]
	cursor = (cursor + 1) % pool.size()
	p.position = pos
	p.stream = clips.get(id, clips.hit)
	p.volume_db = gain
	p.pitch_scale = randf_range(0.94,1.06)
	p.play()

func synth(kind: int) -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.18
	if kind == 3 or kind == 4 or kind == 13: duration = 0.45
	if kind == 12: duration = 0.8
	if kind == 20: duration = 8.0
	var bytes = PackedByteArray()
	bytes.resize(int(rate * duration) * 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = 7183 + kind
	var filtered = 0.0
	for i in int(rate * duration):
		var t = float(i) / rate
		var envelope = exp(-t * (22.0 if kind < 5 else 14.0))
		filtered = lerpf(filtered, rng.randf_range(-1,1), 0.35)
		var value = 0.0
		if kind < 5:
			value = (filtered * 1.2 + sin(t * TAU * (80 + kind * 21) * exp(-t * 8)) * 0.5) * envelope
		elif kind == 20:
			value = (sin(t*TAU*55) * 0.12 + sin(t*TAU*82.5) * 0.06 + sin(t*TAU*110) * 0.04) * (0.6 + 0.4*sin(t*TAU/8))
		elif kind in [7,11,12]:
			value = sin(t*TAU*(500 + kind*30 + floor(t*8)*100))*envelope*0.35
		elif kind == 13:
			value = (filtered * 1.8 + sin(t*TAU*48)*0.7)*exp(-t*9)
		else:
			value = (filtered * 0.8 + sin(t*TAU*(150+kind*38))*0.15)*envelope
		bytes.encode_s16(i*2, int(clampf(value,-1,1)*26000))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	if kind == 20:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(rate * duration)
	return stream
