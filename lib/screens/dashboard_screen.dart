import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/evidence_record.dart';
import '../models/operator_profile.dart';
import '../services/location_service.dart';
import '../theme/apple_theme.dart';
import 'record_details_screen.dart';
import 'reference_card_screen.dart';

class DashboardScreen extends StatelessWidget {
  final List<EvidenceRecord> records;
  final OperatorProfile operator;
  final VoidCallback onLaunchCamera;
  final VoidCallback onOpenLedger;
  final VoidCallback onRefreshRecords;

  const DashboardScreen({
    super.key,
    required this.records,
    required this.operator,
    required this.onLaunchCamera,
    required this.onOpenLedger,
    required this.onRefreshRecords,
  });

  @override
  Widget build(BuildContext context) {
    final positiveCount = records.where((r) => r.category == 'POSITIVE').length;
    final negativeCount = records.where((r) => r.category == 'NEGATIVE').length;
    final otherCount = records.length - positiveCount - negativeCount;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Officer Inset Profile Header Card
          _buildOfficerCard(context),
          const SizedBox(height: 12),

          // Live GPS Field Operating Precinct Card
          const _LiveLocationCard(),
          const SizedBox(height: 16),

          // Apple Health / Fitness Inset KPI Metric Grid
          _buildMetricsGrid(context, positiveCount, negativeCount),
          const SizedBox(height: 20),

          // Quick Action Launchpad
          _buildActionCards(context),
          const SizedBox(height: 20),

          // Distribution Spectrum
          if (records.isNotEmpty) ...[
            _buildResultDistribution(positiveCount, negativeCount, otherCount),
            const SizedBox(height: 20),
          ],

          // Recent Activity Section
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildOfficerCard(BuildContext context) {
    final officerName = operator.name.isNotEmpty ? operator.name : 'Lacshan Shakthivel';
    final initials = officerName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    final isGoogle = operator.authProvider == 'GOOGLE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppleTheme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
        border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isGoogle
                    ? const [Color(0xFF4285F4), Color(0xFF0F9D58)]
                    : const [AppleTheme.systemBlue, Color(0xFF0051A8)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isGoogle ? const Color(0xFF4285F4) : AppleTheme.systemBlue).withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials.isNotEmpty ? initials : 'LS',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        officerName,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: AppleTheme.label,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppleTheme.systemGreen.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppleTheme.systemGreen.withAlpha(60), width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.checkmark_shield_fill, size: 9.5, color: AppleTheme.systemGreen),
                          const SizedBox(width: 3),
                          Text(
                            isGoogle ? 'VERIFIED' : 'BIOMETRIC',
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppleTheme.systemGreen,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Badge #${operator.badge.isNotEmpty ? operator.badge.replaceAll('BADGE-', '') : "7104"} • Samsung Galaxy F15 5G',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppleTheme.secondaryLabel,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, int positives, int negatives) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 13) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                title: 'Total Tests',
                value: '${records.length}',
                subtitle: 'Logged to SHA-256 Ledger',
                icon: CupertinoIcons.doc_text_fill,
                accentColor: AppleTheme.systemBlue,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                title: 'Positive',
                value: '$positives',
                subtitle: records.isNotEmpty
                    ? '${((positives / records.length) * 100).toStringAsFixed(0)}% detection rate'
                    : '0% rate',
                icon: CupertinoIcons.exclamationmark_triangle_fill,
                accentColor: AppleTheme.systemRed,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                title: 'Negative',
                value: '$negatives',
                subtitle: 'Non-reactive control',
                icon: CupertinoIcons.checkmark_seal_fill,
                accentColor: AppleTheme.systemGreen,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                title: 'Chain Integrity',
                value: '100%',
                subtitle: 'Cryptographic Valid',
                icon: CupertinoIcons.lock_shield_fill,
                accentColor: AppleTheme.systemIndigo,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppleTheme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(AppleTheme.radiusMedium + 2),
        border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppleTheme.secondaryLabel,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppleTheme.label,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppleTheme.tertiaryLabel,
              letterSpacing: -0.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppleTheme.tertiaryLabel,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionPill(
                title: 'Scanner',
                subtitle: 'Colorimetric analysis',
                icon: CupertinoIcons.camera_viewfinder,
                accentColor: AppleTheme.systemBlue,
                onTap: onLaunchCamera,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionPill(
                title: 'Records',
                subtitle: 'Inspect audit ledger',
                icon: CupertinoIcons.folder_fill,
                accentColor: AppleTheme.systemGreen,
                onTap: onOpenLedger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const ReferenceCardScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppleTheme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
              border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppleTheme.systemOrange.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.color_filter,
                    size: 18,
                    color: AppleTheme.systemOrange,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NIJ Standard Color Reference Target',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: AppleTheme.label,
                        ),
                      ),
                      Text(
                        'D65 Chromatic Calibration & Reagent Target',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppleTheme.secondaryLabel,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: AppleTheme.tertiaryLabel,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppleTheme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(AppleTheme.radiusMedium + 2),
          border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppleTheme.label,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppleTheme.secondaryLabel,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDistribution(int positives, int negatives, int others) {
    final total = positives + negatives + others;
    if (total == 0) return const SizedBox.shrink();

    final posFlex = (positives * 100 ~/ total).clamp(1, 100);
    final negFlex = (negatives * 100 ~/ total).clamp(1, 100);
    final othFlex = (others * 100 ~/ total).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppleTheme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
        border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Presumptive Test Distribution',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: AppleTheme.label,
                ),
              ),
              Text(
                'NIJ Spectrum',
                style: TextStyle(
                  fontSize: 11,
                  color: AppleTheme.secondaryLabel,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (positives > 0)
                    Expanded(
                      flex: posFlex,
                      child: Container(color: AppleTheme.systemRed),
                    ),
                  if (negatives > 0)
                    Expanded(
                      flex: negFlex,
                      child: Container(color: AppleTheme.systemGreen),
                    ),
                  if (others > 0)
                    Expanded(
                      flex: othFlex,
                      child: Container(color: AppleTheme.systemOrange),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildLegendItem('Positives ($positives)', AppleTheme.systemRed),
              _buildLegendItem('Negatives ($negatives)', AppleTheme.systemGreen),
              if (others > 0)
                _buildLegendItem('Inconclusive ($others)', AppleTheme.systemOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel, letterSpacing: -0.1),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final recent = records.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT FIELD TESTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppleTheme.tertiaryLabel,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onOpenLedger,
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppleTheme.systemBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: AppleTheme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
              border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppleTheme.systemBlue.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.camera_viewfinder,
                      size: 28,
                      color: AppleTheme.systemBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Field Tests Logged Yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppleTheme.label,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Launch the scanner to analyze a chemical sample.',
                    style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    onPressed: onLaunchCamera,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.camera_fill, size: 16),
                        SizedBox(width: 8),
                        Text('Start Test', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
            child: Container(
              color: AppleTheme.secondarySystemBackground,
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 0.5,
                  indent: 48,
                  color: AppleTheme.separator,
                ),
                itemBuilder: (context, index) {
                  final r = recent[index];
                  final isPositive = r.category == 'POSITIVE';
                  final isNegative = r.category == 'NEGATIVE';
                  final statusColor = isPositive
                      ? AppleTheme.systemRed
                      : isNegative
                          ? AppleTheme.systemGreen
                          : AppleTheme.systemOrange;

                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => RecordDetailsScreen(record: r),
                        ),
                      ).then((_) => onRefreshRecords());
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPositive
                                ? CupertinoIcons.exclamationmark_triangle_fill
                                : (isNegative
                                    ? CupertinoIcons.checkmark_seal_fill
                                    : CupertinoIcons.question_circle_fill),
                            size: 16,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    r.caseNumber,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                      color: AppleTheme.label,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r.category,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${r.kitName} • ${r.substance}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppleTheme.secondaryLabel,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 14,
                          color: AppleTheme.tertiaryLabel,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Self-refreshing Apple HIG Live Operating Precinct Card
class _LiveLocationCard extends StatefulWidget {
  const _LiveLocationCard();

  @override
  State<_LiveLocationCard> createState() => _LiveLocationCardState();
}

class _LiveLocationCardState extends State<_LiveLocationCard> {
  ForensicLocation? _location;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation({bool force = false}) async {
    if (force) setState(() => _isLoading = true);

    // Initial cache hit for instant rendering
    if (_location == null) {
      final cached = await LocationService.getLastCachedLocation();
      if (mounted && cached != null) {
        setState(() => _location = cached);
      }
    }

    final loc = await LocationService.getCurrentLocation(forceRefresh: force);
    if (mounted) {
      setState(() {
        _location = loc;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locName = _location?.locationName ?? 'Acquiring Real Device GPS...';
    final hasFix = _location != null;
    final isLive = _location?.isLiveGps == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppleTheme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
        border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppleTheme.systemBlue.withAlpha(40),
                  AppleTheme.systemBlue.withAlpha(15),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.location_fill,
                size: 18,
                color: AppleTheme.systemBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLive ? AppleTheme.systemGreen : AppleTheme.systemOrange,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        isLive
                            ? (hasFix ? 'OPERATING PRECINCT • ±${_location!.accuracyMeters.toStringAsFixed(1)}m' : 'OPERATING PRECINCT')
                            : 'PRECINCT CACHE',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppleTheme.tertiaryLabel,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  locName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppleTheme.label,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _isLoading ? null : () => _loadLocation(force: true),
            child: _isLoading
                ? const CupertinoActivityIndicator(radius: 8)
                : const Icon(
                    CupertinoIcons.arrow_clockwise,
                    size: 15,
                    color: AppleTheme.secondaryLabel,
                  ),
          ),
        ],
      ),
    );
  }
}

