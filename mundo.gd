extends Node3D

func _ready() -> void:
	_criar_iluminacao_basica()
	_pintar_chao_de_grama()

func _pintar_chao_de_grama() -> void:
	# Pinta qualquer CSGBox3D do mundo com a cor verde (Grama)
	for filho in get_children():
		if filho is CSGBox3D:
			var material_grama = StandardMaterial3D.new()
			material_grama.albedo_color = Color(0.15, 0.55, 0.15) # Verde estilo grama
			filho.material = material_grama

func _criar_iluminacao_basica() -> void:
	# 1. Adiciona o Sol (Luz Direcional)
	var sol = DirectionalLight3D.new()
	sol.name = "Sol"
	sol.shadow_enabled = true
	# Rotaciona a luz para ficar inclinada (parecendo luz do dia/tarde)
	sol.rotation_degrees = Vector3(-45, 45, 0)
	add_child(sol)
	
	# 2. Adiciona o Céu e a Luz Ambiente (WorldEnvironment)
	var ambiente = WorldEnvironment.new()
	ambiente.name = "CeuAmbiente"
	
	var material_ceu = ProceduralSkyMaterial.new()
	# Cores do céu configuradas explicitamente (azul do dia)
	material_ceu.sky_top_color = Color(0.13, 0.43, 0.84)
	material_ceu.sky_horizon_color = Color(0.63, 0.79, 0.95)
	material_ceu.ground_bottom_color = Color(0.12, 0.28, 0.18)
	material_ceu.ground_horizon_color = Color(0.63, 0.79, 0.95)
	material_ceu.sun_angle_max = 30.0
	
	var ceu = Sky.new()
	ceu.sky_material = material_ceu
	
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
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
