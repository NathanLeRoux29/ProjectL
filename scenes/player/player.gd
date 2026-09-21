extends CharacterBody2D

# Référence au nœud enfant, résolue au chargement de la scène.
# @onready est nécessaire : à la création de l'objet, les enfants n'existent pas encore.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 200.0
@export var jump_velocity: float = -370.0  # Négatif car l'axe Y pointe vers le bas en 2D
@export var acceleration: float = 2000.0
@export var friction: float = 1500.0 
@export var gravity_up: float = 980.0 
@export var gravity_down: float = 1500.0 
@export var jump_cut: float = 0.5 
@export var coyote_time: float = 0.05
var coyote_timer: float = 0.0   
@export var jump_buffer_time: float = 0.1 
var jump_buffer_timer: float = 0.0 
  
# Choisit l'animation et l'orientation selon l'état courant du personnage.
# Appelée après move_and_slide(), donc is_on_floor() est déjà à jour.
func _update_animation(direction: float) -> void:
	# On ne retourne le sprite que si une touche est pressée,
	# sinon le personnage pivoterait tout seul à l'arrêt.
	if direction != 0:
		sprite.flip_h = direction < 0

	if not is_on_floor():
		# En l'air : monte ou descend
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
	else:
		# Au sol : bouge ou immobile
		if direction != 0:
			sprite.play("run")
		else:
			sprite.play("idle")


# Boucle physique, appelée à cadence fixe (60 fois par seconde par défaut).
# delta = temps écoulé depuis l'appel précédent, pour rester indépendant des FPS.
func _physics_process(delta: float) -> void:

	# Coyote time : on garde le souvenir d'avoir été au sol pendant un court instant.
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	# Tampon de saut : on garde l'appui en mémoire s'il arrive un peu trop tôt.
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta	
		
	# Chute libre tant qu'on ne touche pas le sol
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y += gravity_up * delta
		else:
			velocity.y += gravity_down * delta

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut

	# Renvoie -1 (gauche), 0 (rien) ou 1 (droite)
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		# Ramène la vitesse à zéro. Ici le pas est speed, donc l'arrêt est instantané :
		# c'est ce paramètre qu'on assouplira pour obtenir une vraie décélération.
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# Applique la vélocité et gère les collisions. Met à jour is_on_floor().
	move_and_slide()
	_update_animation(direction)
