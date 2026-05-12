extends CharacterBody3D

# ── Configurações exportáveis ────────────────────────────────────────────────
@export var base_forward_speed: float = 40.0  # Dobro da velocidade base (de 20 para 40)
@export var flap_thrust: float = 80.0         # Impulso máximo muito mais forte (de 40 para 80)
@export var thrust_decay: float = 5.0 # Decaimento reduzido de 15 para 5 (velocidade se conserva 3x mais)
@export var pitch_speed: float = 1.5
@export var roll_speed: float = 2.0
@export var yaw_speed: float = 1.0
@export var anim_speed: float = 1.0

var current_thrust: float = 0.0

# Referências internas
var _dragon_model: Node3D = null
var _camera: Camera3D = null
var _camera_target: Node3D = null
var _anim_player: AnimationPlayer = null

var _was_on_floor: bool = false

# ── _ready ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	# 1. Esconde o cubo placeholder (MeshInstance3D simples)
	for filho in get_children():
		if filho is MeshInstance3D and filho.name == "MeshInstance3D":
			filho.hide()

	# 2. Carrega e instancia o modelo 3D do Dragão
	var packed = load("res://Models/Dragon.glb")
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
			
			var fly_anim = _anim_player.get_animation("DragonArmature|Dragon_Flying")
			if fly_anim:
				fly_anim.loop_mode = Animation.LOOP_NONE
				fly_anim.length = fly_anim.length / 2.0

	# 4. Referencia a câmera já existente na cena
	_camera = $Camera3D
	if _camera:
		_camera_target = Node3D.new()
		_camera_target.name = "CameraTarget"
		# Levantando a câmera para não focar apenas nos pés (Y=7.0 parece ser o centro do tronco)
		_camera_target.position = Vector3(0, 7.0, 16)
		_camera_target.rotation_degrees = Vector3(0, 0, 0)
		add_child(_camera_target)
		
		_camera.top_level = true
		_camera.position = _camera_target.global_position
		_camera.rotation = _camera_target.global_rotation



# ── _physics_process ─────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# 1. Obter os inputs de controle de voo
	var pitch_input = 0.0
	if Input.is_physical_key_pressed(KEY_W): pitch_input -= 1.0 # Levantar nariz (-X)
	if Input.is_physical_key_pressed(KEY_S): pitch_input += 1.0 # Abaixar nariz (+X)

	var roll_input = 0.0
	if Input.is_physical_key_pressed(KEY_A): roll_input += 1.0 # Rolar esquerda (+Z)
	if Input.is_physical_key_pressed(KEY_D): roll_input -= 1.0 # Rolar direita (-Z)

	var yaw_input = 0.0
	if Input.is_physical_key_pressed(KEY_Q): yaw_input += 1.0 # Virar esquerda (+Y)
	if Input.is_physical_key_pressed(KEY_E): yaw_input -= 1.0 # Virar direita (-Y)

	# 2. Aplicar rotações locais
	rotate_object_local(Vector3(1, 0, 0), pitch_input * pitch_speed * delta)
	rotate_object_local(Vector3(0, 0, 1), roll_input * roll_speed * delta)
	rotate_object_local(Vector3(0, 1, 0), yaw_input * yaw_speed * delta)
	
	transform.basis = transform.basis.orthonormalized()

	# 3. Propulsão ao bater asas
	if Input.is_action_just_pressed("ui_accept"):
		if not _anim_player.is_playing() or _anim_player.current_animation != "DragonArmature|Dragon_Flying":
			current_thrust = flap_thrust
			_anim_player.play("DragonArmature|Dragon_Flying")

	# Decaimento suave da força da batida de asas
	current_thrust = move_toward(current_thrust, 0.0, thrust_decay * delta)

	# 4. Aplicar velocidade sempre na direção do nariz (frente = -Z)
	var forward_dir = -transform.basis.z.normalized()
	velocity = forward_dir * (base_forward_speed + current_thrust)

	# 5. Move o avião/dragão
	move_and_slide()

	# 6. Animação Procedural Suave (Sway/Inclinação)
	if _dragon_model:
		var target_rot_z = yaw_input * 0.4 - roll_input * 0.2
		var target_rot_x = pitch_input * 0.3
		_dragon_model.rotation.z = lerp_angle(_dragon_model.rotation.z, target_rot_z, delta * 3.0)
		_dragon_model.rotation.x = lerp_angle(_dragon_model.rotation.x, target_rot_x, delta * 3.0)

	# 7. Câmera com Delay Suave (Efeito de Velocidade)
	if _camera and _camera_target:
		_camera.global_position = _camera.global_position.lerp(_camera_target.global_position, delta * 15.0)
		var current_quat = _camera.global_transform.basis.get_rotation_quaternion()
		var target_quat = _camera_target.global_transform.basis.get_rotation_quaternion()
		_camera.global_transform.basis = Basis(current_quat.slerp(target_quat, delta * 10.0))
