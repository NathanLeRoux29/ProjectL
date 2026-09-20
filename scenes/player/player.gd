extends CharacterBody2D

# Référence au nœud enfant, résolue au chargement de la scène.
# @onready est nécessaire : à la création de l'objet, les enfants n'existent pas encore.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0  # Négatif car l'axe Y pointe vers le bas en 2D


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
	# Chute libre tant qu'on ne touche pas le sol
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Impulsion verticale, uniquement depuis le sol (pas de double saut pour l'instant)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Renvoie -1 (gauche), 0 (rien) ou 1 (droite)
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		# Ramène la vitesse à zéro. Ici le pas est SPEED, donc l'arrêt est instantané :
		# c'est ce paramètre qu'on assouplira pour obtenir une vraie décélération.
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Applique la vélocité et gère les collisions. Met à jour is_on_floor().
	move_and_slide()
	_update_animation(direction)
