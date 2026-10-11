@tool
extends EditorPlugin
var exporter = preload("res://addons/admob/internal/exporters/android/export_plugin.gd").new()
func _enter_tree() -> void:
	add_export_plugin(exporter)
	if "--configure-export" in OS.get_cmdline_user_args(): call_deferred("configure_export")
func _exit_tree() -> void:
	remove_export_plugin(exporter)

func configure_export() -> void:
	await get_tree().process_frame
	var filesystem=EditorInterface.get_resource_filesystem()
	while filesystem.is_scanning(): await get_tree().process_frame
	var helper=load("res://tools/configure_export.gd").new()
	get_tree().quit(helper.configure())
