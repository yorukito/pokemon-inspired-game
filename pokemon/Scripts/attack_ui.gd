# Attack_ui.gd
extends Control

signal attack_1
signal attack_2
signal buff
signal back_to_main  # Novo sinal para voltar

func _on_attack_1_pressed() -> void:
	attack_1.emit(10, 90)  # 10 de dano, 90% de chance

func _on_attack_2_pressed() -> void:
	attack_2.emit(30, 40)  # 30 de dano, 70% de chance

func _on_buff_pressed() -> void:
	buff.emit()

func _on_back_pressed() -> void:  # Função para botão "Voltar" (opcional)
	back_to_main.emit()
