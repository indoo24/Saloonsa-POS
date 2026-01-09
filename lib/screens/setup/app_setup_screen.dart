import 'package:barber_casher/helpers/system_settings_helper.dart';
import 'package:barber_casher/services/app_setup_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// First-launch setup screen
///
/// This screen appears ONLY on the first app launch and guides the user
/// through required permissions and system settings.
///
/// FLOW (Android 12+):
/// 1. Request runtime permissions (Bluetooth Connect + Scan ONLY)
/// 2. Check Bluetooth is enabled
/// 3. Mark setup as complete
/// 4. Navigate to app
///
/// FLOW (Android < 12):
/// 1. Request runtime permissions (Location ONLY)
/// 2. Check Bluetooth is enabled
/// 3. Check Location is enabled
/// 4. Mark setup as complete
/// 5. Navigate to app
class AppSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const AppSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<AppSetupScreen> createState() => _AppSetupScreenState();
}

class _AppSetupScreenState extends State<AppSetupScreen> {
  final Logger _logger = Logger();
  final AppSetupService _setupService = AppSetupService();

  SetupStep _currentStep = SetupStep.welcome;
  bool _isProcessing = false;
  String? _errorMessage;
  int _androidVersion = 31; // Default to Android 12+

  @override
  void initState() {
    super.initState();
    _loadAndroidVersion();
  }

  Future<void> _loadAndroidVersion() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    setState(() {
      _androidVersion = androidInfo.version.sdkInt;
    });
    _logger.i('📱 Android SDK Version: $_androidVersion');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App icon/logo
              Icon(
                Icons.print,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Welcome to Salon POS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle based on current step
              Text(
                _getStepDescription(),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Progress indicator
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else
                _buildStepContent(),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case SetupStep.welcome:
        return 'Let\'s set up your app for printer functionality';
      case SetupStep.permissions:
        if (_androidVersion >= 31) {
          return 'We need Bluetooth permissions to access printers';
        } else {
          return 'We need Location permission for Bluetooth scanning';
        }
      case SetupStep.bluetooth:
        return 'Bluetooth must be enabled to connect to printers';
      case SetupStep.location:
        return 'Location services are required for Bluetooth scanning on Android 11 and below';
      case SetupStep.complete:
        return 'Setup complete! You\'re ready to use the app';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case SetupStep.welcome:
        return _buildWelcomeStep();
      case SetupStep.permissions:
        return _buildPermissionsStep();
      case SetupStep.bluetooth:
        return _buildBluetoothStep();
      case SetupStep.location:
        return _buildLocationStep();
      case SetupStep.complete:
        return _buildCompleteStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.bluetooth,
          title: 'Bluetooth Printing',
          description: 'Connect to thermal printers wirelessly',
        ),
        const SizedBox(height: 16),
        if (_androidVersion < 31)
          _buildInfoCard(
            icon: Icons.location_on,
            title: 'Device Discovery',
            description:
                'Find and pair with nearby printers (Android 11 and below)',
          )
        else
          _buildInfoCard(
            icon: Icons.devices,
            title: 'Nearby Devices',
            description: 'Access paired Bluetooth printers',
          ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => _startSetup(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
          child: const Text('Get Started'),
        ),
      ],
    );
  }

  Widget _buildPermissionsStep() {
    final permissionsList = _androidVersion >= 31
        ? 'Bluetooth Connect\nBluetooth Scan'
        : 'Location';

    final permissionTitle = _androidVersion >= 31
        ? 'Nearby Devices Permission'
        : 'Location Permission';

    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.security,
          title: permissionTitle,
          description: permissionsList,
        ),
        if (_androidVersion >= 31) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Location permission is NOT required on Android 12+',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => _requestPermissions(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
          child: const Text('Grant Permissions'),
        ),
      ],
    );
  }

  Widget _buildBluetoothStep() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.bluetooth_disabled,
          title: 'Bluetooth is OFF',
          description: 'Please enable Bluetooth to continue',
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => _openBluetoothSettings(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Open Bluetooth Settings'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => _recheckRequirements(),
          child: const Text('I\'ve Enabled Bluetooth'),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.location_off,
          title: 'Location is OFF',
          description:
              'Location services are required for Bluetooth device discovery',
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => _openLocationSettings(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Open Location Settings'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => _recheckRequirements(),
          child: const Text('I\'ve Enabled Location'),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      children: [
        Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'All set!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => _finishSetup(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
          child: const Text('Continue to App'),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SETUP FLOW METHODS
  // ============================================================================

  Future<void> _startSetup() async {
    setState(() {
      _currentStep = SetupStep.permissions;
      _errorMessage = null;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _setupService.requestPermissions();

      if (result.allGranted) {
        _logger.i('✅ All permissions granted');
        await _proceedToNextStep();
      } else if (result.hasAnyPermanentlyDenied) {
        setState(() {
          _errorMessage =
              'Some permissions were permanently denied. '
              'Please grant them in app settings.';
        });
        await SystemSettingsHelper.openAppPermissionSettings();
      } else {
        setState(() {
          _errorMessage = 'All permissions are required to continue.';
        });
      }
    } catch (e) {
      _logger.e('Error requesting permissions: $e');
      setState(() {
        _errorMessage = 'Failed to request permissions: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _openBluetoothSettings() async {
    await SystemSettingsHelper.openBluetoothSettings();
  }

  Future<void> _openLocationSettings() async {
    await SystemSettingsHelper.openLocationSettings();
  }

  Future<void> _recheckRequirements() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _proceedToNextStep();
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _proceedToNextStep() async {
    // Validate current requirements
    final validation = await _setupService.performValidation();

    // Find next missing requirement
    if (!validation.permissionsGranted) {
      setState(() {
        _currentStep = SetupStep.permissions;
        _errorMessage = 'Please grant all required permissions.';
      });
      return;
    }

    if (!validation.bluetoothEnabled) {
      setState(() {
        _currentStep = SetupStep.bluetooth;
        _errorMessage = null;
      });
      return;
    }

    if (!validation.locationEnabled) {
      setState(() {
        _currentStep = SetupStep.location;
        _errorMessage = null;
      });
      return;
    }

    // All requirements met!
    setState(() {
      _currentStep = SetupStep.complete;
      _errorMessage = null;
    });
  }

  Future<void> _finishSetup() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _setupService.markSetupCompleted();
      _logger.i('✅ Setup completed successfully');
      widget.onSetupComplete();
    } catch (e) {
      _logger.e('Error finishing setup: $e');
      setState(() {
        _errorMessage = 'Failed to complete setup: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

enum SetupStep { welcome, permissions, bluetooth, location, complete }
