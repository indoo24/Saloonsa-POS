import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import 'api_client.dart';
import 'logger_service.dart';

/// Service to persist and retrieve app settings
/// Syncs with API and uses SharedPreferences as cache
class SettingsService {
  static const String _settingsKey = 'app_settings';
  static const String _lastSyncKey = 'settings_last_sync';

  final ApiClient _apiClient;

  SettingsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Load settings from API and cache locally
  /// Falls back to local cache if API fails
  Future<AppSettings> loadSettings() async {
    try {
      // Try to load from API first
      final apiSettings = await _loadFromApi();
      if (apiSettings != null) {
        // Cache the API response
        await _saveToCache(apiSettings);
        await _updateLastSync();
        return apiSettings;
      }

      // If API fails, load from cache
      LoggerService.warning('Loading settings from cache (API unavailable)');
      return await _loadFromCache();
    } catch (e) {
      LoggerService.error('Error loading settings', error: e);
      // Fall back to cache
      return await _loadFromCache();
    }
  }

  /// Load settings from API
  Future<AppSettings?> _loadFromApi() async {
    try {
      LoggerService.info('🔄 Fetching settings from API');
      final response = await _apiClient.get('/settings/salon');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        // Map API response to AppSettings model
        final settings = AppSettings(
          businessName: data['site_name'] as String? ?? 'صالون الشباب',
          address: data['address'] as String? ?? 'المدينة المنورة',
          phoneNumber: data['mobile'] as String? ?? '0565656565',
          taxNumber: data['tax_number'] as String? ?? '',
          invoiceNotes: 'شكراً لزيارتكم', // Default, not in API
          taxValue: 15.0, // Default, could be added to API
          pricesIncludeTax: false, // Default, could be added to API
        );

        LoggerService.info('✅ Settings loaded from API successfully');
        return settings;
      }

      return null;
    } catch (e) {
      LoggerService.error('Failed to load settings from API', error: e);
      return null;
    }
  }

  /// Load settings from local cache
  Future<AppSettings> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> json = jsonDecode(settingsJson);
        LoggerService.info('✅ Settings loaded from cache');
        return AppSettings.fromJson(json);
      }

      // Return default settings if none cached
      LoggerService.info('📝 Using default settings');
      return const AppSettings();
    } catch (e) {
      LoggerService.error('Error loading settings from cache', error: e);
      return const AppSettings();
    }
  }

  /// Save settings to cache
  Future<bool> _saveToCache(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      return await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      LoggerService.error('Error saving settings to cache', error: e);
      return false;
    }
  }

  /// Save settings to API and local storage
  Future<bool> saveSettings(AppSettings settings) async {
    try {
      // Save to API first
      final apiSuccess = await _saveToApi(settings);

      // Always save to cache (even if API fails)
      await _saveToCache(settings);

      if (apiSuccess) {
        await _updateLastSync();
        LoggerService.info('✅ Settings saved successfully');
        return true;
      } else {
        LoggerService.warning(
          '⚠️ Settings saved locally only (API sync failed)',
        );
        return true; // Still return true because cache was saved
      }
    } catch (e) {
      LoggerService.error('Error saving settings', error: e);
      return false;
    }
  }

  /// Save settings to API
  Future<bool> _saveToApi(AppSettings settings) async {
    try {
      LoggerService.info('🔄 Saving settings to API');

      // Update individual settings via API
      // The API uses key-value pairs, so we need to update each one
      final updates = {
        'SiteName': settings.businessName,
        'Address': settings.address,
        'mobile': settings.phoneNumber,
        'tax_number': settings.taxNumber,
      };

      bool allSuccess = true;
      for (final entry in updates.entries) {
        try {
          final response = await _apiClient.put(
            '/settings/${entry.key}',
            body: {'value': entry.value},
          );

          if (response['success'] != true) {
            allSuccess = false;
            LoggerService.warning('Failed to update ${entry.key}');
          }
        } catch (e) {
          LoggerService.error('Error updating ${entry.key}', error: e);
          allSuccess = false;
        }
      }

      return allSuccess;
    } catch (e) {
      LoggerService.error('Failed to save settings to API', error: e);
      return false;
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      LoggerService.error('Error updating last sync', error: e);
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Force refresh from API
  Future<AppSettings> refreshFromApi() async {
    final settings = await _loadFromApi();
    if (settings != null) {
      await _saveToCache(settings);
      await _updateLastSync();
      return settings;
    }
    // Fall back to cache if API fails
    return await _loadFromCache();
  }

  /// Clear all settings (reset to defaults)
  Future<bool> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
      await prefs.remove(_lastSyncKey);
      LoggerService.info('Settings cleared');
      return true;
    } catch (e) {
      LoggerService.error('Error clearing settings', error: e);
      return false;
    }
  }
}
