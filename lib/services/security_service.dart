import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'database_helper.dart';

class SecurityService {
  static final SecurityService instance = SecurityService._internal();
  final LocalAuthentication _auth = LocalAuthentication();

  SecurityService._internal();

  static const _pinKey = 'security_pin_hash';
  static const _biometricKey = 'security_biometric_enabled';

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  String _hashPin(String pin) => hashPin(pin);

  Future<bool> isPinSet() async {
    final hash = await DatabaseHelper.instance.getSetting(_pinKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await DatabaseHelper.instance.getSetting(_pinKey);
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await DatabaseHelper.instance.setSetting(_pinKey, hash);
  }

  Future<void> removePin() async {
    await DatabaseHelper.instance.setSetting(_pinKey, '');
    await setBiometricEnabled(false);
  }

  Future<bool> isBiometricEnabled() async {
    final enabled = await DatabaseHelper.instance.getSetting(_biometricKey);
    return enabled == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await DatabaseHelper.instance.setSetting(_biometricKey, enabled ? 'true' : 'false');
  }

  Future<bool> canUseBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric() async {
    try {
      final isAvailable = await canUseBiometrics();
      if (!isAvailable) return false;

      return await _auth.authenticate(
        localizedReason: 'Pindai sidik jari atau wajah untuk membuka Awan Cash',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
