extends Control

signal resume_requested
signal restart_requested

func _on_resume_button_pressed() -> void:
	resume_requested.emit()
	queue_free()

func _on_restart_button_pressed() -> void:
	restart_requested.emit()
	queue_free()

func show_pause_menu() -> void:
	visible = true
	# Pause the game when showing the pause menu
	get_tree().paused = true

func _ready() -> void:
	# Make sure this dialog can receive input even when paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC key
		_on_resume_button_pressed()
		get_viewport().set_input_as_handled()  # Consume the input to prevent other handlers