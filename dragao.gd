extends CharacterBody3D

# ── Configurações exportáveis ────────────────────────────────────────────────
@export var speed: float = 8.0
@export var flap_strength: float = 6.0
@export var gravity: float = 12.0

# Referências internas
var _dragon_model: Node3D = null
var _camera: Camera3D = null

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
		# Modelo exportado com Z para trás; rotaciona 180° para ficar de frente
		_dragon_model.rotation_degrees = Vector3(0, 180, 0)
		add_child(_dragon_model)

	# 3. Referencia a câmera já existente na cena (adicionada pelo editor)
	#    e ajusta posição/ângulo para 3ª pessoa clássica
	_camera = $Camera3D
	if _camera:
		# Vista 3ª pessoa: Z=28 e Y=10 enquadram o dragão por completo (escala 5x)
		_camera.position = Vector3(0, 10, 28)
		_camera.rotation_degrees = Vector3(-20, 0, 0)

# ── _physics_process ─────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# ── 1. Gravidade ─────────────────────────────────────────────────────────
	if not is_on_floor():
		velocity.y -= gravity * delta

	# ── 2. Impulso de voo (Espaço / Enter / ui_accept) ───────────────────────
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = flap_strength

	# ── 3. Input de direção horizontal ───────────────────────────────────────
	# get_vector retorna: x=-1 (left/A), x=+1 (right/D), y=-1 (up/W), y=+1 (down/S)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Fallback para teclas físicas WASD (garante funcionamento mesmo sem mapeamento ui_)
	if Input.is_physical_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D): input_dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S): input_dir.y += 1.0
	input_dir = input_dir.clamp(Vector2(-1, -1), Vector2(1, 1))

	# No Godot: Z negativo = frente, Z positivo = trás
	# input_dir.y = -1 quando W (frente) → Z precisa ser negativo → usamos -input_dir.y
	var direction := (transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()

	# ── 4. Aplica velocidade horizontal ──────────────────────────────────────
	if direction.length() > 0.01:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Rotaciona o modelo visual do dragão para encarar a direção do movimento
		if _dragon_model:
			var angle := atan2(direction.x, direction.z)
			_dragon_model.rotation.y = angle
	else:
		# Desaceleração suave ao soltar as teclas
		velocity.x = move_toward(velocity.x, 0, speed * delta * 6.0)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 6.0)

	# ── 5. Aplica movimento e resolve colisões ────────────────────────────────
	move_and_slide()
