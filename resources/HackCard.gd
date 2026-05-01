class_name HackCard
extends Resource

enum EffectType { STUN, REDIRECT, BREACH, OVERCLOCK, PING, FIREWALL }

@export var card_name: String = ""
@export var description: String = ""
@export var icon_color: Color = Color.WHITE
@export var effect_type: EffectType = EffectType.STUN
@export var cooldown: float = 10.0
@export var effect_radius: float = 150.0
@export var effect_duration: float = 3.0
@export var upgraded_version: HackCard = null
