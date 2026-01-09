import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/app_settings.dart';
import '../../services/settings_service.dart';
import 'settings_state.dart';

/// Cubit to manage app settings
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsService _settingsService;
  AppSettings? _currentSettings;

  SettingsCubit({SettingsService? settingsService})
    : _settingsService = settingsService ?? SettingsService(),
      super(const SettingsInitial());

  /// Load settings from storage
  Future<void> loadSettings() async {
    emit(const SettingsLoading());
    try {
      final settings = await _settingsService.loadSettings();
      _currentSettings = settings;
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('فشل تحميل الإعدادات: $e'));
    }
  }

  /// Save settings to storage
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final success = await _settingsService.saveSettings(settings);
      if (success) {
        _currentSettings = settings;
        emit(SettingsSaved(settings));
        // Return to loaded state after brief success message
        await Future.delayed(const Duration(milliseconds: 100));
        emit(SettingsLoaded(settings));
      } else {
        emit(SettingsError('فشل حفظ الإعدادات', _currentSettings));
      }
    } catch (e) {
      emit(SettingsError('فشل حفظ الإعدادات: $e', _currentSettings));
    }
  }

  /// Update specific setting field
  Future<void> updateSettings({
    String? businessName,
    String? address,
    String? phoneNumber,
    String? taxNumber,
    String? invoiceNotes,
    double? taxValue,
    bool? pricesIncludeTax,
  }) async {
    if (_currentSettings == null) {
      await loadSettings();
    }

    final updatedSettings = (_currentSettings ?? const AppSettings()).copyWith(
      businessName: businessName,
      address: address,
      phoneNumber: phoneNumber,
      taxNumber: taxNumber,
      invoiceNotes: invoiceNotes,
      taxValue: taxValue,
      pricesIncludeTax: pricesIncludeTax,
    );

    await saveSettings(updatedSettings);
  }

  /// Get current settings (load if needed)
  Future<AppSettings> getCurrentSettings() async {
    if (_currentSettings == null) {
      await loadSettings();
    }
    return _currentSettings ?? const AppSettings();
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    await _settingsService.clearSettings();
    _currentSettings = const AppSettings();
    emit(SettingsLoaded(_currentSettings!));
  }

  /// Refresh settings from API
  Future<void> refreshFromApi() async {
    emit(const SettingsLoading());
    try {
      final settings = await _settingsService.refreshFromApi();
      _currentSettings = settings;
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('فشل تحديث الإعدادات من السيرفر: $e'));
    }
  }
}
