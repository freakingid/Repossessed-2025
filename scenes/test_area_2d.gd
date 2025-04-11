extends Area2D
func _ready():
	print("TestArea2D ready")
	self.body_entered.connect(func(body): print("TestArea2D detected:", body.name))
