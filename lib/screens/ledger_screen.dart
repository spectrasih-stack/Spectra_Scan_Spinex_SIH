import 'package:flutter/cupertino.dart';
import '../models/evidence_record.dart';
import '../services/biometric_gate_service.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';
import '../theme/apple_theme.dart';
import 'record_details_screen.dart';

class LedgerScreen extends StatefulWidget {
  final List<EvidenceRecord> records;
  final VoidCallback onRefreshRecords;

  const LedgerScreen({
    super.key,
    required this.records,
    required this.onRefreshRecords,
  });

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  String _searchQuery = '';
  String _categoryFilter = 'ALL';
  LedgerAuditReport? _auditReport;
  bool _isAuditing = false;

  void _runAudit() {
    setState(() => _isAuditing = true);
    final report = CryptoService.verifyEntireLedger(widget.records);
    setState(() {
      _auditReport = report;
      _isAuditing = false;
    });
  }

  Future<void> _handleDeleteRecord(EvidenceRecord record) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: CupertinoAlertDialog(
          title: const Text('Delete Evidence Record?'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Permanently remove case ${record.caseNumber} from this local device? This cannot be undone.'),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final biometricOk = await BiometricGateService.requireAuthorization(
        context,
        title: 'Biometric Clearance',
        reason: 'Authenticate with Face ID or biometrics to permanently delete case ${record.caseNumber}.',
      );
      if (!biometricOk) return;

      await StorageService.deleteRecord(record.id);
      widget.onRefreshRecords();
    }
  }

  Future<void> _handleResetLedger() async {
    final biometricOk = await BiometricGateService.requireAuthorization(
      context,
      title: 'Purge Ledger Chain',
      reason: 'Authenticate with Face ID or biometrics to reset the evidence chain.',
    );
    if (!biometricOk) return;

    await StorageService.resetLedger();
    setState(() => _auditReport = null);
    widget.onRefreshRecords();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.records.where((r) {
      final matchesCategory = _categoryFilter == 'ALL' || r.category == _categoryFilter;
      final q = _searchQuery.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          r.caseNumber.toLowerCase().contains(q) ||
          r.operator.badge.toLowerCase().contains(q) ||
          r.operator.name.toLowerCase().contains(q) ||
          r.kitName.toLowerCase().contains(q) ||
          r.substance.toLowerCase().contains(q) ||
          r.label.toLowerCase().contains(q);

      return matchesCategory && matchesQuery;
    }).toList();

    return Column(
      children: [
        // Action Bar & Audit Toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Field (Apple HIG)
              CupertinoSearchTextField(
                placeholder: 'Search case, officer, substance...',
                style: const TextStyle(color: AppleTheme.label),
                placeholderStyle: const TextStyle(color: AppleTheme.tertiaryLabel),
                backgroundColor: AppleTheme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 10),

              // Sliding Segmented Control (ALL, POSITIVE, NEGATIVE, INCONCLUSIVE)
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: CupertinoSlidingSegmentedControl<String>(
                    backgroundColor: AppleTheme.secondarySystemBackground,
                    thumbColor: AppleTheme.tertiarySystemBackground,
                    groupValue: _categoryFilter,
                    children: const {
                      'ALL': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.label)),
                      ),
                      'POSITIVE': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('Positive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.systemRed)),
                      ),
                      'NEGATIVE': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('Negative', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.systemGreen)),
                      ),
                      'INCONCLUSIVE': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('Inconclusive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.systemOrange)),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) setState(() => _categoryFilter = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Integrity Verification Buttons
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: AppleTheme.systemBlue.withAlpha(40),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _isAuditing ? null : _runAudit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.shield_lefthalf_fill, size: 16, color: AppleTheme.systemBlue),
                          const SizedBox(width: 8),
                          Text(
                            _isAuditing ? 'Auditing Blocks...' : 'Verify Chain Integrity',
                            style: const TextStyle(
                              color: AppleTheme.systemBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    color: AppleTheme.secondarySystemBackground,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _handleResetLedger,
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.arrow_counterclockwise, size: 14, color: AppleTheme.secondaryLabel),
                        SizedBox(width: 4),
                        Text(
                          'Reset',
                          style: TextStyle(color: AppleTheme.secondaryLabel, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Apple Security Report Banner
              if (_auditReport != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _auditReport!.isAllValid
                        ? AppleTheme.systemGreen.withAlpha(25)
                        : AppleTheme.systemRed.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _auditReport!.isAllValid
                          ? AppleTheme.systemGreen.withAlpha(80)
                          : AppleTheme.systemRed.withAlpha(80),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _auditReport!.isAllValid
                            ? CupertinoIcons.checkmark_seal_fill
                            : CupertinoIcons.exclamationmark_triangle_fill,
                        color: _auditReport!.isAllValid ? AppleTheme.systemGreen : AppleTheme.systemRed,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _auditReport!.isAllValid
                                  ? 'CRYPTOGRAPHIC INTEGRITY CONFIRMED'
                                  : 'INTEGRITY BREACH DETECTED',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _auditReport!.isAllValid ? AppleTheme.systemGreen : AppleTheme.systemRed,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Verified ${_auditReport!.totalRecords} SHA-256 blocks and hash linkages.',
                              style: const TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.clear_circled_solid, size: 18, color: AppleTheme.tertiaryLabel),
                        onPressed: () => setState(() => _auditReport = null),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Records Inset Grouped List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.folder, size: 44, color: AppleTheme.tertiaryLabel),
                      const SizedBox(height: 10),
                      const Text(
                        'No evidence records found',
                        style: TextStyle(fontSize: 14, color: AppleTheme.secondaryLabel, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final record = filtered[index];
                    final isPos = record.category == 'POSITIVE';
                    final isNeg = record.category == 'NEGATIVE';
                    final catColor = isPos
                        ? AppleTheme.systemRed
                        : isNeg
                            ? AppleTheme.systemGreen
                            : AppleTheme.systemOrange;

                    final isTampered = record.isTamperedSimulation;
                    final prevRecord = index < filtered.length - 1 ? filtered[index + 1] : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isTampered ? const Color(0xFF261014) : AppleTheme.secondarySystemBackground,
                        borderRadius: BorderRadius.circular(AppleTheme.radiusMedium + 2),
                        border: Border.all(
                          color: isTampered ? AppleTheme.systemRed : AppleTheme.hairlineBorder,
                          width: isTampered ? 1.5 : 0.5,
                        ),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(14),
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => RecordDetailsScreen(
                                record: record,
                                previousRecord: prevRecord,
                              ),
                            ),
                          ).then((_) => widget.onRefreshRecords());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Case Header & Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    record.caseNumber,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                      color: AppleTheme.label,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: catColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${record.category} (${record.confidence}%)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: catColor,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Substance & Kit Details
                            Text(
                              record.substance,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: AppleTheme.label,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${record.kitName} • ${record.timestampFormatted}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppleTheme.secondaryLabel,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.location_solid, size: 11, color: AppleTheme.systemBlue),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    record.address.isNotEmpty ? record.address : 'Field Operations Sector',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppleTheme.secondaryLabel,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Hash Pill & Tamper Action
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppleTheme.tertiarySystemBackground,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'SHA: ${record.recordHash.substring(0, 16)}...',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontFamily: 'monospace',
                                        color: AppleTheme.systemTeal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  color: AppleTheme.tertiarySystemBackground,
                                  borderRadius: BorderRadius.circular(6),
                                  onPressed: () => _handleDeleteRecord(record),
                                  child: const Icon(
                                    CupertinoIcons.trash,
                                    size: 13,
                                    color: AppleTheme.secondaryLabel,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  CupertinoIcons.chevron_forward,
                                  size: 14,
                                  color: AppleTheme.tertiaryLabel,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
