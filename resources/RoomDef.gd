class_name RoomDef
extends Resource

enum Type { HUB, COMBAT, HACK, LOOT, BLACK_MARKET, BOSS, WARDEN }

const NORTH := 0
const EAST  := 1
const SOUTH := 2
const WEST  := 3

@export var id: int = 0
@export var type: Type = Type.HUB
@export var connections: Dictionary = {}  # direction (int) -> room_id (int)
@export var cleared: bool = false
@export var map_pos: Vector2i = Vector2i.ZERO
@export var floor_num: int = 1
