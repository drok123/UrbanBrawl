class_name SeekGroundWeaponAction
extends ActionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if actor == null or not actor.has_method("ai_seek_ground_weapon"):
		return FAILURE
	return SUCCESS if bool(actor.call("ai_seek_ground_weapon")) else FAILURE
