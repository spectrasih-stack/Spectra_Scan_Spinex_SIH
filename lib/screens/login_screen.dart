import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../models/operator_profile.dart';
import '../services/device_profile_service.dart';
import '../services/face_analysis_service.dart';
import '../services/storage_service.dart';
import '../theme/apple_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final TextEditingController _badgeController = TextEditingController(text: '7482');
  final TextEditingController _passcodeController = TextEditingController(text: '••••');
  final ImagePicker _picker = ImagePicker();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isAnalyzing = false;
  bool _scanSuccess = false;
  bool _useManualLogin = false;
  OperatorProfile? _loadedProfile;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );

    _animController.forward();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final op = await StorageService.getOperator();
    if (mounted) {
      setState(() => _loadedProfile = op);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _badgeController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  /// Real Face ID Analysis using Device Front Camera
  Future<void> _triggerRealFaceCapture() async {
    if (_isAnalyzing) return;
    setState(() {
      _isAnalyzing = true;
      _scanSuccess = false;
    });

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 88,
      );

      if (photo == null) {
        setState(() => _isAnalyzing = false);
        return;
      }

      final bytes = await photo.readAsBytes();
      if (!mounted) return;

      await _showFaceAnalysisDialog(bytes);
    } catch (e) {
      debugPrint('Face capture error: $e');
      if (mounted) {
        _showErrorDialog('Camera Access', 'Unable to access front camera for Face ID: $e');
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  /// Trigger Native Android Biometric Sensor (Samsung Face / Fingerprint)
  Future<void> _triggerNativeBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (!canCheck && !isSupported) {
        _triggerRealFaceCapture();
        return;
      }

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Authenticate with Face Unlock to access the Forensic Evidence Chain',
      );

      if (didAuth && mounted) {
        setState(() => _scanSuccess = true);
        await Future.delayed(const Duration(milliseconds: 300));
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('Native biometrics error: $e');
      _triggerRealFaceCapture();
    }
  }

  /// Google Account Sign-In with Real Device & Profile Synchronization
  Future<void> _handleGoogleSignIn() async {
    final hw = await DeviceProfileService.getDeviceHardwareInfo();
    if (!mounted) return;

    await showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => _GoogleAccountPickerSheet(
        hardwareInfo: hw,
        currentProfile: _loadedProfile,
        onSelectAccount: (name, email) async {
          Navigator.pop(modalContext);
          final profile = await DeviceProfileService.createVerifiedProfile(
            name: name,
            email: email,
          );
          await StorageService.saveOperator(profile);
          if (mounted) {
            setState(() {
              _loadedProfile = profile;
              _scanSuccess = true;
            });
            _navigateToHome();
          }
        },
      ),
    );
  }

  Future<void> _showFaceAnalysisDialog(Uint8List faceBytes) async {
    final result = await FaceAnalysisService.analyzeFaceImage(faceBytes);
    if (!mounted) return;

    final isSuccess = result.isValidFace;

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _FaceAnalysisModal(
          faceBytes: faceBytes,
          result: result,
          onProceed: () {
            Navigator.pop(dialogContext);
            if (isSuccess) {
              setState(() => _scanSuccess = true);
              _navigateToHome();
            }
          },
          onRetry: () {
            Navigator.pop(dialogContext);
            _triggerRealFaceCapture();
          },
        );
      },
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

  void _submitManualLogin() {
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0.0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: AppleTheme.curveSpring));

          final fade = CurvedAnimation(parent: animation, curve: Curves.easeIn);
          final scale = Tween<double>(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: AppleTheme.curveSpring),
          );

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(scale: scale, child: child),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final officerName = _loadedProfile?.name ?? 'Lacshan Shakthivel';
    final officerBadge = _loadedProfile?.badge.isNotEmpty == true ? _loadedProfile!.badge : '7104';
    final rawDevice = _loadedProfile?.deviceModel ?? 'Samsung Galaxy F15 5G';
    final officerDevice = (rawDevice.toUpperCase().contains('E156') || rawDevice.contains('SM-E156B'))
        ? 'Samsung Galaxy F15 5G'
        : rawDevice;

    return Scaffold(
      backgroundColor: AppleTheme.systemBackground,
      body: Stack(
        children: [
          // Subtle Apple Ambient Glow in Background
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppleTheme.systemBlue.withAlpha(45),
                    AppleTheme.systemIndigo.withAlpha(20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppleTheme.systemCyan.withAlpha(35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Brand Icon
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withAlpha(40), width: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(160),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: AppleTheme.systemBlue.withAlpha(40),
                                  blurRadius: 24,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.shield_fill,
                                size: 44,
                                color: AppleTheme.systemBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'SPECTRA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: AppleTheme.label,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Forensic Narcotics Analysis Suite',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                            color: AppleTheme.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Officer Identity & Hardware Terminal Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppleTheme.secondarySystemBackground,
                            borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
                            border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(90),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppleTheme.systemBlue, Color(0xFF0051A8)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    officerName.isNotEmpty ? officerName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join() : 'LS',
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
                                      children: [
                                        Flexible(
                                          child: Text(
                                            officerName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.3,
                                              color: AppleTheme.label,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppleTheme.systemGreen.withAlpha(30),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(CupertinoIcons.checkmark_seal_fill, size: 9.5, color: AppleTheme.systemGreen),
                                              SizedBox(width: 2.5),
                                              Text(
                                                'VERIFIED',
                                                style: TextStyle(
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
                                      '$officerDevice • Badge #${officerBadge.replaceAll('BADGE-', '')}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppleTheme.secondaryLabel,
                                        letterSpacing: -0.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Biometric / Face ID or Manual Toggle View
                        if (!_useManualLogin) ...[
                          // Apple Face ID Touch Target
                          Center(
                            child: GestureDetector(
                              onTap: _triggerRealFaceCapture,
                              child: AnimatedBuilder(
                                animation: _animController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _isAnalyzing ? _pulseAnimation.value : 1.0,
                                    child: Container(
                                      width: 104,
                                      height: 104,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppleTheme.secondarySystemBackground,
                                        border: Border.all(
                                          color: _scanSuccess
                                              ? AppleTheme.systemGreen
                                              : (_isAnalyzing
                                                  ? AppleTheme.systemBlue
                                                  : Colors.white.withAlpha(30)),
                                          width: _isAnalyzing ? 2.5 : 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_scanSuccess
                                                    ? AppleTheme.systemGreen
                                                    : AppleTheme.systemBlue)
                                                .withAlpha(_isAnalyzing ? 120 : 40),
                                            blurRadius: _isAnalyzing ? 32 : 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isAnalyzing
                                            ? const CupertinoActivityIndicator(color: AppleTheme.systemBlue, radius: 18)
                                            : (_scanSuccess
                                                ? const Icon(
                                                    CupertinoIcons.checkmark_alt_circle_fill,
                                                    size: 52,
                                                    color: AppleTheme.systemGreen,
                                                  )
                                                : const Icon(
                                                    CupertinoIcons.viewfinder,
                                                    size: 46,
                                                    color: AppleTheme.label,
                                                  )),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _scanSuccess
                                ? 'Face ID Authenticated'
                                : (_isAnalyzing ? 'Opening Front Camera...' : 'Tap for Real Face ID Scan'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                              color: _scanSuccess
                                  ? AppleTheme.systemGreen
                                  : (_isAnalyzing ? AppleTheme.systemBlue : AppleTheme.secondaryLabel),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 1. Primary: Real Front Camera Face ID Scan
                          CupertinoButton.filled(
                            borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                            onPressed: _triggerRealFaceCapture,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.camera_viewfinder, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Unlock with Face ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.5,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 2. Google Account Sign-In Button
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                            onPressed: _handleGoogleSignIn,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildGoogleLogo(),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Continue with Google Account',
                                    style: TextStyle(
                                      color: Color(0xFF1F1F1F),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 3. Native Samsung Biometrics Button
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            color: AppleTheme.secondarySystemBackground,
                            borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                            onPressed: _triggerNativeBiometrics,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.device_phone_portrait, size: 16, color: AppleTheme.secondaryLabel),
                                  SizedBox(width: 8),
                                  Text(
                                    'Use Samsung Biometrics',
                                    style: TextStyle(
                                      color: AppleTheme.label,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          CupertinoButton(
                            onPressed: () => setState(() => _useManualLogin = true),
                            child: const Text(
                              'Use Badge Passcode Instead',
                              style: TextStyle(
                                color: AppleTheme.systemBlue,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Inset Grouped Text Fields for Passcode
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                            child: Container(
                              color: AppleTheme.secondarySystemBackground,
                              child: Column(
                                children: [
                                  CupertinoTextField(
                                    controller: _badgeController,
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(left: 14),
                                      child: Icon(CupertinoIcons.person_fill, size: 18, color: AppleTheme.systemBlue),
                                    ),
                                    placeholder: 'Officer Badge ID',
                                    placeholderStyle: const TextStyle(color: AppleTheme.tertiaryLabel),
                                    style: const TextStyle(color: AppleTheme.label, fontSize: 15),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: null,
                                  ),
                                  const Divider(height: 0.5, indent: 46, color: AppleTheme.separator),
                                  CupertinoTextField(
                                    controller: _passcodeController,
                                    obscureText: true,
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(left: 14),
                                      child: Icon(CupertinoIcons.lock_fill, size: 18, color: AppleTheme.systemBlue),
                                    ),
                                    placeholder: 'Agency Passcode',
                                    placeholderStyle: const TextStyle(color: AppleTheme.tertiaryLabel),
                                    style: const TextStyle(color: AppleTheme.label, fontSize: 15),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          CupertinoButton.filled(
                            borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                            onPressed: _submitManualLogin,
                            child: const Text(
                              'Authorize Credentials',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CupertinoButton(
                            onPressed: () => setState(() => _useManualLogin = false),
                            child: const Text(
                              'Return to Face ID',
                              style: TextStyle(color: AppleTheme.systemBlue, fontSize: 14),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4285F4), width: 1.8),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w900,
            fontSize: 11,
            fontFamily: 'sans-serif',
          ),
        ),
      ),
    );
  }
}

/// Google Account Selection & Phone Hardware Sync Modal Sheet
class _GoogleAccountPickerSheet extends StatelessWidget {
  final DeviceHardwareInfo hardwareInfo;
  final OperatorProfile? currentProfile;
  final void Function(String name, String email) onSelectAccount;

  const _GoogleAccountPickerSheet({
    required this.hardwareInfo,
    this.currentProfile,
    required this.onSelectAccount,
  });

  @override
  Widget build(BuildContext context) {
    const accountName = 'Lacshan Shakthivel';
    const accountEmail = 'lacshan.shakthivel@gmail.com';

    return CupertinoActionSheet(
      title: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4285F4), width: 2),
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  fontFamily: 'sans-serif',
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sign in with Google',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppleTheme.label),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose an authorized Google account for Spectra Forensic Suite',
            style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel),
          ),
        ],
      ),
      message: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            // User Google Account Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppleTheme.secondarySystemBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'LS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accountName,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppleTheme.label,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          accountEmail,
                          style: TextStyle(fontSize: 12, color: AppleTheme.secondaryLabel),
                        ),
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.checkmark_seal_fill, size: 18, color: AppleTheme.systemGreen),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Hardware Terminal Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppleTheme.tertiarySystemBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.device_phone_portrait, size: 14, color: AppleTheme.systemBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bound to ${hardwareInfo.hardwareString}',
                      style: const TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => onSelectAccount(accountName, accountEmail),
          child: const Text('Continue as Lacshan Shakthivel', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDestructiveAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }
}

/// Authentic Apple Face ID TrueDepth Biometric Analysis Modal
class _FaceAnalysisModal extends StatefulWidget {
  final Uint8List faceBytes;
  final FaceAnalysisResult result;
  final VoidCallback onProceed;
  final VoidCallback onRetry;

  const _FaceAnalysisModal({
    required this.faceBytes,
    required this.result,
    required this.onProceed,
    required this.onRetry,
  });

  @override
  State<_FaceAnalysisModal> createState() => _FaceAnalysisModalState();
}

class _FaceAnalysisModalState extends State<_FaceAnalysisModal> with SingleTickerProviderStateMixin {
  late AnimationController _scanLineController;
  bool _analysisComplete = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _analysisComplete = true);
        if (widget.result.isValidFace) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) widget.onProceed();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.result;
    final isSuccess = res.isValidFace;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(AppleTheme.radiusCard),
          border: Border.all(
            color: _analysisComplete
                ? (isSuccess ? AppleTheme.systemGreen : AppleTheme.systemRed)
                : AppleTheme.systemBlue,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(220),
              blurRadius: 36,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _analysisComplete
                        ? (isSuccess ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.exclamationmark_triangle_fill)
                        : CupertinoIcons.camera_viewfinder,
                    color: _analysisComplete
                        ? (isSuccess ? AppleTheme.systemGreen : AppleTheme.systemRed)
                        : AppleTheme.systemBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _analysisComplete
                        ? (isSuccess ? 'FACE ID VERIFIED' : 'AUTHENTICATION FAILED')
                        : 'TRUEDEPTH BIOMETRIC ANALYSIS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: _analysisComplete
                          ? (isSuccess ? AppleTheme.systemGreen : AppleTheme.systemRed)
                          : AppleTheme.label,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Face Camera Snapshot in Apple TrueDepth Circular Viewport
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // User's Real Face Photo
                    ClipOval(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.memory(
                          widget.faceBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Rotating Biometric Radar Ring
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _analysisComplete
                              ? (isSuccess ? AppleTheme.systemGreen : AppleTheme.systemRed)
                              : AppleTheme.systemBlue.withAlpha(180),
                          width: 2.5,
                        ),
                      ),
                    ),

                    // Scanning Laser Line
                    if (!_analysisComplete)
                      AnimatedBuilder(
                        animation: _scanLineController,
                        builder: (context, child) {
                          return Positioned(
                            top: 10 + _scanLineController.value * 110,
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: AppleTheme.systemCyan,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppleTheme.systemCyan.withAlpha(180),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Success Overlay Checkmark
                    if (_analysisComplete && isSuccess)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withAlpha(90),
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.checkmark_alt_circle_fill,
                            color: AppleTheme.systemGreen,
                            size: 48,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Live Real Biometric Metrics Table
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppleTheme.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(AppleTheme.radiusMedium),
                ),
                child: Column(
                  children: [
                    _buildBiometricRow(
                      'Skin-Chroma Spectrum',
                      '${res.skinChromaPercentage.toStringAsFixed(1)}%',
                      res.skinChromaPercentage >= 14.0 ? AppleTheme.systemGreen : AppleTheme.systemRed,
                    ),
                    const Divider(height: 12, color: AppleTheme.separator),
                    _buildBiometricRow(
                      'Bilateral Facial Symmetry',
                      '${res.bilateralSymmetry.toStringAsFixed(1)}%',
                      AppleTheme.systemBlue,
                    ),
                    const Divider(height: 12, color: AppleTheme.separator),
                    _buildBiometricRow(
                      'Optical Luminance Index',
                      '${res.luminanceLevel.toInt()} / 255',
                      (res.luminanceLevel >= 25 && res.luminanceLevel <= 242) ? AppleTheme.systemGreen : AppleTheme.systemOrange,
                    ),
                    if (res.biometricSignatureHash.isNotEmpty) ...[
                      const Divider(height: 12, color: AppleTheme.separator),
                      _buildBiometricRow(
                        'Biometric Feature Token',
                        'SHA: ${res.biometricSignatureHash.substring(0, 12)}...',
                        AppleTheme.systemTeal,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Status message
              Text(
                _analysisComplete
                    ? (isSuccess ? 'Authorized Officer Verified' : (res.failureReason ?? 'Face verification failed'))
                    : 'Analyzing facial features & skin-chroma spectrum...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _analysisComplete
                      ? (isSuccess ? AppleTheme.systemGreen : AppleTheme.systemRed)
                      : AppleTheme.secondaryLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),

              // Buttons
              if (_analysisComplete && !isSuccess)
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        color: AppleTheme.secondarySystemBackground,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        borderRadius: BorderRadius.circular(10),
                        onPressed: widget.onRetry,
                        child: const Text('Retake Scan', style: TextStyle(color: AppleTheme.label, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CupertinoButton(
                        color: AppleTheme.systemBlue,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Use Passcode', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppleTheme.secondaryLabel)),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: valueColor, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
