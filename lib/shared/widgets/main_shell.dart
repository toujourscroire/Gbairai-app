import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/design_tokens.dart';
import '../../routing/route_names.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static final _tabs = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
      route: RouteNames.feed,
    ),
    (
      icon: Icons.local_fire_department_outlined,
      activeIcon: Icons.local_fire_department_rounded,
      label: 'Tendances',
      route: RouteNames.trends,
    ),
    (
      icon: Icons.add,
      activeIcon: Icons.add,
      label: '',
      route: RouteNames.create,
    ),
    (
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Activité',
      route: RouteNames.notifications,
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
      route: RouteNames.myProfile,
    ),
  ];

  int _getIndex(String location) {
    if (location.startsWith(RouteNames.feed)) return 0;
    if (location.startsWith(RouteNames.trends)) return 1;
    if (location.startsWith(RouteNames.create)) return 2;
    if (location.startsWith(RouteNames.notifications)) return 3;
    if (location.startsWith(RouteNames.myProfile)) return 4;
    if (location.startsWith('/profile')) return 4; // deep links /profile/:userId
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndex(location);

    return Scaffold(
      extendBody: true,
      backgroundColor: GColors.void_,
      body: child,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: currentIndex,
        tabs: _tabs,
        onTap: (i) => context.go(_tabs[i].route),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<({IconData icon, IconData activeIcon, String label, String route})> tabs;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GColors.void_,
        border: Border(
          top: BorderSide(color: GColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 52,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == currentIndex;
              final isCenter = i == 2;

              if (isCenter) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: GColors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: GColors.orange.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: GDuration.fast,
                        switchInCurve: Curves.easeOut,
                        child: Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          key: ValueKey('${i}_$isActive'),
                          color: isActive
                              ? GColors.orange
                              : GColors.textTertiary,
                          size: 24,
                        ),
                      ),
                      if (tab.label.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: GDuration.fast,
                          style: GTextStyle.labelSmall.copyWith(
                            color: isActive
                                ? GColors.orange
                                : GColors.textTertiary,
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          child: Text(tab.label),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
