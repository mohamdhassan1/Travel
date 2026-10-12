import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common/l10n_extensions.dart';

/// The signed-in app frame: the current tab and its navigation — a bottom
/// bar on phones, a side rail on wide windows (tablets, desktop web).
/// Pages pushed above it (destination details, booking, settings…) cover
/// it, so it never appears twice and back always behaves as expected.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Material 3's "expanded" window class starts at 840 dp.
  static const railBreakpoint = 840.0;

  void _select(int index) {
    // Re-selecting the current tab returns it to its first page.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final outline = Theme.of(context).colorScheme.outlineVariant;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      (Icons.explore_outlined, Icons.explore, l10n.navExplore),
      (Icons.luggage_outlined, Icons.luggage, l10n.navTrips),
      (Icons.favorite_border, Icons.favorite, l10n.navSaved),
      (Icons.person_outline, Icons.person, l10n.navProfile),
    ];

    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;
    // One tree for both layouts (the keyed shell keeps its tab stacks when
    // the window is resized across the breakpoint).
    return Scaffold(
      body: Row(
        children: [
          if (wide) ...[
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.85,
                destinations: [
                  for (final (icon, selected, label) in items)
                    NavigationRailDestination(
                      icon: Icon(icon),
                      selectedIcon: Icon(selected),
                      label: Text(label),
                    ),
                ],
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: outline),
          ],
          Expanded(key: const ValueKey('shell'), child: shell),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: outline))),
              child: NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _select,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (final (icon, selected, label) in items)
                    NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
                ],
              ),
            ),
    );
  }
}
