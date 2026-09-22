extends CanvasLayer

@onready var wins_label: Label = $Bar/WinsLabel
@onready var time_label: Label = $Bar/TimeLabel
@onready var hurry_label: Label = $Bar/HurryLabel


func set_wins(wins: Array[int]) -> void:
	var parts: Array[String] = []
	for i in wins.size():
		parts.append("%s %d" % [Battle.bomber_name(i), wins[i]])
	wins_label.text = " ".join(parts)


func set_time(seconds: float) -> void:
	var whole := ceili(seconds)
	time_label.text = "%d:%02d" % [int(whole / 60.0), whole % 60]


func show_hurry(visible_now: bool) -> void:
	hurry_label.visible = visible_now
