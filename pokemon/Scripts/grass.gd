extends Node2D

func _on_area_2d_body_entered(_body: Node2D) -> void:
	GlobalInfo.origem_da_luta = "mapa"
	get_tree().call_deferred("change_scene_to_file", "res://Scenes/battle_scene.tscn")
