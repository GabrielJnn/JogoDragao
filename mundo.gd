extends Node3D

func _ready() -> void:
	_criar_ceu_bonito()
	_pintar_chao_de_grama()
	_criar_musica_ambiente()

func _criar_musica_ambiente() -> void:
	var musica = AudioStreamPlayer.new()
	musica.name = "MusicaAmbiente"
	var stream = load("res://Audio/scroll_003.ogg")
	if stream is AudioStreamOggVorbis:
		var s = stream.duplicate() as AudioStreamOggVorbis
		s.loop = true
		musica.stream = s
	else:
		musica.stream = stream
	musica.volume_db = -12.0  # Suave, para não sobrepor os efeitos do dragão
	add_child(musica)
	musica.play()

func _pintar_chao_de_grama() -> void:
	# Pinta qualquer CSGBox3D do mundo com textura de grama rica
	for filho in get_children():
		if filho is CSGBox3D:
			var material_grama = StandardMaterial3D.new()
			# Verde vibrante com variação de tom (simula grama real)
			material_grama.albedo_color = Color(0.18, 0.52, 0.12)
			material_grama.roughness = 0.9
			material_grama.metallic = 0.0
			# Expande o chão para 500x500 via escala do material UV
			material_grama.uv1_scale = Vector3(10.0, 10.0, 10.0)
			filho.material = material_grama
			# Escala o chão dinamicamente para 500x500
			filho.size = Vector3(500, 1, 500)

func _criar_ceu_bonito() -> void:
	# ── Sol (DirectionalLight3D) ─────────────────────────────────────────────
	var sol = DirectionalLight3D.new()
	sol.name = "Sol"
	sol.shadow_enabled = true
	sol.light_color = Color(1.0, 0.97, 0.88)   # Tom quente de luz solar
	sol.light_energy = 1.8                       # Sol mais brilhante
	sol.shadow_bias = 0.05
	sol.rotation_degrees = Vector3(-50, 30, 0)  # Posição alta, ângulo de tarde
	add_child(sol)

	# ── WorldEnvironment com céu procedural cinematográfico ─────────────────
	var ambiente = WorldEnvironment.new()
	ambiente.name = "CeuAmbiente"

	var material_ceu = ProceduralSkyMaterial.new()
	# Topo: azul profundo de altitude
	material_ceu.sky_top_color      = Color(0.05, 0.22, 0.72)
	# Horizonte: azul-celeste vibrante
	material_ceu.sky_horizon_color  = Color(0.52, 0.78, 1.00)
	# Terra (refletida no céu inferior): verde escuro
	material_ceu.ground_bottom_color   = Color(0.07, 0.20, 0.06)
	# Horizonte da terra: gradiente suave acinzentado
	material_ceu.ground_horizon_color  = Color(0.55, 0.72, 0.60)
	# Sol: grande e brilhante
	material_ceu.sun_angle_max      = 5.0
	material_ceu.sun_curve          = 0.08
	# Energia/brilho do céu
	material_ceu.energy_multiplier  = 1.3

	var ceu = Sky.new()
	ceu.sky_material = material_ceu

	var env = Environment.new()
	env.background_mode   = Environment.BG_SKY
	env.sky               = ceu
	env.background_energy_multiplier = 1.0

	# Luz ambiente vinda do céu (tom azulado suave nas sombras)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.7

	# Névoa volumétrica leve (dá profundidade ao horizonte)
	env.fog_enabled         = true
	env.fog_density         = 0.002
	env.fog_aerial_perspective = 0.3
	env.fog_light_color     = Color(0.7, 0.85, 1.0)
	env.fog_sun_scatter     = 0.3

	# Glow sutil (deixa o sol "explodir" de luz)
	env.glow_enabled        = true
	env.glow_intensity      = 0.6
	env.glow_bloom          = 0.12
	env.glow_blend_mode     = Environment.GLOW_BLEND_MODE_ADDITIVE

	# Ajuste de tonemap para visual cinematográfico
	env.tonemap_mode        = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure    = 1.1
	env.tonemap_white       = 6.0

	ambiente.environment = env
	add_child(ambiente)

var frames_espera = 0
func _process(delta: float) -> void:
	# Sistema manual: O usuário pode apertar P para tirar print no meio do jogo
	if Input.is_physical_key_pressed(KEY_P):
		_tirar_print()
		
	# Sistema automático da IA: Tira print e fecha se rodar com a tag --auto-print
	if "--auto-print" in OS.get_cmdline_args():
		frames_espera += 1
		if frames_espera == 20: # Espera uns frames para renderizar tudo
			_tirar_print()
			get_tree().quit()

func _tirar_print() -> void:
	var img = get_viewport().get_texture().get_image()
	img.save_png("res://screenshot.png")
	print("Screenshot salva em res://screenshot.png")
