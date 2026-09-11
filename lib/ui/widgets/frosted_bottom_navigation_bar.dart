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
  final VoidCallback onAdd;
  final List<FrostedNavigationItem> items;

  const FrostedBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAdd,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + bottomInset),
      child: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: [
                    BoxShadow(
                      color: colors.background.withValues(alpha: .42),
                      blurRadius: 26,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.elevated.withValues(alpha: .90),
                            colors.card.withValues(alpha: .76),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < items.length;
                            index++
                          ) ...[
                            if (index == 2) const SizedBox(width: 68),
                            Expanded(
                              child: _Destination(
                                item: items[index],
                                selected: index == selectedIndex,
                                duration: reduceMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 220),
                                onTap: () {
                                  if (index == selectedIndex) return;
                                  HapticFeedback.selectionClick();
                                  onDestinationSelected(index);
                                },
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
            Positioned(
              top: 0,
              child: Semantics(
                button: true,
                label: 'Add task',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: .34),
                        blurRadius: 24,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: 'nav-add-task',
                    tooltip: 'Add task',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onAdd();
                    },
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add_rounded, size: 30),
                  ),
                ),
              ),
            ),
          ],
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
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: selected
                      ? item.color.withValues(alpha: .16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: selected ? 22 : 20,
                      color: selected
                          ? item.color
                          : item.color.withValues(alpha: .72),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: selected ? item.color : colors.textMuted,
                        fontSize: 9.5,
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
