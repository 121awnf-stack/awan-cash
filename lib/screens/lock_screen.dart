import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../state/app_state.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricOnLaunch();
  }

  Future<void> _checkBiometricOnLaunch() async {
    final appState = AppState.instance;
    if (appState.isBiometricEnabled) {
      await Future.delayed(const Duration(milliseconds: 300));
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final success = await SecurityService.instance.authenticateBiometric();
    if (success && mounted) {
      AppState.instance.unlock();
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 6) return;

    setState(() {
      _errorMessage = null;
      _enteredPin += digit;
    });

    if (_enteredPin.length >= 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_isChecking) return;
    _isChecking = true;

    final isValid = await SecurityService.instance.verifyPin(_enteredPin);
    _isChecking = false;

    if (!mounted) return;

    if (isValid) {
      AppState.instance.unlock();
    } else {
      if (_enteredPin.length >= 6) {
        setState(() {
          _errorMessage = 'PIN salah. Silakan coba lagi.';
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo / Ikon Awan
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.cloud_queue, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Awan Cash',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan PIN keamanan Anda',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            // Indikator Titik PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? const Color(0xFF0EA5E9)
                        : Colors.grey.withAlpha(50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFilled
                          ? const Color(0xFF0EA5E9)
                          : Colors.grey.withAlpha(120),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            const Spacer(),
            // Numpad 1 - 9, biometrik, 0, hapus
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKey('1'),
                      _buildKey('2'),
                      _buildKey('3'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKey('4'),
                      _buildKey('5'),
                      _buildKey('6'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKey('7'),
                      _buildKey('8'),
                      _buildKey('9'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Tombol Biometrik
                      AppState.instance.isBiometricEnabled
                          ? _buildActionButton(
                              icon: Icons.fingerprint,
                              onPressed: _tryBiometric,
                            )
                          : const SizedBox(width: 72, height: 72),
                      _buildKey('0'),
                      _buildActionButton(
                        icon: Icons.backspace_outlined,
                        onPressed: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String digit) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withAlpha(120),
          shape: BoxShape.circle,
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(36),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Icon(icon, size: 28),
      ),
    );
  }
}
