extends Button

func set_upgrade_text(upgrade):
	var title = Upgrades.title(upgrade)
	var desc = Upgrades.description(upgrade)
	$Label.text = "%s\n\n%s" % [title, desc]