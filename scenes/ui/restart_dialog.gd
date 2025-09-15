extends Control

signal restart_requested

func _on_restart_button_pressed() -> void:
	restart_requested.emit()
	queue_free()

func show_dialog() -> void:
	visible = true
	# Pause the game when showing the dialog
	get_tree().paused = true

func _ready() -> void:
	# Make sure this dialog can receive input even when paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
