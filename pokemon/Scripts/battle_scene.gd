extends Node2D

@onready var enemyBar = $Enemy_bar
@onready var playerBar = $Player_bar
@onready var battleui = $Battle_ui
@onready var turn_manager = $TurnManager # Certifique-se de ter um nó 'TurnManager' na cena

@export var inimigo_do_npc_cena: PackedScene
@export var inimigo_do_mapa_cena: PackedScene

@export var enemy_health = 100
@export var enemy_max_health = 100

var player_health = 100
var player_max_health = 100

# Chamado quando o nó entra na árvore de cena
func _ready() -> void:
	update_progress_bars()
	
	# Conecta os sinais do Battle_ui
	battleui.attack.connect(on_player_attack)
	battleui.run.connect(on_player_run) # <--- Nova Conexão!
	
	# Conecta os sinais do gerenciador de turnos
	turn_manager.player_turn_started.connect(on_player_turn)
	turn_manager.enemy_turn_started.connect(on_enemy_turn)
	
	turn_manager.start_battle()
	if GlobalInfo.origem_da_luta == "npc":
		var inimigo = inimigo_do_npc_cena.instantiate()
		add_child(inimigo)
		inimigo.position.x = 315
		inimigo.position.y = 35
	elif GlobalInfo.origem_da_luta == "mapa":
		var inimigo = inimigo_do_mapa_cena.instantiate()
		add_child(inimigo)
		inimigo.position.x = 315
		inimigo.position.y = 35
	else:
		print("Origem da luta desconhecida.")

# ---

func update_progress_bars() -> void:
	enemyBar.value = enemy_health
	enemyBar.max_value = enemy_max_health
	playerBar.value = player_health
	playerBar.max_value = player_max_health

# --- Funções de Turno ---

func on_player_turn() -> void:
	print("É o seu turno! Habilite os botões.")
	# Exemplo: Habilitar botões na UI
	battleui.set_buttons_enabled(true)

func on_enemy_turn() -> void:
	print("Turno do inimigo! Desabilite os botões e ataque.")
	# Exemplo: Desabilitar botões na UI
	battleui.set_buttons_enabled(false)
	
	# Simula o ataque do inimigo
	var damage = 5
	player_health -= damage
	update_progress_bars()
	
	if player_health <= 0:
		player_health = 0
		update_progress_bars()
		print("Você perdeu a batalha!")
		turn_manager.end_battle()
	else:
		# Fim do turno do inimigo
		turn_manager.end_enemy_turn()

# --- Funções de Ação ---

func on_player_attack() -> void:
	# Causa dano no inimigo se for o turno do jogador
	if turn_manager.current_state == turn_manager.State.PLAYER_TURN and turn_manager.can_act:
		var damage = 10
		enemy_health -= damage
		if enemy_health < 0:
			enemy_health = 0
			
		update_progress_bars()
		
		print("Inimigo recebeu ", damage, " de dano. Vida restante: ", enemy_health)
		
		if enemy_health <= 0:
			print("Inimigo derrotado!")
			turn_manager.end_battle()
		else:
			turn_manager.end_player_turn()

func on_player_run() -> void:
	# Chama a função segura para mudar de cena
	get_tree().call_deferred("change_scene_to_file", "res://Scenes/main.tscn")
	print("Você fugiu da batalha!")
