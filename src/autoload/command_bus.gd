extends Node

## Autoload xử lý mọi Command.
## Theo thiết kế (Tech Spec M6.5): validate -> trừ chi phí -> execute -> signal -> log.

signal command_rejected(cmd: Command, reason: Error)

var command_log: Array[Command] = []
const MAX_LOG_SIZE: int = 200

func submit(state: WorldState, cmd: Command) -> Error:
	var err: Error = cmd.validate(state)
	if err == OK:
		# Trừ chi phí
		var costs: Dictionary = cmd.cost(state)
		if costs.has("mana"):
			state.mana -= float(costs["mana"])
			EventBus.mana_changed.emit(state.mana, state.max_mana)
		
		# Execute
		cmd.execute(state)
		
		# Log
		cmd.tick = GameClock.tick
		command_log.push_back(cmd)
		if command_log.size() > MAX_LOG_SIZE:
			command_log.pop_front()
			
		EventBus.command_executed.emit(cmd)
	else:
		command_rejected.emit(cmd, err)
		
	return err
