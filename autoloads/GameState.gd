extends Node

var run_data := {
	"score": 0,
	"floor": 1,
	"cards": [],
}

func reset_run() -> void:
	run_data.score = 0
	run_data.floor = 1
	run_data.cards = []

func add_score(amount: int) -> void:
	run_data.score += amount
