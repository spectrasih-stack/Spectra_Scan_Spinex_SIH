import 'package:flutter/material.dart';
import '../theme/apple_theme.dart';
import '../theme/tactical_theme.dart';

class ReferenceCardScreen extends StatelessWidget {
  const ReferenceCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleTheme.systemBackground,
      appBar: AppBar(
        title: const Text('Calibration Target'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TacticalTheme.accentEmerald.withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified, color: TacticalTheme.accentEmerald, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forensic Color Reference Card',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Standard D65 / 18% Gray Chromatic Target (ISO 17025)',
                          style: TextStyle(fontSize: 12, color: TacticalTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Digital Displayable Calibration Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Header of Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'SPECTRA-FIELD CALIBRATION TARGET',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'REF: D65 / ISO-17025 STANDARD',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'LOT: 2026-X9\nSERIAL: FID-884',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 9,
                        fontFamily: 'monospace',
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 16),

                // Primary Target Patches: White, 18% Gray, Black
                Row(
                  children: [
                    // White 100% Patch
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF94A3B8), width: 2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'WHITE',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const Text(
                            '100% R (D65)',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 18% Neutral Gray Patch
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF808080),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF64748B), width: 2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '18% GRAY',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const Text(
                            'Reflectance Anchor',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Deep Black Patch
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155), width: 2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'BLACK',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const Text(
                            '0% Baseline',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Alignment Crosshairs & Fiducial Rulers
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.crop_free, color: Colors.blue.shade700, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'ALIGNMENT RETICLE\nMatch camera HUD guide',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      // Forensic color strips
                      Row(
                        children: [
                          for (final col in [
                            const Color(0xFFDC2626),
                            const Color(0xFF16A34A),
                            const Color(0xFF2563EB),
                            const Color(0xFFEAB308),
                            const Color(0xFF06B6D4),
                          ])
                            Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: col,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Operational Field Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: TacticalTheme.textAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Why In-Frame Calibration is Mandatory',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: TacticalTheme.textAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ambient field lighting (e.g. patrol car interior spotlights, warm sodium streetlights, overcast twilight) introduces drastic chromatic shifts that can make a positive purple opioid reaction appear brown, or a cobalt blue cocaine precipitate appear greenish. '
                    'The in-frame 18% neutral gray and white patches allow the app to calculate chromatic adaptation gains (kR, kG, kB) to normalize lighting directly on-device.',
                    style: TextStyle(fontSize: 12, color: TacticalTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  _buildInstructionItem(
                    Icons.check_circle_outline,
                    'Positioning',
                    'Place this card flat on the inspection surface directly beside the test ampoule/pouch.',
                  ),
                  _buildInstructionItem(
                    Icons.check_circle_outline,
                    'Anti-Glare',
                    'Angle the camera slightly to avoid direct specular glare or flash bounce on the glass/plastic.',
                  ),
                  _buildInstructionItem(
                    Icons.check_circle_outline,
                    'Dual-Screen Field Mode',
                    'If no physical printed card is available in the patrol kit, display this screen on a partner officer’s phone in-frame.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildInstructionItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: TacticalTheme.accentEmerald, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: TacticalTheme.textPrimary, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: subtitle, style: const TextStyle(color: TacticalTheme.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
