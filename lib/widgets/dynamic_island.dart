import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/apple_theme.dart';

class DynamicIslandController extends ChangeNotifier {
  String? _message;
  String? _subMessage;
  IconData _icon = CupertinoIcons.shield_lefthalf_fill;
  Color _accentColor = AppleTheme.systemBlue;
  bool _isExpanded = false;
  Timer? _dismissTimer;
  Timer? _clearTimer;

  String? get message => _message;
  String? get subMessage => _subMessage;
  IconData get icon => _icon;
  Color get accentColor => _accentColor;
  bool get isExpanded => _isExpanded;

  void show({
    required String message,
    String? subMessage,
    IconData icon = CupertinoIcons.checkmark_seal_fill,
    Color accentColor = AppleTheme.systemGreen,
    Duration duration = const Duration(seconds: 3),
  }) {
    _dismissTimer?.cancel();
    _clearTimer?.cancel();

    _message = message;
    _subMessage = subMessage;
    _icon = icon;
    _accentColor = accentColor;
    _isExpanded = true;
    notifyListeners();

    _dismissTimer = Timer(duration, () {
      if (_message == message) {
        dismiss();
      }
    });
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _isExpanded = false;
    notifyListeners();

    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_isExpanded) {
        _message = null;
        _subMessage = null;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _clearTimer?.cancel();
    super.dispose();
  }
}

class DynamicIsland extends StatelessWidget {
  final DynamicIslandController controller;

  const DynamicIsland({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasContent = controller.message != null;
        final isExpanded = controller.isExpanded;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          height: isExpanded ? 46 : (hasContent ? 36 : 30),
          constraints: BoxConstraints(
            maxWidth: isExpanded ? 340 : (hasContent ? 200 : 120),
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isExpanded
                  ? controller.accentColor.withAlpha(90)
                  : Colors.white.withAlpha(20),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? controller.accentColor.withAlpha(40)
                    : Colors.black.withAlpha(120),
                blurRadius: isExpanded ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                if (isExpanded) {
                  controller.dismiss();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: controller.accentColor.withAlpha(35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.icon,
                        size: 14,
                        color: controller.accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.message ?? 'SPECTRA HIG',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppleTheme.label,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isExpanded && controller.subMessage != null)
                            Text(
                              controller.subMessage!,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppleTheme.secondaryLabel,
                                letterSpacing: -0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: controller.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
