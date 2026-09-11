import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';

class FrostedNavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;

  const FrostedNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.color,
  });
}

class FrostedBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FrostedNavigationItem> items;

  const FrostedBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 4, 14, 10 + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: colors.background.withValues(alpha: 0.34),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.elevated.withValues(alpha: 0.88),
                    colors.card.withValues(alpha: 0.72),
                  ],
                ),
              ),
              child: SizedBox(
                height: 68,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _Destination(
                          item: items[i],
                          selected: i == selectedIndex,
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          onTap: () {
                            if (i != selectedIndex) {
                              HapticFeedback.selectionClick();
                              onDestinationSelected(i);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  final FrostedNavigationItem item;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  const _Destination({
    required this.item,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: selected
                      ? item.color.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: selected ? 23 : 21,
                      color: selected
                          ? item.color
                          : item.color.withValues(alpha: 0.72),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: selected ? item.color : colors.textMuted,
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
