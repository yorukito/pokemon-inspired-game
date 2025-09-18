extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

var SPEED = 100.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("Left", "Right", "Up", "Down")
	if direction:
		sprite.flip_h = false
		if Input.is_action_pressed("Left"):
			sprite.play("side")
			
		elif Input.is_action_pressed("Right"):
			sprite.flip_h = true
			sprite.play("side")
			
		elif Input.is_action_pressed("Up"):
			sprite.play("back")
			
		elif Input.is_action_pressed("Down"):
			sprite.play("front")
		velocity = direction * SPEED
		
		if Input.is_action_pressed("sprint"):
			SPEED = 150
		else:
			SPEED = 100
	else:
		sprite.stop()
		velocity = Vector2.ZERO

	move_and_slide()
