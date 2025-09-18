extends Node2D
var count = 0

func _ready() -> void:
	# Gera o sorteio apenas uma vez no GlobalInfo se ainda não existe
	if not GlobalInfo.has_method("get_battle_trigger") or GlobalInfo.battle_trigger_sort == 0:
		GlobalInfo.battle_trigger_sort = randi_range(1, 10)
		GlobalInfo.battle_trigger_count = 0

func _on_area_2d_body_entered(_body: Node2D) -> void:
	GlobalInfo.battle_trigger_count += 1
	
	if GlobalInfo.battle_trigger_sort == GlobalInfo.battle_trigger_count:
		GlobalInfo.origem_da_luta = "mapa"
		# Reseta para próxima vez
		GlobalInfo.battle_trigger_sort = randi_range(1, 10)
		GlobalInfo.battle_trigger_count = 0
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/battle_scene.tscn")
	
	print(str(GlobalInfo.battle_trigger_count) + " out of " + str(GlobalInfo.battle_trigger_sort))
