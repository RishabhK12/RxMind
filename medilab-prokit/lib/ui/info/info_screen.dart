import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../components/shimmer_card.dart';
import '../../components/processing_plan_screen.dart';
import '../../components/confetti_celebration.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  bool _showProcessing = false;
  bool _showConfetti = false;
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  TimeOfDay? sleepStart;
  TimeOfDay? sleepEnd;
  Set<String> eatingTimes = {};
  double height = 170;
  double weight = 70;
  int? sysBP;
  int? diaBP;
  String? dischargeImagePath;
  bool isUploading = false;
  bool isLoading = false;

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (sleepStart ?? TimeOfDay(hour: 22, minute: 0))
          : (sleepEnd ?? TimeOfDay(hour: 7, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          sleepStart = picked;
        else
          sleepEnd = picked;
      });
    }

    // ...existing code...
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => dischargeImagePath = picked.path);
    }
  }

  void _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    // Save UserProfile to DB
    final userProfile = UserProfile(
      sleepStart: sleepStart,
      sleepEnd: sleepEnd,
      eatingTimes: eatingTimes.join(','),
      height: height,
      weight: weight,
      sysBP: sysBP,
      diaBP: diaBP,
      dischargeImagePath: dischargeImagePath,
    );
    await DatabaseService().insertSetting({
      'key': 'user_profile',
      'value': userProfile.toString(),
    });
    // Add discharge image to upload queue if present
    if (dischargeImagePath != null) {
      setState(() => _showProcessing = true);
      await DatabaseService().insertUploadQueue({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'filepath': dischargeImagePath!,
        'status': 'queued',
        'created_at': DateTime.now().toIso8601String(),
      });
      // Simulate processing delay and confetti for first AI success
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _showProcessing = false;
        _showConfetti = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _showConfetti = false);
    }
    setState(() => isLoading = false);
    if (mounted) Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Setup Profile')),
          body: Form(
            key: _formKey,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Stepper(
                key: ValueKey(_currentStep),
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 4) {
                    setState(() => _currentStep++);
                  } else {
                    _saveProfile();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) setState(() => _currentStep--);
                },
                controlsBuilder: (context, details) => Row(
                  children: [
                    ElevatedButton(
                      onPressed: isLoading ? null : details.onStepContinue,
                      child: isLoading
                          ? const SizedBox(
                              width: 60,
                              height: 24,
                              child: ShimmerCard(height: 24, width: 60))
                          : Text(_currentStep == 4 ? 'Finish Setup' : 'Next'),
                    ),
                    if (_currentStep > 0)
                      TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back')),
                  ],
                ),
                steps: [
                  // ...existing code for steps...
                  Step(
                    title: const Text('Sleep'),
                    content: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Text(sleepStart == null
                                    ? 'Start Time'
                                    : sleepStart!.format(context)),
                                trailing: const Icon(Icons.access_time),
                                onTap: () => _pickTime(true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ListTile(
                                title: Text(sleepEnd == null
                                    ? 'End Time'
                                    : sleepEnd!.format(context)),
                                trailing: const Icon(Icons.access_time),
                                onTap: () => _pickTime(false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isActive: _currentStep == 0,
                  ),
                  Step(
                    title: const Text('Eating'),
                    content: Column(
                      children: [
                        Wrap(
                          spacing: 12,
                          children: [
                            ChoiceChip(
                              label: const Text('Breakfast'),
                              selected: eatingTimes.contains('breakfast'),
                              onSelected: (v) => setState(() => v
                                  ? eatingTimes.add('breakfast')
                                  : eatingTimes.remove('breakfast')),
                            ),
                            ChoiceChip(
                              label: const Text('Lunch'),
                              selected: eatingTimes.contains('lunch'),
                              onSelected: (v) => setState(() => v
                                  ? eatingTimes.add('lunch')
                                  : eatingTimes.remove('lunch')),
                            ),
                            ChoiceChip(
                              label: const Text('Dinner'),
                              selected: eatingTimes.contains('dinner'),
                              onSelected: (v) => setState(() => v
                                  ? eatingTimes.add('dinner')
                                  : eatingTimes.remove('dinner')),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isActive: _currentStep == 1,
                  ),
                  Step(
                    title: const Text('Body'),
                    content: Column(
                      children: [
                        Row(
                          children: [
                            const Text('Height'),
                            Expanded(
                              child: Slider(
                                value: height,
                                min: 120,
                                max: 220,
                                divisions: 100,
                                label: '${height.round()} cm',
                                onChanged: (v) => setState(() => height = v),
                              ),
                            ),
                            Text('${height.round()} cm'),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Weight'),
                            Expanded(
                              child: Slider(
                                value: weight,
                                min: 30,
                                max: 150,
                                divisions: 120,
                                label: '${weight.round()} kg',
                                onChanged: (v) => setState(() => weight = v),
                              ),
                            ),
                            Text('${weight.round()} kg'),
                          ],
                        ),
                      ],
                    ),
                    isActive: _currentStep == 2,
                  ),
                  Step(
                    title: const Text('BP'),
                    content: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Systolic (SYS)'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => sysBP = int.tryParse(v),
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Diastolic (DIA)'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => diaBP = int.tryParse(v),
                        ),
                      ],
                    ),
                    isActive: _currentStep == 3,
                  ),
                  Step(
                    title: const Text('Discharge'),
                    content: Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Discharge Paper'),
                          onPressed: isUploading ? null : _pickImage,
                        ),
                        if (dischargeImagePath != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.file(
                              File(dischargeImagePath!),
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
                    isActive: _currentStep == 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showProcessing) const ProcessingPlanScreen(),
        if (_showConfetti) const ConfettiCelebration(),
      ],
    );
  }
}
