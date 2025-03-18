extends CanvasLayer  # Ensures it renders above everything else

@onready var score_label = $ScoreLabel
## gem collection
@onready var gem_meter = $GemPowerMeter  # ProgressBar
@onready var charge_label = $GemChargeLabel  # Label on top to show count

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
