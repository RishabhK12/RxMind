import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import 'package:medilab_prokit/ui/home/_compliance_calendar.dart';
import 'package:medilab_prokit/ui/home/_streaks_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/scheduler.dart';
// import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../services/upload_queue_processor.dart';
// import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _playedVictory = false;
  bool _uploadedToday(List<Map<String, dynamic>> uploads) {
    final today = DateTime.now();
    return uploads.any((u) {
      final created = DateTime.tryParse(u['created_at'] ?? '') ??
          today.subtract(const Duration(days: 1));
      return created.year == today.year &&
          created.month == today.month &&
          created.day == today.day;
    });
  }

  Future<void> _refreshDashboard() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    UploadQueueProcessor().addListener(_onUploadQueueProcessed);
  }

  @override
  void dispose() {
    UploadQueueProcessor().removeListener(_onUploadQueueProcessed);
    _greetingController.dispose();
    _cardController.dispose();
    _pieController.dispose();
    super.dispose();
  }

  void _onUploadQueueProcessed() {
    if (mounted) {
      setState(() {}); // Refresh dashboard data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discharge paper(s) uploaded and processed!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  late Stream<ConnectivityResult> _connectivityStream;
  bool _isOffline = false;
  Future<void> _pickAndQueueDischargePaper() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        await DatabaseService().insertUploadQueue({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'file_path': picked.path,
          'status': 'queued',
          'created_at': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Discharge paper added to upload queue.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  late AnimationController _greetingController;
  late AnimationController _cardController;
  late AnimationController _pieController;

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _greetingController.forward();
      Future.delayed(
          const Duration(milliseconds: 200), () => _cardController.forward());
      Future.delayed(
          const Duration(milliseconds: 400), () => _pieController.forward());
    });

    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((result) {
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Home'),
          elevation: 0,
          backgroundColor: Colors.transparent,
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
                builder: (context, taskSnapshot) {
                  if (taskSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tasks = taskSnapshot.data ?? [];
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: DatabaseService().getAllMedications(),
                    builder: (context, medSnapshot) {
                      if (medSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final meds = medSnapshot.data ?? [];
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: DatabaseService().getAllCompliance(),
                        builder: (context, compSnapshot) {
                          if (compSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          // final compliance = compSnapshot.data ?? [];
                          int completed =
                              tasks.where((t) => t['completed'] == 1).length;
                          int total = tasks.length;
                          String compliancePercent = total > 0
                              ? ((completed / total * 100).round().toString() +
                                  '%')
                              : '0%';
                          // Play victory sound if 100% compliance and not already played
                          bool allComplete = total > 0 && completed == total;
                          if (allComplete && !_playedVictory) {
                            _playedVictory = true;
                            _audioPlayer.play(AssetSource('audio/victory.mp3'));
                          } else if (!allComplete && _playedVictory) {
                            _playedVictory = false;
                          }
                          return RefreshIndicator(
                            onRefresh: _refreshDashboard,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Animated Greeting
                                    FadeTransition(
                                      opacity: _greetingController,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(-0.2, 0),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                            parent: _greetingController,
                                            curve: Curves.easeOut)),
                                        child: Text(
                                          'Good morning, [Name]',
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Animated Summary Cards
                                    SizedBox(
                                      height: 120,
                                      child: AnimatedBuilder(
                                        animation: _cardController,
                                        builder: (context, child) {
                                          return ListView(
                                            scrollDirection: Axis.horizontal,
                                            children: [
                                              Transform.translate(
                                                offset: Offset(
                                                    0,
                                                    40 *
                                                        (1 -
                                                            _cardController
                                                                .value)),
                                                child: Opacity(
                                                  opacity:
                                                      _cardController.value,
                                                  child: _SummaryCard(
                                                      title: 'Today\'s Tasks',
                                                      value: tasks.length
                                                          .toString()),
                                                ),
                                              ),
                                              Transform.translate(
                                                offset: Offset(
                                                    0,
                                                    40 *
                                                        (1 -
                                                            _cardController
                                                                .value)),
                                                child: Opacity(
                                                  opacity:
                                                      _cardController.value,
                                                  child: _SummaryCard(
                                                      title: 'Meds Left',
                                                      value: meds.length
                                                          .toString()),
                                                ),
                                              ),
                                              Transform.translate(
                                                offset: Offset(
                                                    0,
                                                    40 *
                                                        (1 -
                                                            _cardController
                                                                .value)),
                                                child: Opacity(
                                                  opacity:
                                                      _cardController.value,
                                                  child: _SummaryCard(
                                                      title: 'Compliance',
                                                      value: compliancePercent),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Compliance Pie Chart
                                    Center(
                                      child: total == 0
                                          ? const Text(
                                              'No compliance data yet.')
                                          : PieChart(
                                              PieChartData(
                                                sections: [
                                                  PieChartSectionData(
                                                    value: completed
                                                            .toDouble() *
                                                        _pieController.value,
                                                    color: Colors.greenAccent,
                                                    title: completed > 0
                                                        ? '${(completed * _pieController.value).round()}'
                                                        : '0',
                                                    radius: 60,
                                                    titleStyle: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18),
                                                  ),
                                                  PieChartSectionData(
                                                    value: (total - completed)
                                                            .toDouble() *
                                                        _pieController.value,
                                                    color: Colors.redAccent,
                                                    title: (total - completed) >
                                                            0
                                                        ? '${((total - completed) * _pieController.value).round()}'
                                                        : '0',
                                                    radius: 50,
                                                    titleStyle: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                ],
                                                sectionsSpace: 4,
                                                centerSpaceRadius: 32,
                                              ),
                                            ),
                                    ),
                                    // Compliance Calendar & Streaks
                                    const SizedBox(height: 24),
                                    ComplianceCalendar(
                                        compliance: compSnapshot.data ?? []),
                                    const SizedBox(height: 16),
                                    StreaksWidget(
                                        compliance: compSnapshot.data ?? []),
                                    const SizedBox(height: 24),
                                    // Upload Discharge Paper button
                                    FutureBuilder<List<Map<String, dynamic>>>(
                                      future:
                                          DatabaseService().getQueuedUploads(),
                                      builder: (context, uploadSnapshot) {
                                        final uploaded =
                                            uploadSnapshot.data ?? [];
                                        final hasUploadedToday =
                                            _uploadedToday(uploaded);
                                        return TweenAnimationBuilder<double>(
                                          tween: Tween(
                                              begin: 1.0,
                                              end: hasUploadedToday
                                                  ? 1.0
                                                  : 1.08),
                                          duration: const Duration(seconds: 1),
                                          curve: Curves.easeInOut,
                                          builder: (context, scale, child) {
                                            return Transform.scale(
                                              scale: scale,
                                              child: child,
                                            );
                                          },
                                          onEnd: () {
                                            if (!hasUploadedToday && mounted)
                                              setState(() {});
                                          },
                                          child: Opacity(
                                            opacity:
                                                hasUploadedToday ? 0.6 : 1.0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF43cea2),
                                                    Color(0xFF185a9d)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.blue
                                                        .withAlpha((0.18 * 255)
                                                            .toInt()),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  onTap: hasUploadedToday
                                                      ? null
                                                      : _pickAndQueueDischargePaper,
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 14,
                                                        horizontal: 24),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: const [
                                                        Icon(Icons.upload_file,
                                                            color:
                                                                Colors.white),
                                                        SizedBox(width: 12),
                                                        Text(
                                                            'Upload Discharge Paper',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
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
      ),
    );
  }
}

// Simple summary card widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  const _SummaryCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 120,
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    )),
            const SizedBox(height: 8),
            Text(title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    )),
          ],
        ),
      ),
    );
  }
}
