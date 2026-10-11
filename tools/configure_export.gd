extends RefCounted
func configure() -> int:
	var sdk=OS.get_environment("ANDROID_HOME")
	if sdk.is_empty(): sdk=OS.get_environment("ANDROID_SDK_ROOT")
	if sdk.is_empty(): push_error("Set ANDROID_HOME to an installed, licensed Android SDK."); return 1
	if not FileAccess.file_exists(sdk.path_join("platforms/android-36/android.jar")):
		push_error("Android API 36 is missing. Install it only after its license has been accepted by the owner."); return 1
	var editor_settings=EditorInterface.get_editor_settings()
	if editor_settings==null: push_error("Run configuration with --editor."); return 1
	editor_settings.set_setting("export/android/android_sdk_path",sdk)
	var java=OS.get_environment("JAVA_HOME")
	if not java.is_empty(): editor_settings.set_setting("export/android/java_sdk_path",java)
	var cfg=ConfigFile.new(); cfg.load("res://export_presets.cfg")
	var signed=not OS.get_environment("GODOT_ANDROID_KEYSTORE_RELEASE_PATH").is_empty()
	cfg.set_value("preset.0.options","package/signed",signed)
	var version_code=OS.get_environment("HEXBOUND_VERSION_CODE")
	if not version_code.is_empty(): cfg.set_value("preset.0.options","version/code",int(version_code))
	var ads_enabled=OS.get_environment("HEXBOUND_TEST_ADS")=="1"
	cfg.set_value("preset.0.options","permissions/internet",ads_enabled)
	cfg.set_value("preset.0.options","permissions/access_network_state",ads_enabled)
	if OS.get_environment("HEXBOUND_ANDROID_QA")=="1": cfg.set_value("preset.0.options","command_line/extra_args","-- --qa-play")
	cfg.save("res://export_presets.cfg")
	# Editor export ignores override.cfg: set the temporary project configuration.
	ProjectSettings.set_setting("admob/general/android/enabled",ads_enabled)
	ProjectSettings.set_setting("admob/general/android/app_id","ca-app-pub-3940256099942544~3347511713")
	if ProjectSettings.save()!=OK: push_error("Could not save temporary export configuration."); return 1
	var overrides=ConfigFile.new()
	overrides.set_value("admob","general/android/enabled",ads_enabled)
	overrides.set_value("admob","general/android/app_id","ca-app-pub-3940256099942544~3347511713")
	overrides.set_value("admob","general/ios/enabled",false)
	overrides.save("res://override.cfg")
	print("Android export configured: API 36, signed=",signed," test_ads=",ads_enabled)
	return 0
