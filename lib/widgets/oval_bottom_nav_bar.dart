import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/apple_theme.dart';

class OvalBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const OvalBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(140),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppleTheme.systemBlue.withAlpha(25),
                    blurRadius: 18,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xD918181B),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withAlpha(28),
                        width: 0.8,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = (constraints.maxWidth) / 3;

                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Animated Sliding Pill Background Indicator
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                              left: selectedIndex * itemWidth,
                              top: 0,
                              bottom: 0,
                              width: itemWidth,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppleTheme.systemBlue.withAlpha(45),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: AppleTheme.systemBlue.withAlpha(120),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppleTheme.systemBlue.withAlpha(50),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Interactive Tab Items
                            Row(
                              children: [
                                _buildNavItem(
                                  index: 0,
                                  icon: CupertinoIcons.square_grid_2x2,
                                  activeIcon: CupertinoIcons.square_grid_2x2_fill,
                                  label: 'Overview',
                                  width: itemWidth,
                                ),
                                _buildNavItem(
                                  index: 1,
                                  icon: CupertinoIcons.camera_viewfinder,
                                  activeIcon: CupertinoIcons.camera_viewfinder,
                                  label: 'Scanner',
                                  width: itemWidth,
                                ),
                                _buildNavItem(
                                  index: 2,
                                  icon: CupertinoIcons.folder,
                                  activeIcon: CupertinoIcons.folder_fill,
                                  label: 'Records',
                                  width: itemWidth,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required double width,
  }) {
    final isSelected = selectedIndex == index;

    return SizedBox(
      width: width,
      height: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => onItemSelected(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 0.95,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 21,
                  color: isSelected ? AppleTheme.systemBlue : AppleTheme.tertiaryLabel,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.2,
                  color: isSelected ? AppleTheme.label : AppleTheme.tertiaryLabel,
                  fontFamily: '.SF Pro Text',
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
