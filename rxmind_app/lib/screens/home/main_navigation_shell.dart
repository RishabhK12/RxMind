import 'package:flutter/material.dart';
import 'package:rxmind_app/screens/home/home_dashboard.dart';
import 'package:rxmind_app/screens/stats/compliance_stats.dart';
import 'package:rxmind_app/screens/tracker/medications_screen.dart';
import 'package:rxmind_app/screens/tracker/tasks_screen.dart';
import 'package:rxmind_app/screens/settings/settings_screen.dart';
import 'package:rxmind_app/screens/ai/ai_chat_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

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
      const TasksScreen(),
      const MedicationsScreen(),
      const AiChatScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Semantics(
        label: 'Main navigation bar',
        container: true,
        child: SafeArea(
          top: false,
          bottom: true,
          minimum: EdgeInsets.zero,
          child: Container(
            // Reduced height and added clipBehavior to prevent overflow
            height: 52,
            padding: const EdgeInsets.only(bottom: 0),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232526) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // ...existing code for nav bar items...
                Semantics(
                  label: 'Dashboard tab',
                  selected: _currentIndex == 0,
                  button: true,
                  child: _NavBarItem(
                    icon: Icons.home_rounded,
                    label: 'Dashboard',
                    active: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                ),
                Semantics(
                  label: 'Charts tab',
                  selected: _currentIndex == 1,
                  button: true,
                  child: _NavBarItem(
                    icon: Icons.show_chart_rounded,
                    label: 'Charts',
                    active: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                Semantics(
                  label: 'Tasks tab',
                  selected: _currentIndex == 2,
                  button: true,
                  child: _NavBarItem(
                    icon: Icons.checklist_rounded,
                    label: 'Tasks',
                    active: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
                Semantics(
                  label: 'Medications tab',
                  selected: _currentIndex == 3,
                  button: true,
                  child: _NavBarItem(
                    icon: Icons.medication,
                    label: 'Meds',
                    active: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ),
                Semantics(
                  label: 'AI Chat tab',
                  selected: _currentIndex == 4,
                  button: true,
                  child: _NavBarItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'AI Chat',
                    active: _currentIndex == 4,
                    onTap: () => setState(() => _currentIndex = 4),
                  ),
                ),
                Semantics(
                  label: 'Settings tab',
                  selected: _currentIndex == 5,
                  button: true,
                  child: _NavBarItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    active: _currentIndex == 5,
                    onTap: () => setState(() => _currentIndex = 5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavBarItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                icon,
                color:
                    active ? const Color(0xFF00BFA5) : const Color(0xFF757575),
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color:
                    active ? const Color(0xFF00BFA5) : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
