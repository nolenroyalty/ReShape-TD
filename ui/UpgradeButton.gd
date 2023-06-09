extends Button

func set_upgrade_text(upgrade):
	$Title.text = Upgrades.title(upgrade)
	$Desc.text = Upgrades.description(upgrade)
