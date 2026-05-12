extends Node3D

func _ready() -> void:
	pass

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
