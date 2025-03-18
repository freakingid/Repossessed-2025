extends CanvasLayer  # Ensures it renders above everything else

@onready var score_label = $ScoreLabel
## gem collection
@onready var gem_meter = $GemPowerMeter  # ProgressBar
@onready var charge_label = $GemChargeLabel  # Label on top to show count

@onready var big_shot_icon = $PowerupContainer/BigShotIcon
@onready var rapid_shot_icon = $PowerupContainer/RapidShotIcon
@onready var triple_shot_icon = $PowerupContainer/TripleShotIcon
@onready var bounce_shot_icon = $PowerupContainer/BounceShotIcon

# Preload powerup icons
var powerup_icons = {
	"big_shot": preload("res://assets/sprites/powerups/fpo-powerup_B.png"),
	"rapid_shot": preload("res://assets/sprites/powerups/fpo-powerup_R.png"),
	"triple_shot": preload("res://assets/sprites/powerups/fpo-powerup_T.png"),
	"bounce_shot": preload("res://assets/sprites/powerups/fpo-powerup_BB.png")
}

func update_powerup_display(active_powerups: Dictionary):
	# Show or hide icons based on active powerups
	big_shot_icon.texture = powerup_icons["big_shot"] if active_powerups.get("big_shot", false) else null
	rapid_shot_icon.texture = powerup_icons["rapid_shot"] if active_powerups.get("rapid_shot", false) else null
	triple_shot_icon.texture = powerup_icons["triple_shot"] if active_powerups.get("triple_shot", false) else null
	bounce_shot_icon.texture = powerup_icons["bounce_shot"] if active_powerups.get("bounce_shot", false) else null

func _ready():
	gem_meter.custom_minimum_size = Vector2(200, 20)  # Set to a thinner size
	update_score_display()

func add_score(points: int):
	Global.score += points
	update_score_display()

func update_score_display():
	if score_label:
		score_label.text = "Score: " + str(Global.score)
	else:
		print("Error: ScoreLabel node not found!")

func get_score():
	return Global.score

func set_score(new_score: int):
	Global.score = new_score
	update_score_display()

func update_gem_power(full_charges: int, partial_charge: int):
	# Fill the progress bar based on the percentage of the current charge
	gem_meter.value = (partial_charge / 50.0) * 100  # Normalize to 0-100 range

	# Display the number of full charges (if any)
	charge_label.text = str(full_charges) if full_charges > 0 else ""
