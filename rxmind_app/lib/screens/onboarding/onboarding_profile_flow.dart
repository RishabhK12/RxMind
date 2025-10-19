import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';

class OnboardingProfileFlow extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingProfileFlow({super.key, required this.onComplete});

  @override
  State<OnboardingProfileFlow> createState() => _OnboardingProfileFlowState();
}

class _OnboardingProfileFlowState extends State<OnboardingProfileFlow> {
  @override
  void initState() {
    super.initState();
  }

  // Profile data
  String? firstName;
  String? lastName;
  int? heightCm;
  int? weightKg;
  bool useMetric = true;
  String? customDietaryRestriction;
  String? customChronicCondition;
  int? age;
  String? sex;
  TimeOfDay? bedtime;
  TimeOfDay? wakeTime;
  String? activityLevel;
  List<String> dietaryRestrictions = [];
  List<String> chronicConditions = [];
  List<String> allergies = [];

  // Navigation
  int currentStep = 0;
  final int totalSteps = 9; // Increased from 8 to include name step

  // Validation
  bool get canContinue {
    switch (currentStep) {
      case 0:
        return firstName != null &&
            firstName!.isNotEmpty &&
            lastName != null &&
            lastName!.isNotEmpty;
      case 1:
        return heightCm != null;
      case 2:
        return weightKg != null;
      case 3:
        return age != null;
      case 4:
        return sex != null;
      case 5:
        return bedtime != null && wakeTime != null;
      case 6:
        return activityLevel != null;
      default:
        return true;
    }
  }

  Future<void> next() async {
    if (currentStep < totalSteps - 1) {
      setState(() => currentStep++);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);

      // Save all profile data using DischargeDataManager
      await DischargeDataManager.saveProfileData(
        name: firstName != null && lastName != null
            ? '$firstName $lastName'
            : null,
        height: heightCm,
        weight: weightKg,
        age: age,
        sex: sex,
        bedtime: bedtime != null ? '${bedtime!.hour}:${bedtime!.minute}' : null,
        wakeTime:
            wakeTime != null ? '${wakeTime!.hour}:${wakeTime!.minute}' : null,
      );

      widget.onComplete();
    }
  }

  void back() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  Widget buildProgressBar() {
    // ...existing code...
    // ...existing code...
    final theme = Theme.of(context);
    return Semantics(
      label: 'Progress: Step ${currentStep + 1} of $totalSteps',
      value: '${((currentStep + 1) / totalSteps * 100).round()} percent',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget buildQuestion() {
    final theme = Theme.of(context);
    switch (currentStep) {
      case 0:
        return Semantics(
          label: 'Name input',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What\'s your name?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212121))),
                const SizedBox(height: 32),
                TextField(
                  onChanged: (val) => setState(() => firstName = val),
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    hintText: 'Enter your first name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) => setState(() => lastName = val),
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Enter your last name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
        );
      case 1:
        return Semantics(
          label: 'Height input',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Units:'),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Metric (cm)'),
                    selected: useMetric,
                    onSelected: (v) => setState(() => useMetric = true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Customary (in)'),
                    selected: !useMetric,
                    onSelected: (v) => setState(() => useMetric = false),
                  ),
                ],
              ),
              _NumberPickerCard(
                title: 'What is your height?',
                unit1: useMetric ? 'cm' : 'in',
                min: useMetric ? 100 : 39,
                max: useMetric ? 220 : 87,
                value: useMetric
                    ? heightCm
                    : heightCm != null
                        ? (heightCm! / 2.54).round()
                        : null,
                onChanged: (v) => setState(() {
                  heightCm = useMetric ? v : (v * 2.54).round();
                }),
              ),
            ],
          ),
        );
      case 2:
        return Semantics(
          label: 'Weight input',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Units:'),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Metric (kg)'),
                    selected: useMetric,
                    onSelected: (v) => setState(() => useMetric = true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Customary (lb)'),
                    selected: !useMetric,
                    onSelected: (v) => setState(() => useMetric = false),
                  ),
                ],
              ),
              _NumberPickerCard(
                title: 'What is your weight?',
                unit1: useMetric ? 'kg' : 'lb',
                min: useMetric ? 30 : 66,
                max: useMetric ? 200 : 440,
                value: useMetric
                    ? weightKg
                    : weightKg != null
                        ? (weightKg! * 2.20462).round()
                        : null,
                onChanged: (v) => setState(() {
                  weightKg = useMetric ? v : (v / 2.20462).round();
                }),
              ),
            ],
          ),
        );
      case 3:
        return Semantics(
          label: 'Age input',
          child: _NumberPickerCard(
            title: 'What is your age?',
            unit1: 'years',
            min: 10,
            max: 120,
            value: age,
            onChanged: (v) => setState(() => age = v),
          ),
        );
      case 4:
        return Semantics(
          label: 'Sex selection',
          child: _SexPickerCard(
            value: sex,
            onChanged: (v) => setState(() => sex = v),
          ),
        );
      case 5:
        return Semantics(
          label: 'Sleep schedule input',
          child: _SleepScheduleCard(
            bedtime: bedtime,
            wakeTime: wakeTime,
            onChanged: (b, w) => setState(() {
              bedtime = b;
              wakeTime = w;
            }),
          ),
        );
      case 6:
        return Semantics(
          label: 'Activity level selection',
          child: _ActivityLevelCard(
            value: activityLevel,
            onChanged: (v) => setState(() => activityLevel = v),
          ),
        );
      case 7:
        return Column(
          children: [
            _ChipSelectCard(
              title: 'Any dietary restrictions?',
              options: [
                'Vegetarian',
                'Vegan',
                'Gluten-Free',
                'Dairy-Free',
                'Nut-Free',
                'Other'
              ],
              selected: dietaryRestrictions,
              onChanged: (v) => setState(() => dietaryRestrictions = v),
              optional: true,
            ),
            if (dietaryRestrictions.contains('Other'))
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Please specify',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) =>
                      setState(() => customDietaryRestriction = val),
                ),
              ),
          ],
        );
      case 8:
        return Column(
          children: [
            _ChipSelectCard(
              title: 'Any chronic conditions?',
              options: [
                'Diabetes',
                'Hypertension',
                'Asthma',
                'COPD',
                'Heart Disease',
                'Other'
              ],
              selected: chronicConditions,
              onChanged: (v) => setState(() => chronicConditions = v),
              optional: true,
            ),
            if (chronicConditions.contains('Other'))
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Please specify',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) =>
                      setState(() => customChronicCondition = val),
                ),
              ),
          ],
        );
      case 9:
        return _ChipSelectCard(
          title: 'Any allergies?',
          options: ['Penicillin', 'Peanuts', 'Latex', 'Shellfish', 'Other'],
          selected: allergies,
          onChanged: (v) => setState(() => allergies = v),
          optional: true,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      buildProgressBar(),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, anim) => SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                          child: buildQuestion(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Row(
                          children: [
                            if (currentStep > 0)
                              TextButton(
                                onPressed: back,
                                child: Semantics(
                                  label: 'Back',
                                  button: true,
                                  child: Text('Back',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.grey)),
                                ),
                              ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: canContinue ? next : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 14),
                                elevation: 0,
                              ),
                              child: Semantics(
                                label: canContinue
                                    ? 'Continue'
                                    : 'Continue (disabled)',
                                button: true,
                                enabled: canContinue,
                                child: const Text('Continue'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- UI Helper Widgets ---

class _NumberPickerCard extends StatelessWidget {
  final String title;
  final String unit1;
  final int min;
  final int max;
  final int? value;
  final ValueChanged<int> onChanged;
  const _NumberPickerCard(
      {required this.title,
      required this.unit1,
      required this.min,
      required this.max,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 180,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 48,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => onChanged(min + i),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: max - min + 1,
                      builder: (ctx, i) => Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: theme.textTheme.displaySmall!.copyWith(
                            color: (value == min + i)
                                ? theme.colorScheme.primary
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                          child: Text('${min + i} $unit1'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SexPickerCard extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  const _SexPickerCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      {'label': 'Male', 'icon': Icons.male},
      {'label': 'Female', 'icon': Icons.female},
      {'label': 'Other', 'icon': Icons.transgender},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is your biological sex?',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: options.map((opt) {
              final selected = value == opt['label'];
              return GestureDetector(
                onTap: () => onChanged(opt['label'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: selected ? theme.colorScheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.grey.shade300,
                        width: 2),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.08),
                                blurRadius: 8)
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Icon(opt['icon'] as IconData,
                          color: selected ? Colors.white : Colors.grey,
                          size: 36),
                      const SizedBox(height: 8),
                      Text(opt['label'] as String,
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: selected ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SleepScheduleCard extends StatelessWidget {
  final TimeOfDay? bedtime;
  final TimeOfDay? wakeTime;
  final void Function(TimeOfDay?, TimeOfDay?) onChanged;
  const _SleepScheduleCard(
      {required this.bedtime, required this.wakeTime, required this.onChanged});

  Future<void> pickTime(BuildContext context, bool isBedtime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedtime
          ? (bedtime ?? TimeOfDay(hour: 22, minute: 0))
          : (wakeTime ?? TimeOfDay(hour: 7, minute: 0)),
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: Theme.of(context).colorScheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (isBedtime) {
        onChanged(picked, wakeTime);
      } else {
        onChanged(bedtime, picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is your sleep schedule?',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('Bedtime', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => pickTime(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                          bedtime != null ? bedtime!.format(context) : '--:--',
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Wake Time', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => pickTime(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                          wakeTime != null
                              ? wakeTime!.format(context)
                              : '--:--',
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityLevelCard extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  const _ActivityLevelCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      {'label': 'Sedentary', 'icon': Icons.self_improvement},
      {'label': 'Light', 'icon': Icons.directions_walk},
      {'label': 'Moderate', 'icon': Icons.directions_run},
      {'label': 'High', 'icon': Icons.fitness_center},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How active are you?',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
          const SizedBox(height: 32),
          Column(
            children: options.map((opt) {
              final selected = value == opt['label'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => onChanged(opt['label'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color:
                          selected ? theme.colorScheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                          width: 2),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.08),
                                  blurRadius: 8)
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Icon(opt['icon'] as IconData,
                            color: selected ? Colors.white : Colors.grey,
                            size: 32),
                        const SizedBox(width: 16),
                        Text(opt['label'] as String,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: selected ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChipSelectCard extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool optional;
  const _ChipSelectCard(
      {required this.title,
      required this.options,
      required this.selected,
      required this.onChanged,
      this.optional = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((opt) {
              final isSelected = selected.contains(opt);
              return ChoiceChip(
                label: Text(opt,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.primary)),
                selected: isSelected,
                selectedColor: theme.colorScheme.primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (sel) {
                  final newList = List<String>.from(selected);
                  if (sel) {
                    newList.add(opt);
                  } else {
                    newList.remove(opt);
                  }
                  onChanged(newList);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
