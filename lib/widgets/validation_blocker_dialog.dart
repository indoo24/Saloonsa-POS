import 'package:flutter/material.dart';
import '../services/app_setup_service.dart';
import '../helpers/system_settings_helper.dart';

/// Non-dismissible dialog that appears when validation fails
///
/// This dialog blocks access to the app until all requirements are met.
/// It appears on every app launch if Bluetooth or Location is disabled.
class ValidationBlockerDialog extends StatelessWidget {
  final ValidationResult validationResult;
  final VoidCallback onRetryValidation;

  const ValidationBlockerDialog({
    super.key,
    required this.validationResult,
    required this.onRetryValidation,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissal
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('Setup Required')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following requirements must be met to use printer features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...validationResult.missingItems.map(
                (item) => _buildMissingItem(item),
              ),
            ],
          ),
        ),
        actions: [
          ..._buildActionButtons(),
          TextButton(
            onPressed: onRetryValidation,
            child: const Text('Check Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItem(MissingItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIconForItem(item), color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(item.message, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForItem(MissingItem item) {
    switch (item.type) {
      case MissingItemType.permissionBluetoothConnect:
      case MissingItemType.permissionBluetoothScan:
      case MissingItemType.permissionLocation:
        return Icons.lock;
      case MissingItemType.bluetoothDisabled:
      case MissingItemType.bluetoothNotSupported:
      case MissingItemType.bluetoothError:
        return Icons.bluetooth_disabled;
      case MissingItemType.locationDisabled:
      case MissingItemType.locationError:
        return Icons.location_off;
    }
  }

  List<Widget> _buildActionButtons() {
    final buttons = <Widget>[];

    // Check if Bluetooth settings needed
    final needsBluetooth = validationResult.missingItems.any(
      (item) => item.type == MissingItemType.bluetoothDisabled,
    );

    if (needsBluetooth) {
      buttons.add(
        TextButton.icon(
          onPressed: () => SystemSettingsHelper.openBluetoothSettings(),
          icon: const Icon(Icons.bluetooth),
          label: const Text('Open Bluetooth'),
        ),
      );
    }

    // Check if Location settings needed
    final needsLocation = validationResult.missingItems.any(
      (item) => item.type == MissingItemType.locationDisabled,
    );

    if (needsLocation) {
      buttons.add(
        TextButton.icon(
          onPressed: () => SystemSettingsHelper.openLocationSettings(),
          icon: const Icon(Icons.location_on),
          label: const Text('Open Location'),
        ),
      );
    }

    // Check if permissions needed
    final needsPermissions = validationResult.missingItems.any(
      (item) =>
          item.type == MissingItemType.permissionBluetoothConnect ||
          item.type == MissingItemType.permissionBluetoothScan ||
          item.type == MissingItemType.permissionLocation,
    );

    if (needsPermissions) {
      buttons.add(
        TextButton.icon(
          onPressed: () => SystemSettingsHelper.openAppPermissionSettings(),
          icon: const Icon(Icons.settings),
          label: const Text('Open Settings'),
        ),
      );
    }

    return buttons;
  }
}
