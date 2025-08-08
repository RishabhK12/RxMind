import 'package:flutter/material.dart';
import 'package:rxmind_app/screens/home/home_dashboard.dart';
import 'package:rxmind_app/screens/stats/compliance_stats.dart';
import 'package:rxmind_app/screens/tracker/medications_screen.dart';
import 'package:rxmind_app/screens/settings/settings_screen.dart';
import 'package:rxmind_app/screens/ai/ai_chat_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const HomeDashboardScreen(),
    const ComplianceStatsScreen(),
    const MedicationsScreen(),
    // Real AI Chat screen
    const AiChatScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Semantics(
        label: 'Main navigation bar',
        container: true,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
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
                  label: 'Medications tab',
                  selected: _currentIndex == 2,
                  button: true,
                  child: _NavBarItem(
                    icon: Icons.medication,
                    label: 'Meds',
                    active: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
                Semantics(
                  label: 'AI Chat tab',
                  selected: _currentIndex == 3,
                  button: true,
                  child: _NavBarItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'AI Chat',
                    active: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ),
                Semantics(
                  label: 'Settings tab',
                  selected: _currentIndex == 4,
                  button: true,
                  child: _NavBarItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    active: _currentIndex == 4,
                    onTap: () => setState(() => _currentIndex = 4),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: active ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  icon,
                  color: active
                      ? const Color(0xFF00BFA5)
                      : const Color(0xFF757575),
                  size: 30,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: active
                      ? const Color(0xFF00BFA5)
                      : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
