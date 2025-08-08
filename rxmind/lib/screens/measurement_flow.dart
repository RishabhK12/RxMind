import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MeasurementFlow extends StatefulWidget {
  const MeasurementFlow({Key? key}) : super(key: key);

  @override
  State<MeasurementFlow> createState() => _MeasurementFlowState();
}

class _MeasurementFlowState extends State<MeasurementFlow> {
  int currentStep = 0;
  static const stepLabels = [
    '1. Sleep',
    '2. Eating',
    '3. Body',
    '4. Summary',
    '5. Discharge',
  ];

  static const totalSteps = 5;

  // Example state for each step
  double? sleepHours;
  Map<String, String> meals = {};
  double? weight;
  double? height;
  double? temperature;
  double? glucose;

  void nextStep() {
    if (currentStep < totalSteps - 1) {
      setState(() => currentStep++);
    } else {
      // Finish flow
      context.go('/main');
    }
  }

  void prevStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  void goToStep(int step) {
    setState(() => currentStep = step);
  }

  bool isStepComplete(int step) {
    switch (step) {
      case 0:
        return sleepHours != null && sleepHours! > 0;
      case 1:
        return meals.isNotEmpty;
      case 2:
        return weight != null && height != null;
      default:
        return true;
    }
  }

  Widget _buildStepContent(BuildContext context) {
    switch (currentStep) {
      case 0:
        return _SleepStep(
          sleepHours: sleepHours,
          onChanged: (v) => setState(() => sleepHours = v),
        );
      case 1:
        return _EatingStep(
          meals: meals,
          onChanged: (m) => setState(() => meals = m),
        );
      case 2:
        return _BodyStep(
          weight: weight,
          height: height,
          onChanged: (w, h) => setState(() {
            weight = w;
            height = h;
          }),
        );
      case 3:
        return _SummaryStep(
          sleepHours: sleepHours,
          meals: meals,
          weight: weight,
          height: height,
        );
      case 4:
        return _DischargeStep(
          onFinish: () => context.go('/main'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Info'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper menu
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: stepLabels.length,
                separatorBuilder: (context, i) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final isActive = i == currentStep;
                  return GestureDetector(
                    onTap: () => goToStep(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Text(
                            stepLabels[i].split('.').first + '.',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            stepLabels[i].split('.').last.trim(),
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStepContent(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (currentStep > 0)
                    ElevatedButton(
                      onPressed: prevStep,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 48),
                        backgroundColor: Colors.grey[400],
                      ),
                      child: const Text('Previous'),
                    ),
                  if (currentStep > 0) const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: isStepComplete(currentStep) ? nextStep : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 56),
                      backgroundColor: isStepComplete(currentStep)
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[400],
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child:
                        Text(currentStep == totalSteps - 1 ? 'Finish' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Step Widgets ---

class _SleepStep extends StatelessWidget {
  final double? sleepHours;
  final ValueChanged<double> onChanged;
  const _SleepStep({this.sleepHours, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
        text: sleepHours != null ? sleepHours.toString() : '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How many hours did you sleep last night?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Sleep Hours',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final val = double.tryParse(v);
            if (val != null) onChanged(val);
          },
        ),
      ],
    );
  }
}

class _EatingStep extends StatelessWidget {
  final Map<String, String> meals;
  final ValueChanged<Map<String, String>> onChanged;
  const _EatingStep({required this.meals, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('When did you eat your meals today?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...mealTypes.map((meal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                decoration: InputDecoration(
                  labelText: '$meal Time',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final updated = Map<String, String>.from(meals);
                  updated[meal] = v;
                  onChanged(updated);
                },
              ),
            )),
      ],
    );
  }
}

class _BodyStep extends StatelessWidget {
  final double? weight;
  final double? height;
  final void Function(double?, double?) onChanged;
  const _BodyStep({this.weight, this.height, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final weightController =
        TextEditingController(text: weight != null ? weight.toString() : '');
    final heightController =
        TextEditingController(text: height != null ? height.toString() : '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enter your body measurements:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => onChanged(double.tryParse(v), height),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: heightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => onChanged(weight, double.tryParse(v)),
        ),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  final double? sleepHours;
  final Map<String, String> meals;
  final double? weight;
  final double? height;
  const _SummaryStep(
      {this.sleepHours, required this.meals, this.weight, this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text('Sleep: ${sleepHours ?? '-'} hours'),
        ...meals.entries.map((e) => Text('${e.key}: ${e.value}')),
        Text('Weight: ${weight ?? '-'} kg'),
        Text('Height: ${height ?? '-'} cm'),
      ],
    );
  }
}

class _DischargeStep extends StatelessWidget {
  final VoidCallback onFinish;
  const _DischargeStep({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Ready for discharge?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onFinish,
            child: const Text('Upload & Finish'),
          ),
        ],
      ),
    );
  }
}


// --- Step Widgets ---


