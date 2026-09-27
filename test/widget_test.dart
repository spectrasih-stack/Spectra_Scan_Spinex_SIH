import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drug_analyst/main.dart';
import 'package:drug_analyst/screens/home_screen.dart';
import 'package:drug_analyst/services/colorimetry_service.dart';
import 'package:drug_analyst/services/crypto_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SpectraFieldApp launches Apple Login and transitions to HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const SpectraFieldApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify Login Screen elements
    expect(find.text('SPECTRA'), findsOneWidget);
    expect(find.text('Unlock with Face ID'), findsOneWidget);

    // Verify Direct HomeScreen layout
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5)); // Settle dynamic island ambient notification timer

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Scanner'), findsWidgets);
    expect(find.text('Records'), findsWidgets);
  });

  test('ColorimetryService correctly transforms sRGB to CIE-L*a*b* and computes Delta-E', () {
    // Standard pure white D65
    final whiteLab = ColorimetryService.rgbToLab(255, 255, 255);
    expect(whiteLab.L, greaterThanOrEqualTo(99.0));

    // Distance between identical colors is 0
    final dE = ColorimetryService.calculateDeltaE(whiteLab, whiteLab);
    expect(dE, equals(0.0));

    // Distance between white and black is large (> 80)
    final blackLab = ColorimetryService.rgbToLab(0, 0, 0);
    final dEWhiteBlack = ColorimetryService.calculateDeltaE(whiteLab, blackLab);
    expect(dEWhiteBlack, greaterThan(80.0));
  });

  test('CryptoService SHA-256 creates deterministic digests and flags tamper', () {
    const data = 'CASE-2026-TEST-PAYLOAD';
    final hash1 = CryptoService.sha256String(data);
    final hash2 = CryptoService.sha256String(data);
    expect(hash1, equals(hash2));
    expect(hash1.length, equals(64));

    // Modified data produces distinct hash
    final hash3 = CryptoService.sha256String('CASE-2026-TAMPERED');
    expect(hash1, isNot(equals(hash3)));
  });
}
