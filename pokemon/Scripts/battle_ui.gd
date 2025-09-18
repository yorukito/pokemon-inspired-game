# battle_ui.gd
extends Control

# Sinais para comunicar com o script de batalha principal
signal attack
signal run

@onready var attack_button = $HBoxContainer/Attack_bag/AttackButton
@onready var run_button = $HBoxContainer/Change_run/RunButton

func _ready() -> void:
	# Conecta os botões aos seus respectivos emissores de sinal
	if attack_button != null:
		attack_button.pressed.connect(on_attack_pressed)
	if run_button != null:
		run_button.pressed.connect(on_run_pressed)

func on_attack_pressed() -> void:
	attack.emit()

func on_run_pressed() -> void:
	run.emit()

func set_buttons_enabled(enabled: bool) -> void:
	# Verifica se a variável do botão não é nula antes de tentar usá-la
	if attack_button != null:
		attack_button.disabled = not enabled
	else:
		# Imprime um aviso no console para ajudar a depurar o problema
		print("Aviso: O nó 'AttackButton' não foi encontrado!")
