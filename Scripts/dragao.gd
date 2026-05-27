extends CharacterBody3D

# ══════════════════════════════════════════════════════════════════════════════
# DRAGÃO — Física de Voo Estilo Superflight
# ══════════════════════════════════════════════════════════════════════════════
#
# O ciclo pêndulo:
#   1. MERGULHO (S) → nariz para baixo → arrasto mínimo → v² cresce rápido
#   2. NIVELAR (W)  → lift proporcional a v² cancela gravidade → planeio
#   3. ESTOL        → pitch > stall_angle → arrasto explode, lift zera → cai
#
# Todas as forças são "falsas" (game feel > realismo):
#   - Drag  = drag_coefficient × speed × area_frontal(pitch)
#   - Lift  = lift_coefficient × speed × lift_factor(pitch)  [combate gravidade]
#   - Steering: velocidade é lerped suavemente para o eixo do nariz
#
# ══════════════════════════════════════════════════════════════════════════════

# ── Física de Voo ─────────────────────────────────────────────────────────────
@export_group("Física de Voo")

## Aceleração gravitacional (m/s²). Valores altos tornam o ciclo de mergulho mais urgente.
@export var gravity: float = 28.0

## Fração de velocidade perdida por arrasto por segundo (no voo horizontal).
## Ex.: 0.35 → perde 35% da velocidade por segundo parado em horizontal.
@export var drag_coefficient: float = 0.35

## Força de sustentação por unidade de velocidade. Em voo nivelado, cancela a gravidade
## quando speed ≈ gravity / lift_coefficient (≈ 37 m/s com valores padrão).
@export var lift_coefficient: float = 0.75

## Ângulo de pitch (graus) acima do horizonte que inicia o estol.
@export var stall_angle_deg: float = 25.0

## Multiplicador de arrasto no mergulho vertical (nariz 90° para baixo).
## Valor baixo = queda quase livre = acumulação rápida de velocidade.
@export var dive_drag_mult: float = 0.06

## Velocidade com que a direção de movimento segue o nariz do dragão.
## Alto = mais responsivo; baixo = mais "pesado" e inercial.
@export var steering_factor: float = 2.5

## Velocidade mínima mantida pelo dragão para evitar trava completa.
@export var min_speed: float = 6.0

## Velocidade máxima (terminal) que o sistema de arrasto impõe.
@export var max_speed: float = 130.0

## Velocidade de voo ao iniciar a cena.
@export var initial_speed: float = 25.0

# ── Controles ─────────────────────────────────────────────────────────────────
@export_group("Controles")
@export var pitch_speed: float = 1.5
@export var roll_speed:  float = 2.0
@export var yaw_speed:   float = 1.0

# ── Batida de Asas ────────────────────────────────────────────────────────────
@export_group("Batida de Asas")
## Impulso instantâneo na direção do nariz ao bater as asas.
@export var flap_thrust: float = 30.0
@export var anim_speed:  float = 1.0

# ── Estado Interno ────────────────────────────────────────────────────────────
var _dragon_model:   Node3D            = null
var _camera:         Camera3D          = null
var _camera_target:  Node3D            = null
var _anim_player:    AnimationPlayer   = null
var _is_stalling:    bool              = false   # verdadeiro quando em estol

# ── Debug HUD ─────────────────────────────────────────────────────────────────
var _debug_visible:  bool              = false
var _debug_layer:    CanvasLayer       = null
var _lbl_speed:      Label             = null   # velocímetro grande
var _lbl_pitch:      Label             = null
var _lbl_drag:       Label             = null
var _lbl_lift:       Label             = null
var _lbl_stall:      Label             = null
var _lbl_grav:       Label             = null
var _lbl_hint:       Label             = null   # dica de tecla


# ══════════════════════════════════════════════════════════════════════════════
# _ready
# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	# Velocidade inicial para frente (o dragão já começa "voando")
	velocity = -transform.basis.z.normalized() * initial_speed

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

		# 3. Encontra o AnimationPlayer dentro do GLB
		_anim_player = _dragon_model.find_child("AnimationPlayer", true, false)
		if _anim_player:
			_anim_player.speed_scale = anim_speed
			var fly_anim = _anim_player.get_animation("DragonArmature|Dragon_Flying")
			if fly_anim:
				fly_anim.loop_mode = Animation.LOOP_NONE
				fly_anim.length = fly_anim.length / 2.0

	# 4. Câmera com delay suave
	_camera = $Camera3D
	if _camera:
		_camera_target = Node3D.new()
		_camera_target.name = "CameraTarget"
		_camera_target.position = Vector3(0, 7.0, 16)
		add_child(_camera_target)

		_camera.top_level = true
		_camera.position = _camera_target.global_position
		_camera.rotation = _camera_target.global_rotation

	# 5. Debug HUD
	_create_debug_hud()


# ══════════════════════════════════════════════════════════════════════════════
# Debug HUD
# ══════════════════════════════════════════════════════════════════════════════

## Cria um Label estilizado e o adiciona ao nó pai indicado.
func _make_hud_label(text: String, color: Color, parent: Node) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


## Constrói o painel de debug via código (CanvasLayer + Labels).
func _create_debug_hud() -> void:
	_debug_layer = CanvasLayer.new()
	_debug_layer.layer = 10
	add_child(_debug_layer)

	# ── Painel de métricas (canto superior esquerdo) ──────────────────────────
	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	panel_style.corner_radius_top_left    = 8
	panel_style.corner_radius_top_right   = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left   = 14.0
	panel_style.content_margin_right  = 14.0
	panel_style.content_margin_top    = 10.0
	panel_style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 20)
	_debug_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Labels de métricas
	_lbl_pitch = _make_hud_label("PITCH:   ---", Color(0.6, 0.9, 1.0), vbox)
	_lbl_drag  = _make_hud_label("ARRASTO: ---", Color(1.0, 0.6, 0.3), vbox)
	_lbl_lift  = _make_hud_label("LIFT:    ---", Color(0.4, 1.0, 0.6), vbox)
	_lbl_grav  = _make_hud_label("GRAVITY: ---", Color(0.9, 0.9, 0.5), vbox)
	_lbl_stall = _make_hud_label("ESTOL:   ---", Color(1.0, 1.0, 1.0), vbox)

	# ── Velocímetro (centro inferior) ────────────────────────────────────────
	var spd_anchor := Control.new()
	spd_anchor.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	spd_anchor.grow_vertical = Control.GROW_DIRECTION_BEGIN
	spd_anchor.custom_minimum_size = Vector2(0, 90)
	_debug_layer.add_child(spd_anchor)

	_lbl_speed = Label.new()
	_lbl_speed.text = "0 m/s"
	_lbl_speed.add_theme_font_size_override("font_size", 52)
	_lbl_speed.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_lbl_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_speed.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_lbl_speed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spd_anchor.add_child(_lbl_speed)

	# ── Dica de tecla (canto inferior direito) ────────────────────────────────
	_lbl_hint = Label.new()
	_lbl_hint.text = "[P] Debug HUD"
	_lbl_hint.add_theme_font_size_override("font_size", 13)
	_lbl_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	_lbl_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_lbl_hint.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	_lbl_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_lbl_hint.position = Vector2(-160, -36)
	_debug_layer.add_child(_lbl_hint)

	# Começa oculto (exceto a dica)
	panel.visible    = false
	spd_anchor.visible = false
	# Guarda referências para toggle
	_debug_layer.set_meta("panel", panel)
	_debug_layer.set_meta("spd_anchor", spd_anchor)


## Atualiza os valores exibidos no HUD a cada frame de física.
func _update_debug_hud(pitch: float, spd: float, drag_area: float, lift_fac: float) -> void:
	if not _debug_visible:
		return
	var eff_grav := gravity - lift_coefficient * spd * lift_fac
	_lbl_pitch.text = "PITCH:    %+.1f°" % pitch
	_lbl_drag.text  = "ARRASTO:  %.2f×" % drag_area
	_lbl_lift.text  = "LIFT:     %.2f" % lift_fac
	_lbl_grav.text  = "GRAVITY:  %.1f m/s²" % maxf(eff_grav, 0.0)
	if _is_stalling:
		_lbl_stall.text = "ESTOL:    ⚠ SIM"
		_lbl_stall.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		_lbl_stall.text = "ESTOL:    OK"
		_lbl_stall.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	# Velocímetro — cor varia por faixa de velocidade
	var spd_color: Color
	if spd < 20.0:
		spd_color = Color(0.7, 0.7, 0.7)   # cinza = lento
	elif spd < 60.0:
		spd_color = Color(0.4, 1.0, 0.5)   # verde = bom
	elif spd < 100.0:
		spd_color = Color(1.0, 0.85, 0.2)  # amarelo = rápido
	else:
		spd_color = Color(1.0, 0.3, 0.2)   # vermelho = terminal
	_lbl_speed.text = "%.0f m/s" % spd
	_lbl_speed.add_theme_color_override("font_color", spd_color)


## Alterna visibilidade do painel de debug ao pressionar P.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_P and event.pressed and not event.echo:
		_debug_visible = not _debug_visible
		if _debug_layer:
			_debug_layer.get_meta("panel").visible = _debug_visible
			_debug_layer.get_meta("spd_anchor").visible = _debug_visible


# ══════════════════════════════════════════════════════════════════════════════
# Helpers Aerodinâmicos
# ══════════════════════════════════════════════════════════════════════════════

## Ângulo de pitch em graus: positivo = nariz para cima, negativo = nariz para baixo.
func _get_pitch_degrees() -> float:
	var forward := -transform.basis.z.normalized()
	return rad_to_deg(asin(clamp(forward.y, -1.0, 1.0)))


## Fator de área frontal que escala o arrasto.
##   pitch = -90° (mergulho vertical)  → dive_drag_mult   (≈ 0.06 — quase livre)
##   pitch =   0° (horizontal)         → 1.0              (arrasto base completo)
##   pitch > stall_angle (estol)        → sobe até 4.0     (freio violento)
func _drag_area_factor(pitch: float) -> float:
	if pitch < 0.0:
		# Mergulho: arrasto cai linearmente até o mínimo no nariz-para-baixo
		var t := clampf(-pitch / 90.0, 0.0, 1.0)
		return lerp(1.0, dive_drag_mult, t)
	elif pitch < stall_angle_deg:
		# Planeio suave: arrasto base
		return 1.0
	else:
		# Zona de estol: arrasto quadrático — quanto mais subir, mais trava
		var t := clampf((pitch - stall_angle_deg) / (90.0 - stall_angle_deg), 0.0, 1.0)
		return lerp(1.0, 4.0, t * t)


## Fator de sustentação (0–1) que escala a força anti-gravitacional.
##   pitch =   0° → 1.0 (sustentação máxima — planeio perfeito)
##   pitch = -80° → 0.0 (mergulho vertical — sem sustentação)
##   pitch > stall_angle → cai rapidamente para 0 (estol)
func _lift_factor(pitch: float) -> float:
	if pitch < -80.0 or pitch > 80.0:
		return 0.0
	if pitch < 0.0:
		# Mergulho: sustentação cai quadraticamente
		var t := clampf(-pitch / 80.0, 0.0, 1.0)
		return 1.0 - t * t
	elif pitch < stall_angle_deg:
		# Planeio ou leve subida: sustentação total
		return 1.0
	else:
		# Estol: sustentação colapsa
		var t := clampf((pitch - stall_angle_deg) / (90.0 - stall_angle_deg), 0.0, 1.0)
		return 1.0 - t * t


# ══════════════════════════════════════════════════════════════════════════════
# _physics_process
# ══════════════════════════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:

	# ── 1. Input de Rotação ───────────────────────────────────────────────────
	var pitch_input := 0.0
	if Input.is_physical_key_pressed(KEY_W): pitch_input -= 1.0  # Levantar nariz
	if Input.is_physical_key_pressed(KEY_S): pitch_input += 1.0  # Abaixar nariz

	var roll_input := 0.0
	if Input.is_physical_key_pressed(KEY_A): roll_input += 1.0   # Rolar esquerda
	if Input.is_physical_key_pressed(KEY_D): roll_input -= 1.0   # Rolar direita

	var yaw_input := 0.0
	if Input.is_physical_key_pressed(KEY_Q): yaw_input += 1.0    # Virar esquerda
	if Input.is_physical_key_pressed(KEY_E): yaw_input -= 1.0    # Virar direita

	rotate_object_local(Vector3(1, 0, 0), pitch_input * pitch_speed * delta)
	rotate_object_local(Vector3(0, 0, 1), roll_input  * roll_speed  * delta)
	rotate_object_local(Vector3(0, 1, 0), yaw_input   * yaw_speed   * delta)
	transform.basis = transform.basis.orthonormalized()

	# ── 2. Estado Aerodinâmico Atual ──────────────────────────────────────────
	var pitch_deg  := _get_pitch_degrees()
	var speed      := velocity.length()
	var forward_dir := -transform.basis.z.normalized()

	_is_stalling = (pitch_deg > stall_angle_deg)

	# ── 3. Arrasto (Drag) — desacelera na direção do movimento ───────────────
	#
	#   drag_force = drag_coefficient × drag_area × speed
	#
	# Drag é linear na velocidade (não quadrático) para facilitar o tuning.
	# O drag_area_factor varia de ~0 (mergulho) a 4 (estol).
	var drag_area  := _drag_area_factor(pitch_deg)
	var drag_force := drag_coefficient * drag_area * speed
	# Subtrai da velocidade na sua própria direção (nunca inverte o sentido)
	var drag_delta := drag_force * delta
	if drag_delta < speed:
		velocity -= velocity.normalized() * drag_delta
	else:
		velocity = Vector3.ZERO

	# ── 4. Gravidade ──────────────────────────────────────────────────────────
	velocity.y -= gravity * delta

	# ── 5. Sustentação (Lift) — força para cima proporcional à velocidade ────
	#
	#   lift_force = lift_coefficient × speed × lift_factor(pitch)
	#
	# Quando speed ≥ gravity / lift_coefficient (≈37 m/s), a sustentação
	# cancela a gravidade e o dragão planeia sem perder altitude.
	var l_factor   := _lift_factor(pitch_deg)
	var lift_force := lift_coefficient * speed * l_factor
	velocity.y += lift_force * delta

	# ── 6. Steering — Velocidade segue o nariz gradualmente ──────────────────
	#
	# Este é o coração do game feel do Superflight:
	# a velocidade é interpolada suavemente para a direção do nariz,
	# conservando o módulo (speed). Isso cria a trajetória em arco
	# satisfatória ao nivelar de um mergulho.
	speed = velocity.length()  # recalcula após gravity/lift
	if speed > 0.001:
		var target_velocity := forward_dir * maxf(speed, min_speed)
		velocity = velocity.lerp(target_velocity, steering_factor * delta)

	# ── 7. Limite de Velocidade Terminal ──────────────────────────────────────
	velocity = velocity.limit_length(max_speed)

	# ── 8. Velocidade Mínima de Voo (anti-trava) ──────────────────────────────
	# Garante que o dragão nunca pare completamente no eixo frontal,
	# exceto durante o estol (onde a queda é o comportamento correto).
	if not _is_stalling:
		var fwd_speed := velocity.dot(forward_dir)
		if fwd_speed < min_speed:
			velocity += forward_dir * (min_speed - fwd_speed) * delta * 3.0

	# ── 9. Batida de Asas — Impulso Extra ─────────────────────────────────────
	if Input.is_action_just_pressed("ui_accept"):
		velocity += forward_dir * flap_thrust
		if _anim_player and (not _anim_player.is_playing() or
				_anim_player.current_animation != "DragonArmature|Dragon_Flying"):
			_anim_player.play("DragonArmature|Dragon_Flying")

	# ── 10. Movimentação ──────────────────────────────────────────────────────
	move_and_slide()

	# ── 11. Animação Procedural do Modelo (Sway) ──────────────────────────────
	if _dragon_model:
		var target_rot_z := yaw_input * 0.4 - roll_input * 0.2
		var target_rot_x := pitch_input * 0.3
		_dragon_model.rotation.z = lerp_angle(_dragon_model.rotation.z, target_rot_z, delta * 3.0)
		_dragon_model.rotation.x = lerp_angle(_dragon_model.rotation.x, target_rot_x, delta * 3.0)

	# ── 12. Câmera com Delay Suave ────────────────────────────────────────────
	if _camera and _camera_target:
		_camera.global_position = _camera.global_position.lerp(
			_camera_target.global_position, delta * 15.0)
		var current_quat := _camera.global_transform.basis.get_rotation_quaternion()
		var target_quat  := _camera_target.global_transform.basis.get_rotation_quaternion()
		_camera.global_transform.basis = Basis(current_quat.slerp(target_quat, delta * 10.0))

	# ── 13. Atualizar Debug HUD ────────────────────────────────────────────────
	_update_debug_hud(pitch_deg, speed, drag_area, l_factor)
