extends Area2D

func _on_BattlefieldBounds_body_exited(body:Node):
	body.exited_battlefield()
