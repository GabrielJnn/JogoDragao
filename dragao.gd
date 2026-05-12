extends CharacterBody3D

# ── Configurações exportáveis ────────────────────────────────────────────────
@export var speed: float = 8.0
@export var flap_strength: float = 6.0
@export var gravity: float = 12.0
@export var anim_speed: float = 2.3  # Velocidade das asas batendo

# Referências internas
var _dragon_model: Node3D = null
var _camera: Camera3D = null
var _anim_player: AnimationPlayer = null

var _sfx_asas: AudioStreamPlayer = null
var _sfx_impulso: AudioStreamPlayer = null
var _sfx_pouso: AudioStreamPlayer = null

var _was_on_floor: bool = false
var _flap_timer: float = 0.0  # Controla volta para animação de voo após Attack

# ── _ready ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	# 1. Esconde o cubo placeholder (MeshInstance3D simples)
	for filho in get_children():
		if filho is MeshInstance3D and filho.name == "MeshInstance3D":
			filho.hide()

	# 2. Carrega e instancia o modelo 3D do Dragão
	var packed = load("res://Dragon.glb")
	if packed:
		_dragon_model = packed.instantiate()
		_dragon_model.name = "DragonModel"
		_dragon_model.scale = Vector3(5.0, 5.0, 5.0)
		_dragon_model.rotation_degrees = Vector3(0, 180, 0)
		add_child(_dragon_model)

		# 3. Encontra o AnimationPlayer dentro do GLB e toca Dragon_Flying
		_anim_player = _dragon_model.find_child("AnimationPlayer", true, false)
		if _anim_player:
			_anim_player.speed_scale = anim_speed
			_anim_player.play("DragonArmature|Dragon_Flying")

	# 4. Referencia a câmera já existente na cena
	_camera = $Camera3D
	if _camera:
		_camera.position = Vector3(0, 10, 28)
		_camera.rotation_degrees = Vector3(-20, 0, 0)

	# 5. Cria AudioStreamPlayers
	_sfx_asas    = _criar_audio("res://Audio/scroll_001.ogg",   true,  -14.0)
	_sfx_impulso = _criar_audio("res://Audio/maximize_004.ogg", false, -4.0)
	_sfx_pouso   = _criar_audio("res://Audio/drop_001.ogg",     false, -6.0)

# Cria um AudioStreamPlayer filho e retorna a referência
func _criar_audio(path: String, loop: bool, volume_db: float) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	var stream = load(path)
	if stream is AudioStreamOggVorbis:
		var s = stream.duplicate() as AudioStreamOggVorbis
		s.loop = loop
		player.stream = s
	else:
		player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player

# ── _physics_process ─────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	var on_floor = is_on_floor()

	# ── Som de asas: toca continuamente enquanto no ar ────────────────────
	if _sfx_asas:
		if not on_floor and not _sfx_asas.playing:
			_sfx_asas.play()
		elif on_floor and _sfx_asas.playing:
			_sfx_asas.stop()

	# ── Som de pouso ──────────────────────────────────────────────────────
	if on_floor and not _was_on_floor and _sfx_pouso:
		_sfx_pouso.play()
	_was_on_floor = on_floor

	# ── Timer para voltar à animação de voo após flap ─────────────────────
	if _flap_timer > 0.0:
		_flap_timer -= delta
		if _flap_timer <= 0.0 and _anim_player:
			_anim_player.speed_scale = anim_speed
			_anim_player.play("DragonArmature|Dragon_Flying")

	# ── 1. Gravidade ──────────────────────────────────────────────────────
	if not on_floor:
		velocity.y -= gravity * delta

	# ── 2. Impulso de voo (Espaço / ui_accept) ────────────────────────────
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = flap_strength
		if _sfx_impulso:
			_sfx_impulso.play()
		# Toca animação de ataque por 0.5 s e volta para Flying
		if _anim_player and _flap_timer <= 0.0:
			_anim_player.speed_scale = 1.5
			_anim_player.play("DragonArmature|Dragon_Attack")
			_flap_timer = 0.55

	# ── 3. Input de direção horizontal ───────────────────────────────────
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if Input.is_physical_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D): input_dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W): input_dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_S): input_dir.y -= 1.0
	input_dir = input_dir.clamp(Vector2(-1, -1), Vector2(1, 1))

	# Z negativo = frente no Godot
	var direction := (transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()

	# ── 4. Aplica velocidade horizontal ──────────────────────────────────
	if direction.length() > 0.01:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if _dragon_model:
			var angle := atan2(direction.x, direction.z)
			_dragon_model.rotation.y = angle
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 6.0)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 6.0)

	# ── 5. Aplica movimento e resolve colisões ────────────────────────────
	move_and_slide()
