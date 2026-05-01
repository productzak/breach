class_name Cyberware
extends Resource

enum EffectType { HEALTH_MAX, SPEED, MELEE_DAMAGE, FIRE_RATE, REGEN_ON_CLEAR }

@export var cyberware_name: String = ""
@export var description: String = ""
@export var effect_type: EffectType = EffectType.HEALTH_MAX
@export var effect_value: float = 0.0
@export var cost: int = 0
@export var icon_color: Color = Color(0.4, 1.0, 0.8)
