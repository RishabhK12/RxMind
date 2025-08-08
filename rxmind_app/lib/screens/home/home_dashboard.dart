import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  // Dummy data for preview
  final String userName = 'Alex';
  final List<Map<String, dynamic>> tasks = [
    {'title': 'Take Morning Meds', 'progress': 0.7},
    {'title': 'Follow-up Call', 'progress': 0.3},
    {'title': 'Check Vitals', 'progress': 0.9},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        title: Row(
          children: [
            Semantics(
              label: 'User profile avatar',
              child: CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.secondary,
                child: Text(
                  userName[0],
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              label: 'Greeting: Hi, $userName',
              child: Text(
                'Hi, $userName',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
      body: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 300),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Semantics(
                  label: 'Upcoming Tasks',
                  child: Text(
                    'Upcoming Tasks',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, i) {
                    final task = tasks[i];
                    return Semantics(
                      label:
                          'Task: ${task['title']}, progress ${(task['progress'] * 100).round()} percent',
                      child: _TaskCard(
                        title: task['title'],
                        progress: task['progress'],
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  Semantics(
                    label: 'Upload Discharge',
                    button: true,
                    child: _ActionTile(
                      icon: Icons.upload_file,
                      label: 'Upload Discharge',
                      color: theme.colorScheme.primary,
                      onTap: () =>
                          Navigator.pushNamed(context, '/uploadOptions'),
                    ),
                  ),
                  Semantics(
                    label: 'Medications',
                    button: true,
                    child: _ActionTile(
                      icon: FontAwesomeIcons.pills,
                      label: 'Medications',
                      color: theme.colorScheme.secondary,
                      onTap: () => Navigator.pushNamed(context, '/medications'),
                    ),
                  ),
                  Semantics(
                    label: 'Tasks & Reminders',
                    button: true,
                    child: _ActionTile(
                      icon: Icons.checklist_rtl,
                      label: 'Tasks & Reminders',
                      color: theme.colorScheme.primary,
                      onTap: () => Navigator.pushNamed(context, '/tasks'),
                    ),
                  ),
                  Semantics(
                    label: 'Stats',
                    button: true,
                    child: _ActionTile(
                      icon: Icons.bar_chart,
                      label: 'Stats',
                      color: theme.colorScheme.secondary,
                      onTap: () => Navigator.pushNamed(context, '/stats'),
                    ),
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 120,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Semantics(
        label: 'Add new task',
        button: true,
        child: FloatingActionButton(
          backgroundColor: theme.colorScheme.secondary,
          child: const Icon(Icons.add, size: 28, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/newTask'),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final double progress;
  const _TaskCard({required this.title, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor:
                      AlwaysStoppedAnimation(theme.colorScheme.secondary),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
