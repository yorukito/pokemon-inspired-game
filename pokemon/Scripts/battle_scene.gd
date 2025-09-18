# Script principal da batalha
extends Node2D

@onready var enemyBar = $Enemy_bar
@onready var playerBar = $Player_bar
@onready var battleui = $Battle_ui
@onready var turn_manager = $TurnManager
@onready var attack_ui = $Attack_ui
@onready var enemy_label = $enemy_life_label
@onready var player_label = $player_life_label
@onready var battle_text = $Battle_text  # UI para mensagens de batalha
var enemy_instance = null  

@export var inimigo_do_npc_cena: PackedScene
@export var inimigo_do_mapa_cena: PackedScene
var enemy_health =100
var enemy_max_health= 100

var player_health = 100
var player_max_health = 100

# Variáveis para sistema de buff dos inimigos
var enemy_damage_buff = 0    # Dano extra por turno
var enemy_defense_buff = 0   # Redução de dano recebido
var enemy_buff_turns = 0     # Quantos turnos o buff dura

# NOVO: Sistema de limite de ataques
var attack_uses = {
	"attack_1": 0,
	"attack_2": 0, 
	"buff": 0
}

var attack_limits = {
	"attack_1": 3,
	"attack_2": 2,
	"buff": 1
}

func _ready() -> void:
	reset_attack_counters()  # Reset dos contadores
	update_progress_bars()
	
	# Configurar battle_text
	if battle_text:
		battle_text.visible = false
	
	# Configurar visibilidade inicial das UIs
	battleui.visible = true
	attack_ui.visible = false
	
	battleui.attack.connect(on_player_attack)
	battleui.run.connect(on_player_run)
	
	# Conectar os ataques específicos do Attack_ui
	attack_ui.attack_1.connect(on_attack_1)
	attack_ui.attack_2.connect(on_attack_2)
	attack_ui.buff.connect(on_buff)
	attack_ui.back_to_main.connect(return_to_main_ui)  # Conectar botão voltar (opcional)
	
	turn_manager.player_turn_started.connect(on_player_turn)
	turn_manager.enemy_turn_started.connect(on_enemy_turn)
	
	turn_manager.start_battle()
	
	if GlobalInfo.origem_da_luta == "npc":
		enemy_instance = inimigo_do_npc_cena.instantiate()
		add_child(enemy_instance)
		enemy_instance.position.x = 290
		enemy_instance.position.y = 35
		
		# Pegar vida da cena do inimigo NPC
		if "enemy_current_life" in enemy_instance and "enemy_life" in enemy_instance:
			enemy_max_health = enemy_instance.enemy_life
			enemy_health = enemy_instance.enemy_current_life
			
			print("Inimigo NPC carregado - Vida: ", enemy_health, "/", enemy_max_health)
		else:
			print("AVISO: Propriedades de vida não encontradas no inimigo NPC")
			
	elif GlobalInfo.origem_da_luta == "mapa":
		enemy_instance = inimigo_do_mapa_cena.instantiate()
		add_child(enemy_instance)
		enemy_instance.position.x = 290
		enemy_instance.position.y = 35
		
		# Pegar vida da cena do inimigo selvagem
		if "enemy_current_life" in enemy_instance and "enemy_life" in enemy_instance:
			enemy_health = enemy_instance.enemy_current_life
			enemy_max_health = enemy_instance.enemy_life
			print("Inimigo Selvagem carregado - Vida: ", enemy_health, "/", enemy_max_health)
		else:
			print("AVISO: Propriedades de vida não encontradasd no inimigo selvagem")
			
	else:
		print("Origem da luta desconhecida.")
	
	# Atualizar as barras após definir a vida do inimigo
	update_progress_bars()

# Funções do sistema de limite de ataques
func can_use_attack(attack_name: String) -> bool:
	return attack_uses[attack_name] < attack_limits[attack_name]

func use_attack(attack_name: String) -> bool:
	if can_use_attack(attack_name):
		attack_uses[attack_name] += 1
		update_attack_ui()
		return true
	else:
		show_battle_message(get_attack_display_name(attack_name) + " esgotado! (" + 
			str(attack_uses[attack_name]) + "/" + str(attack_limits[attack_name]) + ")")
		return false

func get_attack_display_name(attack_name: String) -> String:
	match attack_name:
		"attack_1": return "Ataque Rápido"
		"attack_2": return "Ataque Pesado" 
		"buff": return "Cura"
		_: return "Ataque"

func reset_attack_counters() -> void:
	for attack in attack_uses:
		attack_uses[attack] = 0
	update_attack_ui()

func update_attack_ui() -> void:
	# Se o Attack_ui tem labels para mostrar usos restantes
	if attack_ui.has_method("update_attack_counters"):
		var counters = {}
		for attack in attack_uses:
			var remaining = attack_limits[attack] - attack_uses[attack]
			counters[attack] = str(remaining) + "/" + str(attack_limits[attack])
		attack_ui.update_attack_counters(counters)
	
	# Ou desabilitar botões quando esgotados
	if attack_ui.has_method("set_attack_enabled"):
		attack_ui.set_attack_enabled("attack_1", can_use_attack("attack_1"))
		attack_ui.set_attack_enabled("attack_2", can_use_attack("attack_2"))
		attack_ui.set_attack_enabled("buff", can_use_attack("buff"))

func update_progress_bars() -> void:
	enemyBar.max_value = enemy_max_health
	enemyBar.value = enemy_health
	playerBar.value = player_health
	playerBar.max_value = player_max_health
	enemy_label.text = str(enemy_health) + "/" + str(enemy_max_health)
	player_label.text = str(player_health) + "/" + str(player_max_health)

func on_player_turn() -> void:
	print("É o seu turno! Habilite os botões.")
	battleui.set_buttons_enabled(true)

func on_enemy_turn() -> void:
	print("Turno do inimigo! Desabilite os botões e ataque.")
	battleui.set_buttons_enabled(false)
	
	# Ataque do inimigo com chance de erro
	enemy_attack()

func enemy_attack() -> void:
	# Diferentes comportamentos baseados na origem da luta
	if GlobalInfo.origem_da_luta == "npc":
		enemy_npc_behavior()
	elif GlobalInfo.origem_da_luta == "mapa":
		enemy_wild_behavior()
	else:
		# Comportamento padrão
		enemy_wild_behavior()

func enemy_npc_behavior() -> void:
	# Inimigo NPC: Mais estratégico, 50% chance de usar buff
	var action_choice = randi_range(1, 100)
	
	if action_choice <= 50 and enemy_buff_turns <= 0:  # 50% chance de buff (se não tiver buff ativo)
		enemy_use_buff()
	else:
		enemy_basic_attack("npc")

func enemy_wild_behavior() -> void:
	# Inimigo Selvagem: Mais agressivo, 20% chance de buff
	var action_choice = randi_range(1, 100)
	
	if action_choice <= 20 and enemy_buff_turns <= 0:  # 20% chance de buff (se não tiver buff ativo)
		enemy_use_buff()
	else:
		enemy_basic_attack("wild")

func enemy_use_buff() -> void:
	var buff_type = randi_range(1, 2)
	
	if buff_type == 1:
		# Buff de ataque: +4 de dano por 3 turnos
		enemy_damage_buff = 4
		enemy_buff_turns = 3
		show_battle_message("Inimigo se concentrou! Próximos ataques serão mais poderosos!")
		enemy_buff_effect()  # Efeito visual opcional
	else:
		# Buff de defesa: -5 de dano recebido por 3 turnos  
		enemy_defense_buff = 2
		enemy_buff_turns = 3
		show_battle_message("Inimigo endureceu a pele! Receberá menos dano!")
		enemy_buff_effect()  # Efeito visual opcional
	
	update_progress_bars()
	
	if player_health <= 0:
		player_health = 0
		update_progress_bars()
		show_battle_message("Você perdeu a batalha!")
		turn_manager.end_battle()
	else:
		turn_manager.end_enemy_turn()

func enemy_basic_attack(enemy_type: String) -> void:
	var enemy_damage: int
	var enemy_hit_chance: int
	
	# Configurar dano e precisão baseado no tipo de inimigo
	if enemy_type == "npc":
		enemy_damage = 8   # Dano base menor, mas mais preciso
		enemy_hit_chance = 90
	else:  # "wild"
		enemy_damage = 12  # Dano base maior, mas menos preciso
		enemy_hit_chance = 80
	
	# Aplicar buff de dano se ativo
	enemy_damage += enemy_damage_buff
	
	# Usar o sistema de chance do TurnManager
	var attack_result = turn_manager.attack_hit_chance_balanced(enemy_damage, enemy_hit_chance)
	
	if attack_result.hit:
		player_health -= attack_result.damage
		
		var enemy_name = "Inimigo" if enemy_type == "npc" else "Inimigo Selvagem"
		var damage_text = str(attack_result.damage)
		if enemy_damage_buff > 0:
			damage_text += " (+" + str(enemy_damage_buff) + " buff)"
			
		show_battle_message(enemy_name + " atacou e causou " + damage_text + " de dano!")
	else:
		show_battle_message("O ataque do inimigo errou completamente!")
	
	# Reduzir contador do buff
	if enemy_buff_turns > 0:
		enemy_buff_turns -= 1
		if enemy_buff_turns <= 0:
			if enemy_damage_buff > 0:
				show_battle_message("O buff de ataque do inimigo acabou.")
				enemy_damage_buff = 0
			if enemy_defense_buff > 0:
				show_battle_message("O buff de defesa do inimigo acabou.")
				enemy_defense_buff = 0
	
	update_progress_bars()
	
	if player_health <= 0:
		player_health = 0
		update_progress_bars()
		show_battle_message("Você foi derrotado!")
		turn_manager.end_battle()
	else:
		turn_manager.end_enemy_turn()

# Handlers para os ataques específicos com limite
func on_attack_1(damage: int, chance: int) -> void:
	if turn_manager.current_state == turn_manager.State.PLAYER_TURN and turn_manager.can_act:
		if use_attack("attack_1"):
			execute_player_attack(damage, chance, "Ataque Rápido")

func on_attack_2(damage: int, chance: int) -> void:
	if turn_manager.current_state == turn_manager.State.PLAYER_TURN and turn_manager.can_act:
		if use_attack("attack_2"):
			execute_player_attack(damage, chance, "Ataque Pesado")

func on_buff() -> void:
	if turn_manager.current_state == turn_manager.State.PLAYER_TURN and turn_manager.can_act:
		if use_attack("buff"):
			player_health += 20
			if player_health > player_max_health:
				player_health = player_max_health
			
			update_progress_bars()
			show_battle_message("Você se curou! +20 HP")
			turn_manager.end_player_turn()

func execute_player_attack(damage: int, chance: int, attack_name: String) -> void:
	var attack_result = turn_manager.attack_hit_chance_balanced(damage, chance)
	
	if attack_result.hit:
		enemy_health -= attack_result.damage
		if enemy_health < 0:
			enemy_health = 0
			show_battle_message("Inimigo foi derrotado!")
			battleui.visible = false
			attack_ui.visible = false
			await get_tree().create_timer(2.0).timeout  # Aguardar mensagem
			get_tree().call_deferred("change_scene_to_file", "res://Scenes/main.tscn")
			return
		
		show_battle_message(attack_name + " acertou em cheio! Causou " + str(attack_result.damage) + " de dano!")
		
		# Efeito visual de dano no inimigo
		enemy_damage_effect()
	else:
		show_battle_message(attack_name + " falhou! O ataque não acertou!")
	
	update_progress_bars()
	
	if enemy_health <= 0:
		show_battle_message("Vitória! Inimigo derrotado!")
		turn_manager.end_battle()
	else:
		turn_manager.end_player_turn()

# Função para abrir o menu de ataques (não executa ataque diretamente)
func on_player_attack() -> void:
	if turn_manager.current_state == turn_manager.State.PLAYER_TURN and turn_manager.can_act:
		# Esconder UI principal e mostrar menu de ataques
		battleui.visible = false
		attack_ui.visible = true
		update_attack_ui()  # Atualizar UI ao abrir menu
		print("Menu de ataques aberto!")

func on_player_run() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://Scenes/main.tscn")
	print("Você fugiu da batalha!")

# FUNÇÕES DE INTERFACE:
func return_to_main_ui():
	battleui.visible = true
	attack_ui.visible = false

# Sistema de mensagens de batalha
var message_queue = []
var is_showing_message = false
var message_display_time = 2.0  # Tempo que cada mensagem fica na tela

func show_battle_message(message: String) -> void:
	message_queue.append(message)
	attack_ui.visible = false
	# Efeito de fade in/out
	if battle_text.has_method("modulate"):
		battle_text.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(battle_text, "modulate:a", 1.0, 0.3)
	
	if not is_showing_message:
		display_next_message()

func display_next_message() -> void:
	if message_queue.is_empty():
		is_showing_message = false
		battle_text.visible = false
		
		# NOVO: Mostrar attack_ui novamente se o jogador estava no menu de ataques
		if turn_manager.current_state == turn_manager.State.PLAYER_TURN and not battleui.visible:
			attack_ui.visible = true
		return
	
	is_showing_message = true
	var message = message_queue.pop_front()
	
	if battle_text.has_node("Label"):
		battle_text.get_node("Label").text = message
	else:
		battle_text.text = message  # Se o battle_text for um Label direto
	
	battle_text.visible = true
	
	# Aguardar e mostrar próxima mensagem
	await get_tree().create_timer(message_display_time).timeout
	display_next_message()

func show_battle_message_instant(message: String) -> void:
	# Versão instantânea para quando você quiser mostrar imediatamente
	print(message)
	
	if battle_text.has_node("Label"):
		battle_text.get_node("Label").text = message
	else:
		battle_text.text = message
	
	battle_text.visible = true

func clear_message_queue() -> void:
	message_queue.clear()
	battle_text.visible = false
	is_showing_message = false

func enemy_damage_effect() -> void:
	enemy_instance.modulate = Color.RED
	await get_tree().create_timer(0.2).timeout  
	enemy_instance.modulate = Color.WHITE

func enemy_buff_effect() -> void:
	enemy_instance.modulate = Color.AQUA
	await get_tree().create_timer(0.2).timeout
	enemy_instance.modulate = Color.WHITE
	
