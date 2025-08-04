import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../components/confetti_celebration.dart';
import '../../components/shimmer_card.dart';
import '../../components/parallax_background.dart';
import '../../components/blur_modal.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  bool _showConfetti = false;
  late Stream<List<ConnectivityResult>> _connectivityStream;
  bool _isOffline = false;
  late AnimationController _listController;
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(
        const Duration(milliseconds: 200), () => _listController.forward());

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _fabScale = Tween<double>(begin: 1.0, end: 1.12)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_fabController);
    _fabController.repeat(reverse: true, period: const Duration(seconds: 2));

    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      final offline = result == ConnectivityResult.none;
      if (offline != _isOffline && mounted) {
        setState(() => _isOffline = offline);
        if (offline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are offline. Changes will be saved locally.'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Back online!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _listController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    String title = '';
    String time = '';
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => BlurModal(
        child: AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (v) => title = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Time (HH:mm)'),
                onChanged: (v) => time = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isNotEmpty) {
                  await DatabaseService().insertTask({
                    'title': title,
                    'time': time,
                    'completed': 0,
                  });
                  HapticFeedback.mediumImpact();
                  // Schedule notification if time is valid
                  try {
                    if (time.isNotEmpty) {
                      final now = DateTime.now();
                      final parts = time.split(':');
                      if (parts.length == 2) {
                        final hour = int.tryParse(parts[0]);
                        final minute = int.tryParse(parts[1]);
                        if (hour != null && minute != null) {
                          DateTime scheduled = DateTime(
                              now.year, now.month, now.day, hour, minute);
                          if (scheduled.isBefore(now)) {
                            scheduled = scheduled.add(const Duration(days: 1));
                          }
                          await NotificationService().init();
                          await NotificationService().scheduleNotification(
                            id: now.millisecondsSinceEpoch.remainder(100000),
                            title: 'Task Reminder',
                            body: title,
                            scheduledDate: scheduled,
                          );
                        }
                      }
                    }
                  } catch (_) {}
                  if (mounted)
                    setState(() {
                      _showConfetti = true;
                    });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ParallaxBackground(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Tasks'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Column(
              children: [
                if (_isOffline)
                  Container(
                    width: double.infinity,
                    color: Colors.red[100],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Center(
                      child: Text(
                        'Offline: changes will sync when online.',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: DatabaseService().getAllTasks(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Shimmer loading effect
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: 3,
                          itemBuilder: (context, i) => const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: ShimmerCard(height: 80),
                          ),
                        );
                      }
                      final tasks = snapshot.data ?? [];
                      if (tasks.isEmpty) {
                        return const Center(child: Text('No tasks yet.'));
                      }
                      return AnimatedBuilder(
                        animation: _listController,
                        builder: (context, child) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: tasks.length,
                            itemBuilder: (context, i) {
                              final task = tasks[i];
                              return Transform.translate(
                                offset:
                                    Offset(0, 40 * (1 - _listController.value)),
                                child: Opacity(
                                  opacity: _listController.value,
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    child: ListTile(
                                      title: Text(task['title'] ?? '',
                                          style: theme.textTheme.titleMedium),
                                      subtitle: Text(task['time'] ?? ''),
                                      leading: Checkbox(
                                        value: task['completed'] == 1,
                                        onChanged: (v) async {
                                          final updatedTask =
                                              Map<String, dynamic>.from(task);
                                          updatedTask['completed'] = v! ? 1 : 0;
                                          await DatabaseService()
                                              .updateTask(updatedTask);
                                          HapticFeedback.selectionClick();
                                          if (mounted) setState(() {});
                                        },
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          await DatabaseService()
                                              .deleteTask(task['id']);
                                          HapticFeedback.heavyImpact();
                                          if (mounted) setState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: ScaleTransition(
              scale: _fabScale,
              child: FloatingActionButton(
                onPressed: _showAddTaskDialog,
                backgroundColor: const Color(0xFF43cea2),
                child: const Icon(Icons.add),
              ),
            ),
          ),
          if (_showConfetti)
            ConfettiCelebration(
              onEnd: () {
                if (mounted) setState(() => _showConfetti = false);
              },
            ),
        ],
      ),
    );
  }
}
