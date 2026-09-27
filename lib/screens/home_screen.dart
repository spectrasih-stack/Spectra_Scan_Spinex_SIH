import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/evidence_record.dart';
import '../models/operator_profile.dart';
import '../services/storage_service.dart';
import '../theme/apple_theme.dart';
import '../widgets/dynamic_island.dart';
import '../widgets/oval_bottom_nav_bar.dart';
import 'capture_screen.dart';
import 'dashboard_screen.dart';
import 'ledger_screen.dart';
import 'login_screen.dart';
import 'reference_card_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  final DynamicIslandController _islandController = DynamicIslandController();

  List<EvidenceRecord> _records = [];
  OperatorProfile _operator = OperatorProfile.defaultOperator;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadData();

    // Ambient welcome notification in Dynamic Island
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _islandController.show(
        message: 'Spectra Active',
        subMessage: 'Cryptographic Ledger Verified',
        icon: CupertinoIcons.checkmark_seal_fill,
        accentColor: AppleTheme.systemGreen,
        duration: const Duration(seconds: 4),
      );
    });
  }

  @override
  void dispose() {
    _islandController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final op = await StorageService.getOperator();
    final recs = await StorageService.loadRecords();
    setState(() {
      _operator = op;
      _records = recs;
      _isLoading = false;
    });
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _showOfficerProfileSheet() {
    final nameCtrl = TextEditingController(text: _operator.name);
    final badgeCtrl = TextEditingController(text: _operator.badge);
    final agencyCtrl = TextEditingController(text: _operator.agency);
    final unitCtrl = TextEditingController(text: _operator.unit);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: Container(
          decoration: const BoxDecoration(
            color: AppleTheme.secondarySystemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 14,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Officer Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppleTheme.label,
                          letterSpacing: -0.4,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () async {
                          final updated = OperatorProfile(
                            name: nameCtrl.text.trim(),
                            badge: badgeCtrl.text.trim(),
                            agency: agencyCtrl.text.trim(),
                            unit: unitCtrl.text.trim(),
                          );
                          await StorageService.saveOperator(updated);
                          setState(() => _operator = updated);
                          if (context.mounted) Navigator.pop(context);

                          _islandController.show(
                            message: 'Profile Updated',
                            subMessage: 'Officer ${updated.name}',
                            icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                            accentColor: AppleTheme.systemBlue,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Form Fields
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: AppleTheme.tertiarySystemBackground,
                      child: Column(
                        children: [
                          CupertinoTextFormFieldRow(
                            controller: nameCtrl,
                            prefix: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(CupertinoIcons.person, size: 18, color: AppleTheme.systemBlue),
                            ),
                            placeholder: 'Officer Full Name',
                            placeholderStyle: const TextStyle(color: AppleTheme.tertiaryLabel),
                            style: const TextStyle(color: AppleTheme.label, fontSize: 15),
                          ),
                          const Divider(height: 0.5, indent: 40, color: AppleTheme.separator),
                          CupertinoTextFormFieldRow(
                            controller: badgeCtrl,
                            prefix: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(CupertinoIcons.number, size: 18, color: AppleTheme.systemBlue),
                            ),
                            placeholder: 'Badge / ID Number',
                            placeholderStyle: const TextStyle(color: AppleTheme.tertiaryLabel),
                            style: const TextStyle(color: AppleTheme.label, fontSize: 15),
                          ),
                          const Divider(height: 0.5, indent: 40, color: AppleTheme.separator),
                          CupertinoTextFormFieldRow(
                            controller: agencyCtrl,
                            prefix: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(CupertinoIcons.building_2_fill, size: 18, color: AppleTheme.systemBlue),
                            ),
                            placeholder: 'Agency / Department',
                            placeholderStyle: const TextStyle(color: AppleTheme.tertiaryLabel),
                            style: const TextStyle(color: AppleTheme.label, fontSize: 15),
                          ),
                          const Divider(height: 0.5, indent: 40, color: AppleTheme.separator),
                          CupertinoTextFormFieldRow(
                            controller: unitCtrl,
                            prefix: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(CupertinoIcons.shield, size: 18, color: AppleTheme.systemBlue),
                            ),
                            placeholder: 'Unit / Division',
                            placeholderStyle: const TextStyle(color: AppleTheme.tertiaryLabel),
                            style: const TextStyle(color: AppleTheme.label, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Lock / Logout Option
                  CupertinoButton(
                    color: AppleTheme.systemRed.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: () {
                      Navigator.pop(context);
                      _handleLockApp();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.lock_fill, size: 16, color: AppleTheme.systemRed),
                        SizedBox(width: 8),
                        Text(
                          'Lock Session',
                          style: TextStyle(
                            color: AppleTheme.systemRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
      ),
    );
  }

  void _showNoticeSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: CupertinoAlertDialog(
          title: const Text('Statutory Notice'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Colorimetric field tests represent presumptive scientific indicators under standard NIJ-0604.01.\n\nConfirmatory laboratory testing (GC-MS / FTIR) is required for judicial adjudication.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Understood'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLockApp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppleTheme.systemBackground,
        body: Center(
          child: CupertinoActivityIndicator(radius: 14, color: AppleTheme.systemBlue),
        ),
      );
    }

    final titles = ['Overview', 'Scanner', 'Records'];

    return Scaffold(
      backgroundColor: AppleTheme.systemBackground,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppleTheme.glassNavBar,
                border: Border(
                  bottom: BorderSide(color: AppleTheme.hairlineBorder, width: 0.5),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // Brand Icon & Title
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppleTheme.systemBlue.withAlpha(35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(CupertinoIcons.shield_fill, size: 18, color: AppleTheme.systemBlue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            titles[_currentIndex],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: AppleTheme.label,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Spectra Forensic Suite',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppleTheme.secondaryLabel,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Statutory Notice Info Button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showNoticeSheet,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppleTheme.tertiarySystemBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppleTheme.hairlineBorder, width: 0.5),
                        ),
                        child: const Icon(CupertinoIcons.info, size: 14, color: AppleTheme.systemOrange),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Officer Profile Avatar Button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showOfficerProfileSheet,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppleTheme.systemBlue, Color(0xFF0051A8)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(50), width: 0.8),
                        ),
                        child: Center(
                          child: Text(
                            _operator.name.isNotEmpty
                                ? _operator.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                                : 'OP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: [
              DashboardScreen(
                records: _records,
                operator: _operator,
                onLaunchCamera: () => _onTabTapped(1),
                onOpenLedger: () => _onTabTapped(2),
                onRefreshRecords: _loadData,
              ),
              CaptureScreen(
                onOpenRefCard: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => const ReferenceCardScreen()),
                  );
                },
              ),
              LedgerScreen(
                records: _records,
                onRefreshRecords: _loadData,
              ),
            ],
          ),

          // Floating Apple Dynamic Island Overlay at top center
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Center(
              child: DynamicIsland(controller: _islandController),
            ),
          ),
        ],
      ),
      bottomNavigationBar: OvalBottomNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: _onTabTapped,
      ),
    );
  }
}
