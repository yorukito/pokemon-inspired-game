# TurnManager.gd
extends Node

# Sinais para comunicar o estado da batalha
signal player_turn_started
signal enemy_turn_started
signal player_turn_ended
signal battle_ended

enum State {
	PLAYER_TURN,
	ENEMY_TURN,
	BATTLE_ENDED
}

var current_state = State.PLAYER_TURN
var can_act = true # Flag para controlar se é possível realizar uma ação

# Inicia a batalha no turno do jogador
func start_battle() -> void:
	current_state = State.PLAYER_TURN
	player_turn_started.emit()

# Função chamada pelo script principal após o ataque do jogador
func end_player_turn() -> void:
	if current_state != State.PLAYER_TURN or not can_act:
		return
		
	can_act = false
	player_turn_ended.emit()
	await get_tree().create_timer(1.0).timeout # Espera 1 segundo
	start_enemy_turn()

# Inicia o turno do inimigo
func start_enemy_turn() -> void:
	current_state = State.ENEMY_TURN
	enemy_turn_started.emit()
	
	# A lógica de ataque do inimigo será feita aqui
	# (ou no script de batalha, dependendo da sua escolha)
	# Por exemplo, você pode usar um sinal para notificar o script de batalha
	# que o inimigo deve atacar.
	
	# Simula o ataque do inimigo após um pequeno atraso
	await get_tree().create_timer(2.0).timeout
	end_enemy_turn()

# Função chamada após o ataque do inimigo
func end_enemy_turn() -> void:
	current_state = State.PLAYER_TURN
	can_act = true
	player_turn_started.emit()

# Chamada para terminar a batalha
func end_battle() -> void:
	current_state = State.BATTLE_ENDED
	battle_ended.emit()
	can_act = false
