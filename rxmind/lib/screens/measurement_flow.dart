import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MeasurementFlow extends StatelessWidget {
  const MeasurementFlow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const WeightScreen();
  }
}

class WeightScreen extends StatefulWidget {
  const WeightScreen();
  @override
  State<WeightScreen> createState() => WeightScreenState();
}

class WeightScreenState extends State<WeightScreen> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weight')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your weight (kg):',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 70',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Save weight, go to next
                  context.go('/measurement/height');
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeightScreen extends StatefulWidget {
  const HeightScreen();
  @override
  State<HeightScreen> createState() => HeightScreenState();
}

class HeightScreenState extends State<HeightScreen> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Height')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your height (cm):',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 170',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/measurement/blood_pressure');
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen();
  @override
  State<BloodPressureScreen> createState() => BloodPressureScreenState();
}

class BloodPressureScreenState extends State<BloodPressureScreen> {
  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blood Pressure')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your blood pressure (mmHg):',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Systolic',
                        hintText: 'e.g. 120',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _diaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Diastolic',
                        hintText: 'e.g. 80',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/measurement/heart_rate');
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen();
  @override
  State<HeartRateScreen> createState() => HeartRateScreenState();
}

class HeartRateScreenState extends State<HeartRateScreen> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heart Rate')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your heart rate (bpm):',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 72',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/measurement/temperature');
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen();
  @override
  State<TemperatureScreen> createState() => TemperatureScreenState();
}

class TemperatureScreenState extends State<TemperatureScreen> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body Temperature')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your body temperature (°C):',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 36.6',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/measurement/spo2');
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpO2Screen extends StatefulWidget {
  const SpO2Screen();
  @override
  State<SpO2Screen> createState() => SpO2ScreenState();
}

class SpO2ScreenState extends State<SpO2Screen> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blood Oxygen (SpO₂)')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your SpO₂ (%):',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 98',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/measurement/glucose');
                },
                child: const Text('Next'),
              ),
              TextButton(
                onPressed: () {
                  context.go('/measurement/glucose');
                },
                child: const Text('Skip (Optional)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlucoseScreen extends StatefulWidget {
  const GlucoseScreen();
  @override
  State<GlucoseScreen> createState() => GlucoseScreenState();
}

class GlucoseScreenState extends State<GlucoseScreen> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blood Glucose')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your blood glucose (mg/dL):',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 100',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/measurement/optional');
                },
                child: const Text('Next'),
              ),
              TextButton(
                onPressed: () {
                  context.go('/measurement/optional');
                },
                child: const Text('Skip (Optional)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionalScreen extends StatelessWidget {
  const OptionalScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Other Measurements (Optional)')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'You can add more measurements (e.g., cholesterol, HbA1c, ECG, etc.) if you have them, or skip.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Go to summary or home
                  context.go('/main');
                },
                child: const Text('Finish'),
              ),
              TextButton(
                onPressed: () {
                  context.go('/main');
                },
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
