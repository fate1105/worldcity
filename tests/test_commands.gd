extends "res://addons/gut/test.gd"

var _state: WorldState

func before_all():
	DataDB.load_all()

func before_each():
	_state = WorldState.new(32, 32, 123)
	WorldGen.generate(_state, 123)
	_state.max_mana = 100.0
	_state.mana = 100.0

func test_place_road_command():
	_state.tile_grid.set_terrain(10, 10, TileGrid.TileType.GRASS)
	
	var cmd = PlaceRoadCommand.new(10, 10, false)
	var err = cmd.validate(_state)
	assert_eq(err, OK, "Should be able to place road on grass")
	
	CommandBus.submit(_state, cmd)
	assert_eq(_state.tile_grid.road[_state.tile_grid.idx(10, 10)], 1, "Road should be placed")
	
	var cmd_remove = PlaceRoadCommand.new(10, 10, true)
	assert_eq(cmd_remove.validate(_state), OK, "Should be able to remove existing road")
	
	_state.tile_grid.set_terrain(5, 5, TileGrid.TileType.DEEP_SEA)
	var cmd_water = PlaceRoadCommand.new(5, 5, false)
	assert_ne(cmd_water.validate(_state), OK, "Should fail to place road on water")

func test_use_power_command():
	_state.mana = 100.0
	var cmd = UsePowerCommand.new(10, 10, "rain")
	var err = cmd.validate(_state)
	assert_eq(err, OK, "Should be valid if enough mana")
	
	_state.mana = 0.0
	var err2 = cmd.validate(_state)
	assert_ne(err2, OK, "Should fail if not enough mana")

func test_command_bus_execution():
	_state.mana = 100.0
	var cmd = UsePowerCommand.new(10, 10, "rain")
	var err = CommandBus.submit(_state, cmd)
	assert_eq(err, OK, "Submit should succeed")
	assert_true(_state.mana < 100.0, "Mana should be deducted by CommandBus")
	
	# Try invalid command via CommandBus
	_state.mana = 0.0
	var cmd2 = UsePowerCommand.new(11, 11, "rain")
	var err3 = CommandBus.submit(_state, cmd2)
	assert_ne(err3, OK, "CommandBus should return error for invalid command")
