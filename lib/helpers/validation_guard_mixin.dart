import 'package:flutter/material.dart';
import '../services/app_setup_service.dart';
import '../widgets/validation_blocker_dialog.dart';

/// Mixin that adds validation guard to printer-related screens
///
/// This ensures Bluetooth and Location are always ready before
/// allowing printer operations like scanning or connecting.
mixin ValidationGuardMixin<T extends StatefulWidget> on State<T> {
  final AppSetupService _setupService = AppSetupService();

  /// Validate requirements before proceeding with printer operation
  /// Returns true if validation passed, false otherwise
  Future<bool> validateBeforePrinterOperation({String? operationName}) async {
    final validation = await _setupService.performValidation();

    if (validation.isValid) {
      return true;
    }

    // Show blocking dialog
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ValidationBlockerDialog(
          validationResult: validation,
          onRetryValidation: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }

    return false;
  }

  /// Lightweight check without showing dialog
  Future<bool> isEnvironmentReady() async {
    final validation = await _setupService.performValidation();
    return validation.isValid;
  }
}
