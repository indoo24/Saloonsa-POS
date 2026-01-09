import '../../models/app_settings.dart';

/// Base state for Settings
abstract class SettingsState {
  const SettingsState();
}

/// Initial state - settings not loaded yet
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Loading settings from storage
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Settings loaded successfully
class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  const SettingsLoaded(this.settings);
}

/// Settings saved successfully (temporary state for UI feedback)
class SettingsSaved extends SettingsState {
  final AppSettings settings;

  const SettingsSaved(this.settings);
}

/// Error occurred while loading or saving settings
class SettingsError extends SettingsState {
  final String message;
  final AppSettings? lastKnownSettings;

  const SettingsError(this.message, [this.lastKnownSettings]);
}
