extends Label

func remove():
	call_deferred("queue_free")

func init(amount, pos):
	text = "%s" % int(amount)
	self.rect_position = pos

func tween_and_remove():
	var t = Tween.new()
	t.interpolate_property(self, "rect_position:y", null, rect_position.y - 15, 1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	t.interpolate_property(self, "modulate:a", 1.0, 0.25,1, Tween.TRANS_QUAD, Tween.EASE_OUT)
	add_child(t)
	t.start()
	t.connect("tween_all_completed", self, "remove")

func _ready():
	tween_and_remove()
