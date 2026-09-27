import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/reagent_kit.dart';
import '../services/sample_generator.dart';
import '../theme/apple_theme.dart';
import 'calibration_screen.dart';

class CaptureScreen extends StatefulWidget {
  final VoidCallback onOpenRefCard;

  const CaptureScreen({super.key, required this.onOpenRefCard});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  String _selectedKitId = 'marquis';
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  Future<void> _takePhotoWithCamera() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1440,
        imageQuality: 95,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final base64String = base64Encode(bytes);
        _launchWithImage(base64String);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        _showErrorDialog('Camera Access', 'Unable to capture photo: $e');
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1440,
        imageQuality: 95,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        _launchWithImage(base64String);
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
      if (mounted) {
        _showErrorDialog('Photos Access', 'Unable to load photo: $e');
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _launchWithImage(String base64Image) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CalibrationScreen(
          imageBase64: base64Image,
          initialKitId: _selectedKitId,
          initialCaseNumber: 'CF-${DateTime.now().year}-${10000 + (DateTime.now().millisecond % 89999)}',
          initialWhitePoint: const Offset(120, 160),
          initialGrayPoint: const Offset(120, 320),
          initialChamberPoint: const Offset(320, 240),
        ),
      ),
    );
  }

  void _launchStandardReference(ReagentKit kit, ReagentOutcome outcome) {
    final scene = SampleGenerator.generateScene(
      kitId: kit.id,
      reactionColor: outcome.expectedColor,
      lighting: 'daylight',
    );

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CalibrationScreen(
          imageBase64: scene.base64Png,
          initialKitId: kit.id,
          initialCaseNumber: 'REF-${kit.id.toUpperCase()}-${DateTime.now().millisecond % 9999}',
          initialWhitePoint: scene.whitePatchPoint,
          initialGrayPoint: scene.grayPatchPoint,
          initialChamberPoint: scene.reactionChamberPoint,
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedKit = ReagentKit.standardKits.firstWhere((k) => k.id == _selectedKitId);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Real-Time Camera Shutter Hero Card (Apple HIG)
          GestureDetector(
            onTap: _takePhotoWithCamera,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(160),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                child: Stack(
                  children: [
                    // Viewfinder grid & radial background
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.1,
                            colors: [Color(0xFF1E1E24), Color(0xFF0A0A0C)],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: AppleTheme.systemBlue.withAlpha(30),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppleTheme.systemBlue.withAlpha(90), width: 1.5),
                                ),
                                child: _isCapturing
                                    ? const CupertinoActivityIndicator(color: Colors.white, radius: 14)
                                    : const Icon(
                                        CupertinoIcons.camera_viewfinder,
                                        size: 36,
                                        color: AppleTheme.systemBlue,
                                      ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tap to Launch Real Camera',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: AppleTheme.label,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Capture chemical test pouch, reaction strip, or powder',
                                style: TextStyle(fontSize: 11.5, color: AppleTheme.secondaryLabel),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top Status Bar Inside Viewfinder
                    Positioned(
                      top: 12,
                      left: 14,
                      right: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(180),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(30), width: 0.5),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.checkmark_seal_fill, size: 12, color: AppleTheme.systemGreen),
                                SizedBox(width: 5),
                                Text(
                                  'OPTICAL SENSOR ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppleTheme.systemGreen,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(180),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(30), width: 0.5),
                            ),
                            child: const Text(
                              'CIE-Lab / D65 Daylight',
                              style: TextStyle(fontSize: 10, color: AppleTheme.secondaryLabel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Primary Controls Bar: Photos, Camera Shutter, Calibration Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppleTheme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
              border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Real Photo Library / Gallery Button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _pickPhotoFromGallery,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: AppleTheme.tertiarySystemBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.photo_on_rectangle,
                          size: 20,
                          color: AppleTheme.systemBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Photo Roll',
                        style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // Real Device Camera Shutter Trigger
                GestureDetector(
                  onTap: _takePhotoWithCamera,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.5),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _isCapturing
                            ? const CupertinoActivityIndicator(color: Colors.black)
                            : const Icon(CupertinoIcons.camera_fill, size: 28, color: Colors.black),
                      ),
                    ),
                  ),
                ),

                // Reference Calibration Card Display
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: widget.onOpenRefCard,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: AppleTheme.tertiarySystemBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.color_filter,
                          size: 20,
                          color: AppleTheme.systemOrange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Target Card',
                        style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Field Reagent Selection Carousel
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ACTIVE CHEMICAL REAGENT KIT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppleTheme.tertiaryLabel,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'NIJ 0604.01 Standard',
                    style: TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: ReagentKit.standardKits.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final kit = ReagentKit.standardKits[index];
                    final isSelected = kit.id == _selectedKitId;

                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => _selectedKitId = kit.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppleTheme.systemBlue : AppleTheme.secondarySystemBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppleTheme.systemBlue : AppleTheme.hairlineBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(CupertinoIcons.checkmark, size: 12, color: Colors.white),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              kit.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                letterSpacing: -0.2,
                                color: isSelected ? Colors.white : AppleTheme.label,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Kit Chemistry Information Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppleTheme.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                  border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedKit.brand,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppleTheme.label),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppleTheme.systemOrange.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Reaction: ${selectedKit.reactionDurationSeconds}s',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppleTheme.systemOrange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedKit.description,
                      style: const TextStyle(fontSize: 11.5, color: AppleTheme.secondaryLabel),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reagents: ${selectedKit.activeChemicals}',
                      style: const TextStyle(fontSize: 10.5, color: AppleTheme.tertiaryLabel, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // NIJ 0604.01 Presumptive Reaction Library for Selected Kit
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'EXPECTED CHROMATIC REACTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppleTheme.tertiaryLabel,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedKit.outcomes.length} Thresholds',
                    style: const TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                child: Container(
                  color: AppleTheme.secondarySystemBackground,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: selectedKit.outcomes.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 0.5,
                      indent: 48,
                      color: AppleTheme.separator,
                    ),
                    itemBuilder: (context, index) {
                      final outcome = selectedKit.outcomes[index];
                      final isPos = outcome.category == 'POSITIVE';
                      final isNeg = outcome.category == 'NEGATIVE';
                      final badgeColor = isPos
                          ? AppleTheme.systemRed
                          : isNeg
                              ? AppleTheme.systemGreen
                              : AppleTheme.systemOrange;

                      return CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        onPressed: () => _launchStandardReference(selectedKit, outcome),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: outcome.expectedColor,
                                border: Border.all(color: Colors.white.withAlpha(90), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: outcome.expectedColor.withAlpha(80),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    outcome.substance,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                      color: AppleTheme.label,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${outcome.description} • ΔE ≤ ${outcome.toleranceDeltaE.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppleTheme.secondaryLabel,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                outcome.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                  letterSpacing: 0.2,
                                ),
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
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Field Testing Protocol Guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppleTheme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
              border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.info_circle_fill, size: 16, color: AppleTheme.systemBlue),
                    SizedBox(width: 8),
                    Text(
                      'FIELD COLORIMETRY PROTOCOL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppleTheme.systemBlue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  '1. Reagent Reaction: Introduce chemical sample into test pouch, crush glass ampoules in sequence, and agitate for 15 seconds.',
                  style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel, height: 1.35),
                ),
                SizedBox(height: 6),
                Text(
                  '2. Lighting: Place sample in uniform daylight or neutral white LED. Avoid direct camera flash glare on plastic pouches.',
                  style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel, height: 1.35),
                ),
                SizedBox(height: 6),
                Text(
                  '3. Touch Sampling: In the Colorimetric Studio, touch anywhere on the reaction liquid to sample live pixels with the 3.5x magnifying loupe.',
                  style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
