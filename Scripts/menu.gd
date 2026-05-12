extends Control

# ── Referências ───────────────────────────────────────────────────────────────
var _sfx_hover: AudioStreamPlayer
var _sfx_confirmar: AudioStreamPlayer
var _bg: ColorRect
var _titulo: Label
var _wrap_titulo: Control
var _time: float = 0.0
var _frames: int = 0  # Para sistema --auto-print

# ── _ready ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_criar_fundo()
	_criar_painel_central()
	_criar_audio()

# ── _process: anima o fundo e o título ───────────────────────────────────────
func _process(delta: float) -> void:
	_time += delta
	# Sistema --auto-print (igual ao mundo.gd)
	if "--auto-print" in OS.get_cmdline_args():
		_frames += 1
		if _frames == 20:
			var img = get_viewport().get_texture().get_image()
			img.save_png("res://screenshot.png")
			print("Screenshot salva em res://screenshot.png")
			get_tree().quit()
	# Pulsa levemente a cor de fundo (efeito noturno vivo)
	if _bg:
		var t = (sin(_time * 0.4) + 1.0) * 0.5
		_bg.color = Color(
			lerp(0.02, 0.06, t),
			lerp(0.01, 0.04, t),
			lerp(0.12, 0.20, t)
		)
	# Flutua o wrapper do título (sem quebrar o layout do VBoxContainer)
	if _wrap_titulo:
		_wrap_titulo.position.y = sin(_time * 1.8) * 6.0

# ── Cria o fundo escuro com estrelas ─────────────────────────────────────────
func _criar_fundo() -> void:
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.03, 0.01, 0.14)
	add_child(_bg)

	# Partículas de estrelas fixas
	var rng = RandomNumberGenerator.new()
	rng.seed = 1337
	for i in 120:
		var star = ColorRect.new()
		var sz = rng.randf_range(1.0, 3.5)
		star.size = Vector2(sz, sz)
		star.position = Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 1080))
		var brilho = rng.randf_range(0.4, 1.0)
		star.color = Color(brilho, brilho, brilho + 0.1, brilho)
		_bg.add_child(star)

# ── Cria o painel central com título e botões ─────────────────────────────────
func _criar_painel_central() -> void:
	# Painel escuro translúcido (glassmorphism)
	var painel = Panel.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	painel.custom_minimum_size = Vector2(500, 440)
	painel.offset_left   = -250
	painel.offset_top    = -220
	painel.offset_right  =  250
	painel.offset_bottom =  220
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.04, 0.18, 0.82)
	sb.border_color = Color(0.4, 0.6, 1.0, 0.35)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left     = 20
	sb.corner_radius_top_right    = 20
	sb.corner_radius_bottom_left  = 20
	sb.corner_radius_bottom_right = 20
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size  = 16
	painel.add_theme_stylebox_override("panel", sb)
	add_child(painel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	vbox.offset_left   = 30
	vbox.offset_right  = -30
	vbox.offset_top    = 20
	vbox.offset_bottom = -20
	painel.add_child(vbox)

	# Wrapper para flutuar o emoji e o título juntos sem quebrar o layout
	_wrap_titulo = Control.new()
	_wrap_titulo.custom_minimum_size = Vector2(0, 140)
	vbox.add_child(_wrap_titulo)

	# Container interno para alinhar o emoji e o título
	var title_box = VBoxContainer.new()
	title_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.add_theme_constant_override("separation", 5)
	_wrap_titulo.add_child(title_box)

	# Emoji dragão grande
	var emoji = Label.new()
	emoji.text = "🐉"
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var em_set = LabelSettings.new()
	em_set.font_size = 64
	emoji.label_settings = em_set
	title_box.add_child(emoji)

	# Título principal
	var titulo = Label.new()
	titulo.text = "JOGO DO DRAGÃO"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var t_set = LabelSettings.new()
	t_set.font_size = 44
	t_set.font_color = Color(1.0, 0.78, 0.15)
	t_set.outline_size = 5
	t_set.outline_color = Color(0.7, 0.25, 0.0)
	t_set.shadow_size = 10
	t_set.shadow_color = Color(0, 0, 0, 0.9)
	t_set.shadow_offset = Vector2(3, 4)
	titulo.label_settings = t_set
	title_box.add_child(titulo)

	# Subtítulo
	var sub = Label.new()
	sub.text = "Voe pelos céus • Explore o mundo"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var s_set = LabelSettings.new()
	s_set.font_size = 16
	s_set.font_color = Color(0.65, 0.82, 1.0, 0.85)
	sub.label_settings = s_set
	vbox.add_child(sub)

	# Separador
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 12)
	sep.add_theme_color_override("color", Color(0.4, 0.6, 1.0, 0.3))
	vbox.add_child(sep)

	# Controles (dica rápida)
	var dica = Label.new()
	dica.text = "WASD: mover  •  ESPAÇO: voar"
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var d_set = LabelSettings.new()
	d_set.font_size = 13
	d_set.font_color = Color(0.5, 0.7, 0.9, 0.65)
	dica.label_settings = d_set
	vbox.add_child(dica)

	# Botão JOGAR
	var btn_jogar = _criar_botao("⚔   JOGAR", Color(0.15, 0.55, 1.0), Color(0.1, 0.35, 0.85))
	btn_jogar.pressed.connect(_on_jogar)
	btn_jogar.mouse_entered.connect(func(): if _sfx_hover: _sfx_hover.play())
	vbox.add_child(btn_jogar)

	# Botão SAIR
	var btn_sair = _criar_botao("✖   SAIR", Color(0.65, 0.12, 0.12), Color(0.45, 0.07, 0.07))
	btn_sair.pressed.connect(_on_sair)
	btn_sair.mouse_entered.connect(func(): if _sfx_hover: _sfx_hover.play())
	vbox.add_child(btn_sair)

# ── Fábrica de botão estilizado ───────────────────────────────────────────────
func _criar_botao(texto: String, cor: Color, cor_hover: Color) -> Button:
	var btn = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(0, 56)

	var normal = StyleBoxFlat.new()
	normal.bg_color = cor.darkened(0.3)
	normal.border_color = cor
	normal.set_border_width_all(2)
	normal.corner_radius_top_left     = 12
	normal.corner_radius_top_right    = 12
	normal.corner_radius_bottom_left  = 12
	normal.corner_radius_bottom_right = 12
	normal.set_content_margin_all(12)

	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = cor_hover
	hover.border_color = cor.lightened(0.3)
	hover.shadow_color = cor
	hover.shadow_size  = 8

	var pressed_sb = normal.duplicate() as StyleBoxFlat
	pressed_sb.bg_color = cor.darkened(0.5)

	btn.add_theme_stylebox_override("normal",   normal)
	btn.add_theme_stylebox_override("hover",    hover)
	btn.add_theme_stylebox_override("pressed",  pressed_sb)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 22)
	return btn

# ── Áudio do menu ─────────────────────────────────────────────────────────────
func _criar_audio() -> void:
	_sfx_hover = AudioStreamPlayer.new()
	_sfx_hover.stream = load("res://Audio/click_001.ogg")
	_sfx_hover.volume_db = -6.0
	add_child(_sfx_hover)

	_sfx_confirmar = AudioStreamPlayer.new()
	_sfx_confirmar.stream = load("res://Audio/confirmation_001.ogg")
	_sfx_confirmar.volume_db = -2.0
	add_child(_sfx_confirmar)

# ── Ações dos botões ─────────────────────────────────────────────────────────
func _on_jogar() -> void:
	if _sfx_confirmar:
		_sfx_confirmar.play()
		await get_tree().create_timer(0.45).timeout
	get_tree().change_scene_to_file("res://Scenes/mundo.tscn")

func _on_sair() -> void:
	if _sfx_hover:
		_sfx_hover.play()
		await get_tree().create_timer(0.2).timeout
	get_tree().quit()
