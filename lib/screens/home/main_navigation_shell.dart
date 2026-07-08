import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:rxmind_app/screens/home/home_dashboard.dart';
import 'package:rxmind_app/screens/stats/compliance_stats.dart';
import 'package:rxmind_app/screens/tracker/medications_screen.dart';
import 'package:rxmind_app/screens/tracker/tasks_screen.dart';
import 'package:rxmind_app/screens/settings/settings_screen.dart';
import 'package:rxmind_app/screens/ai/ai_chat_screen.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  static const double navBarHeight = 56;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  final GlobalKey<ComplianceStatsScreenState> _complianceStatsKey =
      GlobalKey<ComplianceStatsScreenState>();
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeDashboardScreen(
        onNavigateToTab: (int tabIndex) {
          setState(() => _currentIndex = tabIndex);
        },
      ),
      ComplianceStatsScreen(key: _complianceStatsKey),
      TasksScreen(complianceStatsKey: _complianceStatsKey),
      const MedicationsScreen(),
      const AiChatScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Semantics(
        sortKey: const OrdinalSortKey(0),
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: Semantics(
        sortKey: const OrdinalSortKey(2),
        label: 'Main navigation bar',
        container: true,
        child: SafeArea(
          top: false,
          bottom: true,
          minimum: EdgeInsets.zero,
          child: Container(
            height: MainNavigationShell.navBarHeight,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Dashboard',
                  hint: 'View your recovery dashboard',
                ),
                _navItem(
                  index: 1,
                  icon: Icons.show_chart_rounded,
                  label: 'Charts',
                  hint: 'View wellness charts and stats',
                ),
                _navItem(
                  index: 2,
                  icon: Icons.checklist_rounded,
                  label: 'Tasks',
                  hint: 'View and manage your tasks',
                ),
                _navItem(
                  index: 3,
                  icon: Icons.medication,
                  label: 'Meds',
                  hint: 'View your medication list',
                ),
                _navItem(
                  index: 4,
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  hint: 'Open wellness chat assistant',
                ),
                _navItem(
                  index: 5,
                  icon: Icons.settings,
                  label: 'Settings',
                  hint: 'Open app settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required String hint,
  }) {
    final active = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final ext = RxMindThemeExtension.of(context);

    return Expanded(
      child: Semantics(
        label: '$label tab',
        hint: hint,
        selected: active,
        button: true,
        child: _NavBarItem(
          icon: icon,
          label: label,
          active: active,
          activeColor: colorScheme.secondary,
          inactiveColor: ext.navInactive,
          onTap: () => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: ThemeTokens.fontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
