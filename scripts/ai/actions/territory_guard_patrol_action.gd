class_name TerritoryGuardPatrolAction
extends ActionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if actor == null or not actor.has_method("ai_patrol"):
		return FAILURE
	return SUCCESS if bool(actor.call("ai_patrol")) else FAILURE
