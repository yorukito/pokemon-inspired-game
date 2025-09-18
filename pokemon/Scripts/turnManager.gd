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
	
	# Simula o ataque do inimigo após um pequeno atraso
	await get_tree().create_timer(2.0).timeout
	end_enemy_turn()

# Sistema de chance de acerto balanceado (recomendado)
func attack_hit_chance_balanced(damage: int, chance: int) -> Dictionary:
	var roll = randi_range(1, 100)
	var result = {"hit": false, "damage": 0, "message": ""}
	
	if roll <= chance:
		result.hit = true
		result.damage = damage
		result.message = "Ataque acertou! Dano: " + str(damage)
		print(result.message, " (Roll: ", roll, "/", chance, ")")
	else:
		result.message = "Ataque errou!"
		print(result.message, " (Roll: ", roll, "/", chance, ")")
	
	return result

# Sistema avançado com críticos
func attack_hit_chance_advanced(damage: int, chance: int) -> Dictionary:
	var roll = randi_range(1, 100)
	var result = {"hit": false, "damage": 0, "type": "miss", "message": ""}
	
	# Falha crítica (sempre erra nos primeiros 5%)
	if roll <= 5:
		result.type = "critical_miss"
		result.message = "Falha crítica! O ataque errou completamente!"
		print(result.message, " (Roll: ", roll, ")")
	
	# Acerto crítico (sempre acerta nos últimos 5% se dentro da chance)
	elif roll >= 95 and roll <= chance:
		result.hit = true
		result.damage = damage * 2
		result.type = "critical_hit"
		result.message = "Acerto crítico! Dano dobrado: " + str(result.damage)
		print(result.message, " (Roll: ", roll, ")")
	
	# Acerto normal
	elif roll <= chance:
		result.hit = true
		result.damage = damage
		result.type = "normal_hit"
		result.message = "Ataque acertou! Dano: " + str(damage)
		print(result.message, " (Roll: ", roll, "/", chance, ")")
	
	# Erro normal
	else:
		result.message = "Ataque errou!"
		print(result.message, " (Roll: ", roll, "/", chance, ")")
	
	return result

# Sistema simples (apenas true/false)
func attack_hit_chance_simple(damage: int, chance: int) -> bool:
	var roll = randi_range(1, 100)
	var hit = roll <= chance
	
	if hit:
		print("Ataque acertou! Dano: ", damage, " (Roll: ", roll, "/", chance, ")")
		return true
	else:
		print("Ataque errou! (Roll: ", roll, "/", chance, ")")
		return false

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
