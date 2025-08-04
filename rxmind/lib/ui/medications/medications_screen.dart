import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../components/confetti_celebration.dart';
import '../../components/shimmer_card.dart';
import '../../components/parallax_background.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';

// ...existing code...
class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({Key? key}) : super(key: key);

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen>
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

  void _showAddMedicationDialog() {
    String name = '';
    String dosage = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (v) => name = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Dosage (HH:mm)'),
              onChanged: (v) => dosage = v,
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
              if (name.isNotEmpty) {
                await DatabaseService().insertMedication({
                  'name': name,
                  'dosage': dosage,
                });
                HapticFeedback.mediumImpact();
                // Schedule notification if dosage is a valid time
                try {
                  if (dosage.isNotEmpty) {
                    final now = DateTime.now();
                    final parts = dosage.split(':');
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
                          title: 'Medication Reminder',
                          body: name,
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
              title: const Text('Medications'),
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
                    future: DatabaseService().getAllMedications(),
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
                      final meds = snapshot.data ?? [];
                      if (meds.isEmpty) {
                        return const Center(child: Text('No medications yet.'));
                      }
                      return AnimatedBuilder(
                        animation: _listController,
                        builder: (context, child) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: meds.length,
                            itemBuilder: (context, i) {
                              final med = meds[i];
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
                                      title: Text(med['name'] ?? '',
                                          style: theme.textTheme.titleMedium),
                                      subtitle: Text(med['dosage'] ?? ''),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          await DatabaseService()
                                              .deleteMedication(med['id']);
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
                onPressed: _showAddMedicationDialog,
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
