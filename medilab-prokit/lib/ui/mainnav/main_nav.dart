import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../tasks/tasks_screen.dart';
import '../medications/medications_screen.dart';
import '../settings/settings_screen.dart';
import '../../components/animated_nav_icon.dart';

class MainNav extends StatefulWidget {
  const MainNav({Key? key}) : super(key: key);

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const MedicationsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(
            icon: AnimatedNavIcon(
              icon: Icons.home,
              active: _currentIndex == 0,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: AnimatedNavIcon(
              icon: Icons.check_circle,
              active: _currentIndex == 1,
            ),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: AnimatedNavIcon(
              icon: Icons.medication,
              active: _currentIndex == 2,
            ),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: AnimatedNavIcon(
              icon: Icons.settings,
              active: _currentIndex == 3,
            ),
            label: 'Settings',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3A86FF),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 12,
      ),
    );
  }
}
