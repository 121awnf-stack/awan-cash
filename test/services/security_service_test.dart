import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awan_cash/services/security_service.dart';

void main() {
  group('SecurityService PIN Hashing', () {
    test('hashPin returns deterministic SHA-256 hex string for 4-digit PINs', () {
      const pin = '1234';
      final expectedSha256 = sha256.convert(utf8.encode(pin)).toString();

      final hash1 = SecurityService.hashPin(pin);
      final hash2 = SecurityService.hashPin(pin);

      expect(hash1, expectedSha256);
      expect(hash1, hash2);
      expect(hash1, '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4');
    });

    test('hashPin returns deterministic SHA-256 hex string for 6-digit PINs', () {
      const pin = '123456';
      final expectedSha256 = sha256.convert(utf8.encode(pin)).toString();

      final hash = SecurityService.hashPin(pin);

      expect(hash, expectedSha256);
      expect(hash, '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92');
    });

    test('hashPin output is always 64 hexadecimal characters', () {
      final pins = ['0000', '9999', '111111', '837261', '0'];
      final hexRegex = RegExp(r'^[0-9a-f]{64}$');

      for (final p in pins) {
        final hash = SecurityService.hashPin(p);
        expect(hash.length, 64);
        expect(hexRegex.hasMatch(hash), isTrue);
      }
    });

    test('different PINs produce completely different hashes (avalanche effect)', () {
      final hash1 = SecurityService.hashPin('1234');
      final hash2 = SecurityService.hashPin('1235');
      final hash3 = SecurityService.hashPin('0123');

      expect(hash1, isNot(equals(hash2)));
      expect(hash1, isNot(equals(hash3)));
      expect(hash2, isNot(equals(hash3)));
    });

    test('edge case: empty PIN string produces standard SHA-256 empty hash', () {
      const emptyPin = '';
      final expectedEmptySha256 = sha256.convert(utf8.encode(emptyPin)).toString();

      final hash = SecurityService.hashPin(emptyPin);

      expect(hash, expectedEmptySha256);
      expect(hash, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    });

    test('edge case: PIN with symbols and whitespace is handled correctly', () {
      final testCases = [
        '*#06#',
        ' 1234 ',
        'P@ssw0rd!',
        '12.34',
        '000-000',
      ];

      for (final input in testCases) {
        final hash = SecurityService.hashPin(input);
        final expected = sha256.convert(utf8.encode(input)).toString();

        expect(hash, expected);
        expect(hash.length, 64);
      }
    });

    test('simulated PIN verification matches correct PIN and rejects incorrect PIN', () {
      const storedPin = '7890';
      final storedHash = SecurityService.hashPin(storedPin);

      // Correct PIN attempt
      expect(SecurityService.hashPin('7890') == storedHash, isTrue);

      // Incorrect PIN attempts
      expect(SecurityService.hashPin('7891') == storedHash, isFalse);
      expect(SecurityService.hashPin('0000') == storedHash, isFalse);
      expect(SecurityService.hashPin('') == storedHash, isFalse);
    });
  });
}
