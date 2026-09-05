class_name RaidGuard3D
extends TerritoryGuard3D

func _ready() -> void:
	super._ready()
	add_to_group("raid_defender")
	_engaged = true
	_response_left = 9999.0
	_flash_status("RAID DEFENSE")
