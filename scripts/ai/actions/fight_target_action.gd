class_name FightTargetAction
extends ActionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if actor == null or not actor.has_method("ai_fight_target"):
		return FAILURE
	return SUCCESS if bool(actor.call("ai_fight_target")) else FAILURE
