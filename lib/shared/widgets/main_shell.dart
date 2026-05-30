import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/design_tokens.dart';
import '../../routing/route_names.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static final _tabs = [
    (icon: Icons.home_outlined,     activeIcon: Icons.home_rounded,       label: 'Accueil',     route: RouteNames.feed),
    (icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department, label: 'Tendances', route: RouteNames.trends),
    (icon: Icons.add_circle_outline, activeIcon: Icons.add_circle,        label: '',            route: RouteNames.create),
    (icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Activité',   route: RouteNames.notifications),
    (icon: Icons.person_outline,    activeIcon: Icons.person,             label: 'Profil',      route: RouteNames.myProfile),
  ];

  int _getIndex(String location) {
    if (location.startsWith(RouteNames.feed)) return 0;
    if (location.startsWith(RouteNames.trends)) return 1;
    if (location.startsWith(RouteNames.create)) return 2;
    if (location.startsWith(RouteNames.notifications)) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndex(location);

    return Scaffold(
      extendBody: true, // Corps s'étend derrière la nav bar
      backgroundColor: GColors.void_,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: GColors.void_,
          border: const Border(
            top: BorderSide(color: GColors.border, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == currentIndex;
                final isCenter = i == 2; // Bouton Créer

                if (isCenter) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => context.go(tab.route),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: GColors.orange,
                            shape: BoxShape.circle,
                            boxShadow: GShadow.orangeGlow,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: GColors.textPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.route),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: GDuration.fast,
                          child: Icon(
                            isActive ? tab.activeIcon : tab.icon,
                            key: ValueKey(isActive),
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
      ),
    );
  }
}
