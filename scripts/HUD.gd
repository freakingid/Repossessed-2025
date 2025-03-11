extends CanvasLayer  # Ensures it renders above everything else

@onready var score_label = $ScoreLabel

func _ready():
	update_score_display()

func add_score(points: int):
	Global.score += points
	print("HUD score updated:", Global.score)  # Debugging output
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
