extends BaseEnemy

func _ready():
	# Use Ghost-level stats from Globals.gd
	speed = Global.GHOST.SPEED
	health = Global.GHOST.HEALTH
	damage = Global.GHOST.DAMAGE
	score_value = Global.GHOST.SCORE
	is_flying = false

	# Call parent setup
	super._ready()

# Override with super simple navigation
func update_navigation(delta):
	if is_dead:
		return
	move_directly_to_player(delta)
