class_name TerritoryGuardRespondAction
extends ActionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if actor == null or not actor.has_method("ai_respond_to_threat"):
		return FAILURE
	return SUCCESS if bool(actor.call("ai_respond_to_threat")) else FAILURE
