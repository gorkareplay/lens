class_name VoiceSynth
extends Node

const RATE := 22050
const DURATION := 0.13
const VARIANTS := 4

# character of the voice synth
const BASE_PITCH_HZ := 92.0
const GRAVEL := 0.55
const BREATH := 0.10
const WARMTH := 0.55
const VOLUME_DB := -9.0

const VOWELS := {
	"a": Vector3(730, 1090, 2440),
	"e": Vector3(530, 1840, 2480),
	"i": Vector3(270, 2290, 3010),
	"o": Vector3(570, 840, 2410),
	"u": Vector3(300, 870, 2240),
}

var _vowel_streams: Dictionary = {}
var _last_variant: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0

func _ready() -> void:
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = VOLUME_DB
		add_child(p)
		_players.append(p)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for v in VOWELS:
		var list: Array[AudioStreamWAV] = []
		for i in VARIANTS:
			list.append(_synth_vowel(VOWELS[v], rng))
		_vowel_streams[v] = list

func play_for(ch: String) -> void:
	var c := ch.to_lower()
	if _vowel_streams.has(c):
		var list: Array = _vowel_streams[c]
		var idx: int = randi() % list.size()
		if idx == _last_variant.get(c, -1):
			idx = (idx + 1) % list.size()
		_last_variant[c] = idx
		_play(list[idx], randf_range(0.93, 1.07), 0.0)

func _play(s: AudioStream, pitch: float, extra_db: float) -> void:
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = VOLUME_DB + extra_db
	p.play()

func _resonator(freq: float, bw: float) -> Vector3:
	var r: float = exp(-PI * bw / RATE)
	return Vector3(1.0 - r, 2.0 * r * cos(TAU * freq / RATE), -r * r)

func _synth_vowel(f: Vector3, rng: RandomNumberGenerator) -> AudioStreamWAV:
	var n: int = int(RATE * DURATION)
	var out := PackedFloat32Array()
	out.resize(n)

	var pitch: float = BASE_PITCH_HZ * rng.randf_range(0.92, 1.12)
	var drift: float = rng.randf_range(-0.12, 0.03)
	var vib_rate: float = rng.randf_range(4.5, 6.5)
	var form_start := Vector3(
		rng.randf_range(0.88, 1.12),
		rng.randf_range(0.88, 1.12),
		rng.randf_range(0.88, 1.12))

	var phase: float = 0.0
	var pulse_amp: float = 1.0
	var pulse_count: int = 0
	var prev_g: float = 0.0
	var y1 := Vector3.ZERO
	var y2 := Vector3.ZERO
	var c1 := Vector3.ZERO
	var c2 := Vector3.ZERO
	var c3 := Vector3.ZERO

	for i in n:
		var t: float = float(i) / n
		var tsec: float = float(i) / RATE

		if i % 32 == 0:
			var m: Vector3 = form_start.lerp(Vector3.ONE, minf(t * 2.5, 1.0))
			c1 = _resonator(f.x * m.x, 90.0)
			c2 = _resonator(f.y * m.y, 110.0)
			c3 = _resonator(f.z * m.z, 170.0)

		var f0: float = pitch * (1.0 + drift * t) \
			* (1.0 + 0.012 * sin(TAU * vib_rate * tsec))
		phase += f0 / RATE
		if phase >= 1.0:
			phase -= 1.0
			pulse_count += 1
			phase = maxf(phase + rng.randf_range(-0.03, 0.03) * GRAVEL, 0.0)
			pulse_amp = 1.0 + rng.randf_range(-0.15, 0.15) * GRAVEL
			if pulse_count % 2 == 1:
				pulse_amp *= lerpf(1.0, 0.45, GRAVEL)

		var g: float = 0.0
		if phase < 0.6:
			var sn: float = sin(PI * phase / 0.6)
			g = sn * sn
		var src: float = (g - prev_g) * (RATE / f0) * pulse_amp
		prev_g = g
		src += rng.randf_range(-1.0, 1.0) * BREATH * 4.0

		var o := Vector3(
			c1.x * src + c1.y * y1.x + c1.z * y2.x,
			c2.x * src + c2.y * y1.y + c2.z * y2.y,
			c3.x * src + c3.y * y1.z + c3.z * y2.z)
		y2 = y1
		y1 = o
		var s: float = o.x + 0.55 * o.y + 0.25 * o.z

		var env: float = minf(1.0, minf(tsec / 0.008, (DURATION - tsec) / 0.045))
		env *= 0.75 + 0.25 * sin(PI * t)
		out[i] = s * maxf(env, 0.0)

	var lp: float = 0.0
	for i in n:
		lp = lerpf(lp, out[i], WARMTH)
		out[i] = lp

	return _to_wav(out, 0.75)

func _to_wav(samples: PackedFloat32Array, level: float) -> AudioStreamWAV:
	var peak: float = 0.001
	for v in samples:
		peak = maxf(peak, absf(v))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(samples[i] / peak * level * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
