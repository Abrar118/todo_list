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
  static const _frostSaturation = <double>[
    1.52992,
    -0.47216,
    -0.05776,
    0,
    0,
    -0.14008,
    1.19784,
    -0.05776,
    0,
    0,
    -0.14008,
    -0.47216,
    1.61224,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

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
    assert(items.length == 4, 'The center action requires two items per side.');
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final textScaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 28,
              offset: Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.compose(
              outer: const ColorFilter.matrix(_frostSaturation),
              inner: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            ),
            child: Container(
              height: 62 + textScaler.scale(10),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x12FFFFFF), Color(0x05FFFFFF)],
                ),
              ),
              child: Row(
                children: [
                  _destination(0, reduceMotion),
                  _destination(1, reduceMotion),
                  Expanded(child: _addAction(context)),
                  _destination(2, reduceMotion),
                  _destination(3, reduceMotion),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _destination(int index, bool reduceMotion) => Expanded(
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
  );

  Widget _addAction(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Semantics(
        button: true,
        label: 'Add task',
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.accent, colors.accentDim],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: .34),
                blurRadius: 18,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: FloatingActionButton.small(
              heroTag: 'nav-add-task',
              tooltip: 'Add task',
              elevation: 0,
              highlightElevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: colors.onAccent,
              onPressed: () {
                HapticFeedback.mediumImpact();
                onAdd();
              },
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 27),
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
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: selected
                      ? item.color.withValues(alpha: .16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
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
