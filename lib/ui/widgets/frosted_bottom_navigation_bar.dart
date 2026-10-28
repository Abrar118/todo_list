import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_tokens.dart';
import 'glass_surface.dart';

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
  static const _barHeight = 62.0;
  static const _labelAllowance = 10.0;
  static const _bottomGap = 10.0;

  /// Total space the floating bar occupies, including the gap beneath it and
  /// the gesture inset. Scrolling content must reserve this much at the
  /// bottom or its last row sits under the glass.
  static double heightOf(BuildContext context) =>
      _barHeight +
      MediaQuery.textScalerOf(context).scale(_labelAllowance) +
      _bottomGap +
      MediaQuery.paddingOf(context).bottom;

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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        _bottomGap + bottomInset,
      ),
      child: GlassSurface.chrome(
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
        child: SizedBox(
          height: _barHeight + textScaler.scale(_labelAllowance),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
    );
  }

  Widget _destination(int index, bool reduceMotion) => Expanded(
    child: _Destination(
      item: items[index],
      selected: index == selectedIndex,
      duration: reduceMotion ? Duration.zero : AppMotion.standard,
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
            // The signature lime, as a fill. `accent` is the text-safe token
            // and goes dark on paper, which would leave the most prominent
            // control in the app an olive disc in light mode.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.accentFill,
                Color.lerp(colors.accentFill, colors.onAccentFill, 0.18)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.accentFill.withValues(alpha: .34),
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
              foregroundColor: colors.onAccentFill,
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
    // Only the selected tab carries its hue. Four lit colours at once reads
    // as noise and leaves nothing for the selection itself to say.
    final tint = selected ? item.color : colors.textMuted;
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
            borderRadius: AppRadii.mediumRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: AppSpacing.xs,
              ),
              child: AnimatedContainer(
                duration: duration,
                curve: AppMotion.curve,
                decoration: BoxDecoration(
                  color: selected
                      ? item.color.withValues(alpha: .16)
                      : Colors.transparent,
                  borderRadius: AppRadii.mediumRadius,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: selected ? 22 : 20,
                      color: tint,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: tint,
                        fontSize: AppTypography.caption,
                        fontWeight: selected
                            ? FontWeight.w600
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
