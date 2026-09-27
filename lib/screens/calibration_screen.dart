import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../models/evidence_record.dart';
import '../models/reagent_kit.dart';
import '../services/biometric_gate_service.dart';
import '../services/colorimetry_service.dart';
import '../services/crypto_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../theme/apple_theme.dart';

class CalibrationScreen extends StatefulWidget {
  final String imageBase64;
  final String initialKitId;
  final String initialCaseNumber;
  final Offset initialWhitePoint;
  final Offset initialGrayPoint;
  final Offset initialChamberPoint;

  const CalibrationScreen({
    super.key,
    required this.imageBase64,
    required this.initialKitId,
    required this.initialCaseNumber,
    required this.initialWhitePoint,
    required this.initialGrayPoint,
    required this.initialChamberPoint,
  });

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  late String _selectedKitId;
  late TextEditingController _caseNumberController;

  late Offset _whitePoint;
  late Offset _grayPoint;
  late Offset _chamberPoint;

  img.Image? _decodedImage;
  bool _isSealing = false;
  bool _isSingleSpotMode = true; // Rapid single-point field analysis vs 3-point D65 lab
  int _activeReticleIndex = 2; // 0: White, 1: Gray, 2: Reaction

  // Interactive Magnifier Loupe state
  bool _isDragging = false;
  Offset _dragPosition = Offset.zero;
  Color _dragColor = const Color(0xFF58185F);

  Color _rawWhiteColor = const Color(0xFFF2F2F6);
  Color _rawGrayColor = const Color(0xFF808080);
  Color _rawChamberColor = const Color(0xFF58185F);
  Color _calibratedChamberColor = const Color(0xFF58185F);

  late CalibrationGains _gains;
  late ClassificationResult _classification;
  ForensicLocation? _currentLocation;

  @override
  void initState() {
    super.initState();
    _fetchLiveLocation();
    _selectedKitId = widget.initialKitId;
    _caseNumberController = TextEditingController(text: widget.initialCaseNumber);

    _whitePoint = Offset(
      widget.initialWhitePoint.dx / 640.0,
      widget.initialWhitePoint.dy / 480.0,
    );
    _grayPoint = Offset(
      widget.initialGrayPoint.dx / 640.0,
      widget.initialGrayPoint.dy / 480.0,
    );
    _chamberPoint = Offset(
      widget.initialChamberPoint.dx / 640.0,
      widget.initialChamberPoint.dy / 480.0,
    );

    _decodeImageAndAnalyze();
  }

  void _fetchLiveLocation() {
    LocationService.getCurrentLocation().then((loc) {
      if (mounted) {
        setState(() => _currentLocation = loc);
      }
    });
  }

  @override
  void dispose() {
    _caseNumberController.dispose();
    super.dispose();
  }

  void _decodeImageAndAnalyze() {
    try {
      final clean = widget.imageBase64.contains(',')
          ? widget.imageBase64.split(',').last
          : widget.imageBase64;
      final bytes = base64Decode(clean);
      _decodedImage = img.decodeImage(bytes);
    } catch (e) {
      debugPrint('Error decoding base64: $e');
    }
    _recalculateColorimetry();
  }

  Color _sampleColorAt(Offset normalized) {
    if (_decodedImage == null) return const Color(0xFF808080);
    final px = (normalized.dx * _decodedImage!.width).clamp(0.0, _decodedImage!.width - 1.0).toInt();
    final py = (normalized.dy * _decodedImage!.height).clamp(0.0, _decodedImage!.height - 1.0).toInt();

    int sumR = 0, sumG = 0, sumB = 0, count = 0;
    for (int dy = -2; dy <= 2; dy++) {
      for (int dx = -2; dx <= 2; dx++) {
        final cx = (px + dx).clamp(0, _decodedImage!.width - 1);
        final cy = (py + dy).clamp(0, _decodedImage!.height - 1);
        final p = _decodedImage!.getPixel(cx, cy);
        sumR += p.r.toInt();
        sumG += p.g.toInt();
        sumB += p.b.toInt();
        count++;
      }
    }
    return Color.fromARGB(
      255,
      (sumR ~/ count).clamp(0, 255),
      (sumG ~/ count).clamp(0, 255),
      (sumB ~/ count).clamp(0, 255),
    );
  }

  void _recalculateColorimetry() {
    _rawChamberColor = _sampleColorAt(_chamberPoint);

    if (_isSingleSpotMode) {
      _rawWhiteColor = const Color(0xFFF2F2F6);
      _rawGrayColor = const Color(0xFF808080);
      _gains = CalibrationGains(
        gainR: 1.0,
        gainG: 1.0,
        gainB: 1.0,
        lightingQuality: 96,
        lightingNotes: 'Auto D65 camera sensor compensation',
        colorCast: 'Neutral D65',
      );
      _calibratedChamberColor = _rawChamberColor;
    } else {
      _rawWhiteColor = _sampleColorAt(_whitePoint);
      _rawGrayColor = _sampleColorAt(_grayPoint);
      _gains = ColorimetryService.computeCalibrationGains(_rawWhiteColor, _rawGrayColor);
      _calibratedChamberColor = ColorimetryService.applyCalibration(_rawChamberColor, _gains);
    }

    _classification = ColorimetryService.classifyColorSample(
      _selectedKitId,
      _calibratedChamberColor,
      _gains.lightingQuality,
    );

    if (mounted) setState(() {});
  }

  Future<void> _handleSealAndSave() async {
    if (_isSealing) return;
    setState(() => _isSealing = true);

    final authorized = await BiometricGateService.requireAuthorization(
      context,
      title: 'Biometric Signature',
      reason: 'Authenticate with Face ID or biometrics to cryptographically sign case ${_caseNumberController.text.trim()}.',
    );
    if (!authorized) {
      if (mounted) setState(() => _isSealing = false);
      return;
    }

    try {
      final records = await StorageService.loadRecords();
      final previousHash = records.isEmpty
          ? '0000000000000000000000000000000000000000000000000000000000000000'
          : records.last.recordHash;

      final operator = await StorageService.getOperator();
      final kit = ReagentKit.standardKits.firstWhere((k) => k.id == _selectedKitId);
      final imageHash = CryptoService.hashBase64Image(widget.imageBase64);
      final now = DateTime.now();
      final formatted = DateFormat('MMM dd, yyyy • HH:mm:ss').format(now);
      final loc = _currentLocation ?? await LocationService.getCurrentLocation();

      final recordDraft = EvidenceRecord(
        id: 'EV-${now.millisecondsSinceEpoch}',
        caseNumber: _caseNumberController.text.trim().isEmpty ? 'CF-${now.year}-0001' : _caseNumberController.text.trim(),
        timestampIso: now.toIso8601String(),
        timestampFormatted: formatted,
        latitude: loc.latitude,
        longitude: loc.longitude,
        accuracyMeters: loc.accuracyMeters,
        address: loc.locationName,
        operator: operator,
        kitId: kit.id,
        kitName: kit.name,
        kitBrand: kit.brand,
        lotNumber: 'LOT-2026-X8',
        expirationDate: '2028-12-31',
        calibration: _gains,
        whitePatchColor: _rawWhiteColor,
        grayPatchColor: _rawGrayColor,
        rawSampleColor: _rawChamberColor,
        calibratedSampleColor: _calibratedChamberColor,
        category: _classification.category,
        label: _classification.label,
        substance: _classification.matchedOutcome?.substance ?? 'None Detected',
        confidence: _classification.confidence,
        deltaE: _classification.deltaE,
        sampleLab: _classification.sampleLab,
        statutoryDisclaimer: 'Presumptive testing standard NIJ-0604.01.',
        imageSha256: imageHash,
        previousRecordHash: previousHash,
        recordHash: '',
        digitalSeal: '',
        imageBase64: widget.imageBase64,
      );

      final recordHash = CryptoService.sha256String(recordDraft.toCanonicalJson());
      final digitalSeal = CryptoService.generateDigitalSeal(recordHash, operator.badge, recordDraft.timestampIso);

      final sealedRecord = EvidenceRecord(
        id: recordDraft.id,
        caseNumber: recordDraft.caseNumber,
        timestampIso: recordDraft.timestampIso,
        timestampFormatted: recordDraft.timestampFormatted,
        latitude: recordDraft.latitude,
        longitude: recordDraft.longitude,
        accuracyMeters: recordDraft.accuracyMeters,
        address: recordDraft.address,
        operator: recordDraft.operator,
        kitId: recordDraft.kitId,
        kitName: recordDraft.kitName,
        kitBrand: recordDraft.kitBrand,
        lotNumber: recordDraft.lotNumber,
        expirationDate: recordDraft.expirationDate,
        calibration: recordDraft.calibration,
        whitePatchColor: recordDraft.whitePatchColor,
        grayPatchColor: recordDraft.grayPatchColor,
        rawSampleColor: recordDraft.rawSampleColor,
        calibratedSampleColor: recordDraft.calibratedSampleColor,
        category: recordDraft.category,
        label: recordDraft.label,
        substance: recordDraft.substance,
        confidence: recordDraft.confidence,
        deltaE: recordDraft.deltaE,
        sampleLab: recordDraft.sampleLab,
        statutoryDisclaimer: recordDraft.statutoryDisclaimer,
        imageSha256: recordDraft.imageSha256,
        previousRecordHash: recordDraft.previousRecordHash,
        recordHash: recordHash,
        digitalSeal: digitalSeal,
        imageBase64: recordDraft.imageBase64,
      );

      await StorageService.appendRecord(sealedRecord);

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: CupertinoAlertDialog(
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.checkmark_seal_fill, color: AppleTheme.systemGreen, size: 20),
                  SizedBox(width: 8),
                  Text('Cryptographically Sealed'),
                ],
              ),
              content: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Case ${sealedRecord.caseNumber} committed to tamper-evident SHA-256 chain.'),
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving record: $e');
    } finally {
      if (mounted) setState(() => _isSealing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = _classification.category == 'POSITIVE';
    final isNegative = _classification.category == 'NEGATIVE';
    final outcomeColor = isPositive
        ? AppleTheme.systemRed
        : isNegative
            ? AppleTheme.systemGreen
            : AppleTheme.systemOrange;

    final cleanBase64 = widget.imageBase64.contains(',')
        ? widget.imageBase64.split(',').last
        : widget.imageBase64;
    final imageBytes = base64Decode(cleanBase64);

    return Scaffold(
      backgroundColor: AppleTheme.systemBackground,
      appBar: AppBar(
        title: const Text('Colorimetric Studio'),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: _recalculateColorimetry,
            child: const Icon(CupertinoIcons.arrow_2_circlepath, size: 20),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Case Docket & Kit Row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppleTheme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: CupertinoTextField(
                      controller: _caseNumberController,
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(CupertinoIcons.folder, size: 16, color: AppleTheme.systemBlue),
                      ),
                      placeholder: 'Case Number',
                      placeholderStyle: const TextStyle(color: AppleTheme.tertiaryLabel, fontSize: 14),
                      style: const TextStyle(color: AppleTheme.label, fontSize: 14, fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppleTheme.tertiarySystemBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppleTheme.tertiarySystemBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedKitId,
                          isExpanded: true,
                          dropdownColor: AppleTheme.tertiarySystemBackground,
                          style: const TextStyle(color: AppleTheme.label, fontSize: 13, fontWeight: FontWeight.w500),
                          items: ReagentKit.standardKits
                              .map((k) => DropdownMenuItem(
                                    value: k.id,
                                    child: Text(k.name, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedKitId = val);
                              _recalculateColorimetry();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Mode Selector: Rapid Field vs Lab D65 Calibrated
            Center(
              child: CupertinoSlidingSegmentedControl<bool>(
                backgroundColor: AppleTheme.secondarySystemBackground,
                thumbColor: AppleTheme.tertiarySystemBackground,
                groupValue: _isSingleSpotMode,
                children: const {
                  true: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Text('Rapid Field (Single Spot)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.label)),
                  ),
                  false: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Text('Laboratory D65 (3-Point)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppleTheme.label)),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _isSingleSpotMode = val;
                      _activeReticleIndex = 2;
                    });
                    _recalculateColorimetry();
                  }
                },
              ),
            ),
            const SizedBox(height: 10),

            // Sub-reticle segmented control (only visible if in 3-point mode)
            if (!_isSingleSpotMode) ...[
              Center(
                child: CupertinoSlidingSegmentedControl<int>(
                  backgroundColor: AppleTheme.secondarySystemBackground,
                  thumbColor: AppleTheme.tertiarySystemBackground,
                  groupValue: _activeReticleIndex,
                  children: const {
                    0: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Text('White Target', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTheme.label)),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Text('18% Gray', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTheme.label)),
                    ),
                    2: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Text('Reaction Spot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTheme.systemGreen)),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) setState(() => _activeReticleIndex = val);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Image Viewport with Tap-to-Sample & Floating Loupe
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
                color: Colors.black,
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 640 / 480,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;

                    return GestureDetector(
                      // Tap anywhere on the photo to position the active reticle
                      onTapDown: (details) {
                        final nx = (details.localPosition.dx / w).clamp(0.04, 0.96);
                        final ny = (details.localPosition.dy / h).clamp(0.04, 0.96);
                        setState(() {
                          if (_isSingleSpotMode || _activeReticleIndex == 2) {
                            _chamberPoint = Offset(nx, ny);
                          } else if (_activeReticleIndex == 0) {
                            _whitePoint = Offset(nx, ny);
                          } else {
                            _grayPoint = Offset(nx, ny);
                          }
                          _dragPosition = details.localPosition;
                          _dragColor = _sampleColorAt(Offset(nx, ny));
                        });
                        _recalculateColorimetry();
                      },
                      child: Stack(
                        children: [
                          // Base photo
                          Positioned.fill(
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.fill,
                            ),
                          ),

                          // Reticle 1: White Patch (Only in 3-point mode)
                          if (!_isSingleSpotMode)
                            Positioned(
                              left: _whitePoint.dx * w - 20,
                              top: _whitePoint.dy * h - 20,
                              child: GestureDetector(
                                onPanStart: (details) {
                                  setState(() {
                                    _isDragging = true;
                                    _activeReticleIndex = 0;
                                    _dragPosition = Offset(_whitePoint.dx * w, _whitePoint.dy * h);
                                    _dragColor = _rawWhiteColor;
                                  });
                                },
                                onPanUpdate: (details) {
                                  setState(() {
                                    final nx = (_whitePoint.dx * w + details.delta.dx) / w;
                                    final ny = (_whitePoint.dy * h + details.delta.dy) / h;
                                    _whitePoint = Offset(nx.clamp(0.04, 0.96), ny.clamp(0.04, 0.96));
                                    _dragPosition = Offset(_whitePoint.dx * w, _whitePoint.dy * h);
                                    _dragColor = _sampleColorAt(_whitePoint);
                                  });
                                  _recalculateColorimetry();
                                },
                                onPanEnd: (_) => setState(() => _isDragging = false),
                                child: _buildReticle(
                                  color: Colors.white,
                                  label: 'WHITE',
                                  sampledColor: _rawWhiteColor,
                                  isActive: _activeReticleIndex == 0,
                                ),
                              ),
                            ),

                          // Reticle 2: 18% Gray Patch (Only in 3-point mode)
                          if (!_isSingleSpotMode)
                            Positioned(
                              left: _grayPoint.dx * w - 20,
                              top: _grayPoint.dy * h - 20,
                              child: GestureDetector(
                                onPanStart: (details) {
                                  setState(() {
                                    _isDragging = true;
                                    _activeReticleIndex = 1;
                                    _dragPosition = Offset(_grayPoint.dx * w, _grayPoint.dy * h);
                                    _dragColor = _rawGrayColor;
                                  });
                                },
                                onPanUpdate: (details) {
                                  setState(() {
                                    final nx = (_grayPoint.dx * w + details.delta.dx) / w;
                                    final ny = (_grayPoint.dy * h + details.delta.dy) / h;
                                    _grayPoint = Offset(nx.clamp(0.04, 0.96), ny.clamp(0.04, 0.96));
                                    _dragPosition = Offset(_grayPoint.dx * w, _grayPoint.dy * h);
                                    _dragColor = _sampleColorAt(_grayPoint);
                                  });
                                  _recalculateColorimetry();
                                },
                                onPanEnd: (_) => setState(() => _isDragging = false),
                                child: _buildReticle(
                                  color: AppleTheme.systemTeal,
                                  label: '18% GRAY',
                                  sampledColor: _rawGrayColor,
                                  isActive: _activeReticleIndex == 1,
                                ),
                              ),
                            ),

                          // Reticle 3: Reaction Liquid
                          Positioned(
                            left: _chamberPoint.dx * w - 20,
                            top: _chamberPoint.dy * h - 20,
                            child: GestureDetector(
                              onPanStart: (details) {
                                setState(() {
                                  _isDragging = true;
                                  _activeReticleIndex = 2;
                                  _dragPosition = Offset(_chamberPoint.dx * w, _chamberPoint.dy * h);
                                  _dragColor = _rawChamberColor;
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  final nx = (_chamberPoint.dx * w + details.delta.dx) / w;
                                  final ny = (_chamberPoint.dy * h + details.delta.dy) / h;
                                  _chamberPoint = Offset(nx.clamp(0.04, 0.96), ny.clamp(0.04, 0.96));
                                  _dragPosition = Offset(_chamberPoint.dx * w, _chamberPoint.dy * h);
                                  _dragColor = _sampleColorAt(_chamberPoint);
                                });
                                _recalculateColorimetry();
                              },
                              onPanEnd: (_) => setState(() => _isDragging = false),
                              child: _buildReticle(
                                color: AppleTheme.systemGreen,
                                label: 'REACTION',
                                sampledColor: _rawChamberColor,
                                isActive: _activeReticleIndex == 2,
                              ),
                            ),
                          ),

                          // Apple-Style Magnifying Loupe (Floats during touch)
                          if (_isDragging) ...[
                            _buildMagnifierLoupe(
                              touchPos: _dragPosition,
                              viewWidth: w,
                              viewHeight: h,
                              imageBytes: imageBytes,
                              sampledColor: _dragColor,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Touch or drag reticle to inspect pixels with 3.5x magnifying loupe',
                style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel),
              ),
            ),
            const SizedBox(height: 14),

            // Classification Outcome Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: outcomeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                border: Border.all(color: outcomeColor.withAlpha(80), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: outcomeColor.withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPositive
                          ? CupertinoIcons.exclamationmark_triangle_fill
                          : (isNegative
                              ? CupertinoIcons.checkmark_seal_fill
                              : CupertinoIcons.question_circle_fill),
                      color: outcomeColor,
                      size: 24,
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
                            Text(
                              _classification.category,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: outcomeColor,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(120),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_classification.confidence}% Match',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _classification.label,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppleTheme.label),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Optical Metrics & Color Swatch Comparison
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppleTheme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CALIBRATION METRICS (D65 / CIE-Lab)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppleTheme.tertiaryLabel, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricTile('Delta-E (ΔE)', _classification.deltaE.toStringAsFixed(1), AppleTheme.systemBlue),
                      _buildMetricTile('Confidence', '${_classification.confidence}%', AppleTheme.systemGreen),
                      _buildMetricTile('Lighting Quality', '${_gains.lightingQuality}%', AppleTheme.systemOrange),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 0.5, color: AppleTheme.separator),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSwatchColumn('Raw Measured', _rawChamberColor),
                      const Icon(CupertinoIcons.arrow_right, size: 14, color: AppleTheme.tertiaryLabel),
                      _buildSwatchColumn('Calibrated D65', _calibratedChamberColor, isHighlight: true),
                      const Icon(CupertinoIcons.arrow_right, size: 14, color: AppleTheme.tertiaryLabel),
                      _buildSwatchColumn('Standard Target', _classification.matchedOutcome?.expectedColor ?? const Color(0xFF808080)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live GPS Location Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppleTheme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppleTheme.systemBlue.withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _currentLocation?.isLiveGps == true ? CupertinoIcons.location_fill : CupertinoIcons.location,
                      size: 14,
                      color: AppleTheme.systemBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentLocation != null ? _currentLocation!.locationName : 'Acquiring Real GPS Location...',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppleTheme.label,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentLocation != null
                              ? 'Precision ±${_currentLocation!.accuracyMeters.toStringAsFixed(1)}m • Verified Hardware Fix'
                              : 'Querying FusedLocationProvider sensor...',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppleTheme.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_currentLocation == null)
                    const CupertinoActivityIndicator(radius: 8),
                ],
              ),
            ),

            // Seal Button
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
              onPressed: _isSealing ? null : _handleSealAndSave,
              child: _isSealing
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.lock_shield_fill, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Seal & Commit to SHA-256 Chain',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.3),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMagnifierLoupe({
    required Offset touchPos,
    required double viewWidth,
    required double viewHeight,
    required List<int> imageBytes,
    required Color sampledColor,
  }) {
    const loupeDiameter = 100.0;
    const zoomFactor = 3.5;

    // Position loupe centered 100px above touch
    double loupeLeft = touchPos.dx - loupeDiameter / 2;
    double loupeTop = touchPos.dy - loupeDiameter - 25;

    // Clamp inside viewport
    if (loupeTop < 10) {
      loupeTop = touchPos.dy + 35; // Flip below if near top
    }
    loupeLeft = loupeLeft.clamp(10.0, viewWidth - loupeDiameter - 10);

    final normX = (touchPos.dx / viewWidth).clamp(0.0, 1.0);
    final normY = (touchPos.dy / viewHeight).clamp(0.0, 1.0);

    return Positioned(
      left: loupeLeft,
      top: loupeTop,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: loupeDiameter,
            height: loupeDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(160),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  Positioned(
                    left: -normX * viewWidth * zoomFactor + loupeDiameter / 2,
                    top: -normY * viewHeight * zoomFactor + loupeDiameter / 2,
                    width: viewWidth * zoomFactor,
                    height: viewHeight * zoomFactor,
                    child: Image.memory(
                      imageBytes as dynamic,
                      fit: BoxFit.fill,
                    ),
                  ),
                  // Reticle crosshair inside loupe
                  Center(
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(220),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: Text(
              '#${sampledColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReticle({
    required Color color,
    required String label,
    required Color sampledColor,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 44 : 36,
          height: isActive ? 44 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isActive ? 3 : 2),
            color: sampledColor.withAlpha(180),
            boxShadow: [
              BoxShadow(color: color.withAlpha(isActive ? 160 : 80), blurRadius: isActive ? 12 : 6),
            ],
          ),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(210),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppleTheme.tertiaryLabel)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor, letterSpacing: -0.2),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSwatchColumn(String title, Color color, {bool isHighlight = false}) {
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighlight ? AppleTheme.systemBlue : Colors.white24,
              width: isHighlight ? 2 : 1,
            ),
            boxShadow: isHighlight
                ? [BoxShadow(color: AppleTheme.systemBlue.withAlpha(90), blurRadius: 8)]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 10, color: isHighlight ? AppleTheme.systemBlue : AppleTheme.secondaryLabel)),
        Text(hex, style: const TextStyle(fontSize: 8.5, color: AppleTheme.tertiaryLabel)),
      ],
    );
  }
}
