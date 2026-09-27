import 'package:flutter/material.dart';

class LabColor {
  final double L;
  final double a;
  final double b;

  const LabColor({required this.L, required this.a, required this.b});

  Map<String, dynamic> toJson() => {'L': L, 'a': a, 'b': b};

  factory LabColor.fromJson(Map<String, dynamic> json) => LabColor(
        L: (json['L'] as num).toDouble(),
        a: (json['a'] as num).toDouble(),
        b: (json['b'] as num).toDouble(),
      );

  @override
  String toString() => 'L:${L.toStringAsFixed(1)}, a:${a.toStringAsFixed(1)}, b:${b.toStringAsFixed(1)}';
}

class ReagentOutcome {
  final String id;
  final String label;
  final String category; // 'POSITIVE', 'NEGATIVE', 'INCONCLUSIVE'
  final String substance;
  final Color expectedColor;
  final LabColor targetLab;
  final double toleranceDeltaE;
  final String description;
  final String? warningBadge;

  const ReagentOutcome({
    required this.id,
    required this.label,
    required this.category,
    required this.substance,
    required this.expectedColor,
    required this.targetLab,
    required this.toleranceDeltaE,
    required this.description,
    this.warningBadge,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'category': category,
        'substance': substance,
        'expectedColorHex': '#${expectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        'targetLab': targetLab.toJson(),
        'toleranceDeltaE': toleranceDeltaE,
        'description': description,
        'warningBadge': warningBadge,
      };
}

class ReagentKit {
  final String id;
  final String name;
  final String brand;
  final String description;
  final String activeChemicals;
  final int reactionDurationSeconds;
  final List<ReagentOutcome> outcomes;

  const ReagentKit({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.activeChemicals,
    required this.reactionDurationSeconds,
    required this.outcomes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'description': description,
        'activeChemicals': activeChemicals,
        'reactionDurationSeconds': reactionDurationSeconds,
      };

  static final List<ReagentKit> standardKits = [
    ReagentKit(
      id: 'marquis',
      name: 'Marquis Reagent',
      brand: 'NIK Test A / NarcPouch 902',
      description: 'General screening for Opioids, Amphetamines, and MDMA',
      activeChemicals: 'Formaldehyde and concentrated Sulfuric Acid (9:1)',
      reactionDurationSeconds: 15,
      outcomes: [
        ReagentOutcome(
          id: 'marquis_opiates',
          label: 'POSITIVE (Opiates / Morphine / Heroin)',
          category: 'POSITIVE',
          substance: 'Morphine, Heroin, Codeine or related Opiates',
          expectedColor: const Color(0xFF58185F),
          targetLab: const LabColor(L: 20.4, a: 34.2, b: -18.5),
          toleranceDeltaE: 24.0,
          description: 'Immediate vibrant violet to deep reddish-purple reaction',
          warningBadge: 'Schedule I / II Narcotic Indicated',
        ),
        ReagentOutcome(
          id: 'marquis_meth',
          label: 'POSITIVE (Amphetamine / Methamphetamine)',
          category: 'POSITIVE',
          substance: 'Amphetamine or Methamphetamine',
          expectedColor: const Color(0xFFB55315),
          targetLab: const LabColor(L: 45.2, a: 42.1, b: 50.3),
          toleranceDeltaE: 22.0,
          description: 'Rapid orange-yellow shifting to deep orange-brown',
          warningBadge: 'Schedule II Stimulant Indicated',
        ),
        ReagentOutcome(
          id: 'marquis_mdma',
          label: 'POSITIVE (MDMA / Ecstasy / MDA)',
          category: 'POSITIVE',
          substance: 'MDMA, MDA, or MDE',
          expectedColor: const Color(0xFF181028),
          targetLab: const LabColor(L: 8.5, a: 10.2, b: -12.1),
          toleranceDeltaE: 20.0,
          description: 'Rapid dark purple shifting to near black within 5 seconds',
          warningBadge: 'Schedule I Hallucinogen/Entactogen Indicated',
        ),
        ReagentOutcome(
          id: 'marquis_negative',
          label: 'NEGATIVE (No Presumptive Reaction)',
          category: 'NEGATIVE',
          substance: 'None Detected / Non-reactive excipient',
          expectedColor: const Color(0xFFEAE5C8),
          targetLab: const LabColor(L: 90.2, a: -3.1, b: 15.4),
          toleranceDeltaE: 22.0,
          description: 'Reagent remains clear or pale straw-yellow without color transition',
          warningBadge: 'No Active Substance Indicated',
        ),
      ],
    ),
    ReagentKit(
      id: 'scott',
      name: 'Scott Reagent (Cobalt Thiocyanate)',
      brand: 'NIK Test G / NarcPouch 907',
      description: 'Specific presumptive test for Cocaine HCl and Cocaine Base (Crack)',
      activeChemicals: '2% Cobalt Thiocyanate, conc. HCl, Chloroform',
      reactionDurationSeconds: 20,
      outcomes: [
        ReagentOutcome(
          id: 'scott_cocaine',
          label: 'POSITIVE (Cocaine HCl / Cocaine Base)',
          category: 'POSITIVE',
          substance: 'Cocaine Hydrochloride or Freebase Cocaine (Crack)',
          expectedColor: const Color(0xFF0863A5),
          targetLab: const LabColor(L: 38.6, a: -4.5, b: -38.2),
          toleranceDeltaE: 26.0,
          description: 'Intense cobalt blue precipitate / blue organic lower phase separation',
          warningBadge: 'Schedule II Narcotic Indicated',
        ),
        ReagentOutcome(
          id: 'scott_negative',
          label: 'NEGATIVE (No Cocaine Detected)',
          category: 'NEGATIVE',
          substance: 'None Detected / Common Cutting Agent',
          expectedColor: const Color(0xFFEAD3D9),
          targetLab: const LabColor(L: 86.4, a: 8.2, b: 2.1),
          toleranceDeltaE: 22.0,
          description: 'Fails to form blue precipitate or organic layer remains clear/pink',
          warningBadge: 'No Active Substance Indicated',
        ),
      ],
    ),
    ReagentKit(
      id: 'duquenois',
      name: 'Duquenois-Levine Reagent',
      brand: 'NIK Test E / NarcPouch 905',
      description: 'Specific presumptive identification of Marijuana / THC / Cannabinoids',
      activeChemicals: 'Acetaldehyde, Vanillin, conc. Hydrochloric Acid, Chloroform',
      reactionDurationSeconds: 30,
      outcomes: [
        ReagentOutcome(
          id: 'duquenois_thc',
          label: 'POSITIVE (Cannabinoids / THC)',
          category: 'POSITIVE',
          substance: 'Delta-9-THC, Hashish, Cannabis Resin or Plant Material',
          expectedColor: const Color(0xFF4C1055),
          targetLab: const LabColor(L: 18.2, a: 32.5, b: -20.4),
          toleranceDeltaE: 24.0,
          description: 'Formation of deep purple-violet color which extracts into chloroform layer',
          warningBadge: 'Controlled Cannabinoid Indicated',
        ),
        ReagentOutcome(
          id: 'duquenois_negative',
          label: 'NEGATIVE (No Cannabinoids Detected)',
          category: 'NEGATIVE',
          substance: 'None Detected',
          expectedColor: const Color(0xFFD4C9A0),
          targetLab: const LabColor(L: 80.5, a: -3.5, b: 22.0),
          toleranceDeltaE: 25.0,
          description: 'Lower organic layer remains colorless or pale straw tint',
          warningBadge: 'No Active Substance Indicated',
        ),
      ],
    ),
    ReagentKit(
      id: 'mecke',
      name: 'Mecke Reagent',
      brand: 'NIK Test M / NarcPouch 913',
      description: 'Confirmatory screen for Heroin and Opium Alkaloids',
      activeChemicals: 'Selenious acid in concentrated Sulfuric Acid',
      reactionDurationSeconds: 15,
      outcomes: [
        ReagentOutcome(
          id: 'mecke_heroin',
          label: 'POSITIVE (Heroin / Opium Alkaloids)',
          category: 'POSITIVE',
          substance: 'Diacetylmorphine (Heroin) or Opium Derivatives',
          expectedColor: const Color(0xFF124E38),
          targetLab: const LabColor(L: 28.5, a: -22.4, b: 4.8),
          toleranceDeltaE: 24.0,
          description: 'Immediate deep green turning to dark blue-green',
          warningBadge: 'Schedule I Opiate Indicated',
        ),
        ReagentOutcome(
          id: 'mecke_negative',
          label: 'NEGATIVE (No Opiates Detected)',
          category: 'NEGATIVE',
          substance: 'None Detected',
          expectedColor: const Color(0xFFEAE8CE),
          targetLab: const LabColor(L: 91.0, a: -4.0, b: 12.0),
          toleranceDeltaE: 22.0,
          description: 'Reagent remains clear or pale straw-yellow',
          warningBadge: 'No Active Substance Indicated',
        ),
      ],
    ),
    ReagentKit(
      id: 'ehrlich',
      name: 'Ehrlich Reagent (Van Urk)',
      brand: 'NIK Test B / NarcPouch 903',
      description: 'Screening for LSD, Indoles, and Psilocybin',
      activeChemicals: 'p-Dimethylaminobenzaldehyde in Ethanol and conc. HCl',
      reactionDurationSeconds: 60,
      outcomes: [
        ReagentOutcome(
          id: 'ehrlich_lsd',
          label: 'POSITIVE (LSD / Indoles / Psilocybin)',
          category: 'POSITIVE',
          substance: 'Lysergic Acid Diethylamide (LSD) or Indole Alkaloids',
          expectedColor: const Color(0xFF8C1E6D),
          targetLab: const LabColor(L: 32.4, a: 48.2, b: -14.1),
          toleranceDeltaE: 22.0,
          description: 'Slow development of rich violet-magenta within 1 to 2 minutes',
          warningBadge: 'Schedule I Indole Indicated',
        ),
        ReagentOutcome(
          id: 'ehrlich_negative',
          label: 'NEGATIVE (No Indoles Detected)',
          category: 'NEGATIVE',
          substance: 'None Detected',
          expectedColor: const Color(0xFFE8DFBD),
          targetLab: const LabColor(L: 88.0, a: -2.0, b: 16.0),
          toleranceDeltaE: 22.0,
          description: 'No chromophoric shift observed',
          warningBadge: 'No Active Substance Indicated',
        ),
      ],
    ),
    ReagentKit(
      id: 'fentanyl_strip',
      name: 'Fentanyl Lateral-Flow Immunoassay',
      brand: 'Rapid Response / BTNX Field Immunoassay',
      description: 'Ultra-sensitive detection of Fentanyl and high-potency analogues (20 ng/mL cut-off)',
      activeChemicals: 'Colloidal Gold conjugated antibody competitive binding',
      reactionDurationSeconds: 120,
      outcomes: [
        ReagentOutcome(
          id: 'fentanyl_positive',
          label: 'POSITIVE (Fentanyl / Analogues Detected)',
          category: 'POSITIVE',
          substance: 'Fentanyl, Carfentanil, or Fluorofentanyl',
          expectedColor: const Color(0xFF881A24),
          targetLab: const LabColor(L: 26.2, a: 42.1, b: 18.5),
          toleranceDeltaE: 25.0,
          description: 'Single red control line (C-Line only). Test line (T-Line) absent.',
          warningBadge: 'EXTREME LETHALITY HAZARD: Schedule II Synthetic Opioid',
        ),
        ReagentOutcome(
          id: 'fentanyl_negative',
          label: 'NEGATIVE (Two Bands Present)',
          category: 'NEGATIVE',
          substance: 'Fentanyl Not Detected (< 20 ng/mL)',
          expectedColor: const Color(0xFF526A5A),
          targetLab: const LabColor(L: 42.0, a: -12.0, b: 6.0),
          toleranceDeltaE: 28.0,
          description: 'Two visible lines: both Control (C) and Test (T) lines appear.',
          warningBadge: 'Negative for Tested Analogues',
        ),
      ],
    ),
  ];
}
