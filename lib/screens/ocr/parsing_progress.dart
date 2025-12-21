import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxmind_app/screens/ai/gemini_api_service.dart';

class ParsingProgressScreen extends StatefulWidget {
  const ParsingProgressScreen({super.key});

  @override
  State<ParsingProgressScreen> createState() => _ParsingProgressScreenState();
}

class _ParsingProgressScreenState extends State<ParsingProgressScreen> {
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseText();
  }

  Future<void> _parseText() async {
    final reviewedText = ModalRoute.of(context)?.settings.arguments as String?;
    if (reviewedText == null) {
      setState(() => _error = 'No text provided.');
      return;
    }
    try {
      final GeminiApiService geminiService = GeminiApiService();

      final String prompt = '''
You are a medical data extraction specialist. Your job is to parse hospital discharge summaries into structured JSON format with EXTREME PRECISION.

═══════════════════════════════════════════════════════════════════════════════
⚠️  CRITICAL OUTPUT REQUIREMENT ⚠️
═══════════════════════════════════════════════════════════════════════════════

Respond ONLY with a valid JSON object. NO explanations, NO preambles, NO markdown formatting, NO code blocks.
Your entire response must be parseable JSON starting with { and ending with }

CRITICAL: Use SIMPLE, EVERYDAY LANGUAGE that anyone can understand!
Replace ALL medical jargon and complex terms with plain English.

LANGUAGE SIMPLIFICATION RULES:
• "ambulation" → "walking" or "moving around"
• "cessation" → "stopping"
• "submerge" → "get wet" or "put underwater"
• "orthopedics" → "bone doctor"
• "cardiology" → "heart doctor"
• "incision" → "cut" or "surgical wound"
• "dressing" → "bandage"
• "elevate" → "raise" or "prop up"
• "monitor" → "watch" or "check"
• "administer" → "take" or "give"
• "abstain" → "avoid" or "don't do"
• "hydration" → "drinking water"
• "nourishment" → "eating"
• "mobilize" → "move" or "get up"
• "void" → "use the bathroom" or "pee"

Always use the simplest word possible! Write like you're explaining to a 12-year-old.

═══════════════════════════════════════════════════════════════════════════════
📐 REQUIRED JSON STRUCTURE
═══════════════════════════════════════════════════════════════════════════════

{
  "medications": [
    {
      "name": "medication name (use simple terms)",
      "dose": "dosage amount",
      "frequency": "how often to take (in plain English)"
    }
  ],
  "follow_ups": [
    {
      "name": "doctor/department name (use simple terms like 'heart doctor' not 'cardiologist')",
      "date": "YYYY-MM-DD HH:MM",
      "hasSpecificDate": true
    }
  ],
  "instructions": [
    {
      "name": "general instruction text (in simple, everyday language)"
    }
  ],
  "tasks": [
    {
      "title": "specific actionable task (in simple language)",
      "description": "clear explanation in everyday words",
      "dueDate": "YYYY-MM-DD",
      "dueTime": "HH:MM",
      "isRecurring": true/false,
      "recurringPattern": "hourly/daily/weekly/monthly",
      "recurringInterval": number,
      "startDate": "YYYY-MM-DD",
      "type": "task",
      "hasSpecificDate": true/false
    }
  ],
  "warnings": [
    {
      "text": "warning or restriction (in simple, clear language)"
    }
  ],
  "contacts": [
    {
      "name": "doctor/clinic/hospital name (use simple terms)",
      "phone": "phone number with area code",
      "address": "full address if mentioned",
      "notes": "specialty in plain English (e.g., 'Heart Doctor', 'Bone Doctor', 'Emergency')"
    }
  ]
}

═══════════════════════════════════════════════════════════════════════════════
🎯 THE GOLDEN RULE: TASK vs WARNING vs INSTRUCTION
═══════════════════════════════════════════════════════════════════════════════

A statement goes into TASKS if and ONLY if ALL THREE conditions are met:
1. ✅ It requires a SPECIFIC ACTION by the patient (not just awareness)
2. ✅ It has TIMING information (frequency, schedule, or deadline)
3. ✅ It can be CHECKED OFF as complete at a specific point in time

A statement goes into WARNINGS if it is ANY of these:
1. ❌ A RESTRICTION (don't do something)
2. ❌ A PROHIBITION (no doing something)
3. ❌ An AVOIDANCE instruction (stay away from, avoid)
4. ❌ A MONITORING instruction (watch for, look for, check for)
5. ❌ A CONDITIONAL warning (if X happens, do Y)
6. ❌ An ONGOING STATE to maintain (keep dry, stay elevated, use crutches)

═══════════════════════════════════════════════════════════════════════════════
⛔ WARNINGS - THESE ALWAYS GO IN WARNINGS ARRAY (NEVER IN TASKS!)
═══════════════════════════════════════════════════════════════════════════════

🚫 RESTRICTIONS & PROHIBITIONS (always warnings, never tasks):
• "Do not submerge" → WARNING: "Don't get your wound wet underwater"
• "No driving until cleared by orthopedics" → WARNING: "Don't drive until your bone doctor says it's okay"
• "Avoid heavy lifting" → WARNING: "Don't lift anything heavy"
• "No swimming for 4 weeks" → WARNING: "Don't go swimming for 4 weeks"
• "Don't bear weight on left leg" → WARNING: "Don't put weight on your left leg"
• "Refrain from strenuous activity" → WARNING: "Avoid hard exercise or physical work"
• "No alcohol while taking medication" → WARNING: "Don't drink alcohol while taking your medicine"
• "Abstain from smoking" → WARNING: "Don't smoke"

🚫 ONGOING EQUIPMENT/MOBILITY REQUIREMENTS (always warnings, never tasks):
• "Use crutches for all ambulation" → WARNING: "Use crutches whenever you walk"
• "Wear compression stockings during the day" → WARNING: "Wear tight support socks during daytime"
• "Keep leg elevated when resting" → WARNING: "Keep your leg raised when you're resting"
• "Non-weight bearing on right ankle" → WARNING: "Don't put any weight on your right ankle"
• "Use walker for stability" → WARNING: "Use a walker to help you balance"

🚫 MONITORING & WATCHING (always warnings, never tasks):
• "Watch for signs of infection" → WARNING: "Watch for signs of infection like redness, warmth, or pus"
• "Monitor for fever above 101°F" → WARNING: "Check if you get a fever over 101°F"
• "Look for increased swelling" → WARNING: "Watch for more swelling"
• "Be aware of chest pain" → WARNING: "Pay attention if you get chest pain"

🚫 ONGOING HYGIENE/CARE (always warnings, never tasks):
• "Keep wound clean and dry" → WARNING: "Keep your wound clean and dry"
• "Maintain good hand hygiene" → WARNING: "Wash your hands regularly"
• "Protect surgical site from sun" → WARNING: "Keep your surgery area out of the sun"

🚫 CONDITIONAL/EMERGENCY INSTRUCTIONS (always warnings, never tasks):
• "Call doctor if symptoms worsen" → WARNING: "Call your doctor if you feel worse"
• "Seek immediate care for severe pain" → WARNING: "Go to the hospital right away if you have bad pain"
• "If you experience dizziness, stop medication" → WARNING: "Stop taking your medicine if you feel dizzy"

🚫 DIETARY/LIFESTYLE RESTRICTIONS (always warnings, never tasks):
• "Follow a low-sodium diet" → WARNING: "Eat foods with less salt"
• "Reduce caffeine intake" → WARNING: "Drink less coffee and soda with caffeine"
• "Avoid spicy foods" → WARNING: "Don't eat spicy food"

═══════════════════════════════════════════════════════════════════════════════
✅ TASKS - THESE GO IN TASKS ARRAY (Must have specific action + timing)
═══════════════════════════════════════════════════════════════════════════════

✅ SCHEDULED ACTIONS WITH TIMING (these are tasks):
• "Take Acetaminophen 500mg every 6 hours" → TASK: "Take Tylenol 500mg every 6 hours"
• "Change wound dressing every 48 hours" → TASK: "Change your bandage every 2 days"
• "Apply antibiotic ointment twice daily" → TASK: "Put antibiotic cream on your wound twice a day"
• "Check your temperature every morning" → TASK: "Take your temperature every morning"
• "Take blood pressure reading daily at 8am" → TASK: "Check your blood pressure every day at 8am"
• "Perform ankle exercises 3 times per day" → TASK: "Do ankle exercises 3 times a day"
• "Ice the area for 20 minutes every 4 hours" → TASK: "Put ice on the area for 20 minutes every 4 hours"

✅ TIME-LIMITED ACTIONS (these are tasks):
• "Remove sutures in 10 days" → TASK: "Remove stitches in 10 days"
• "Start physical therapy on June 15th" → TASK: "Start physical therapy on June 15th"

═══════════════════════════════════════════════════════════════════════════════
📝 INSTRUCTIONS - GENERAL GUIDANCE (No specific timing)
═══════════════════════════════════════════════════════════════════════════════

ℹ️ GENERAL GUIDANCE WITHOUT TIMING (these are instructions):
• "Gradually increase activity as tolerated" → INSTRUCTION: "Slowly do more activities when you feel ready"
• "You may shower after 48 hours" → INSTRUCTION: "You can shower after 2 days"
• "Return to work when cleared by physician" → INSTRUCTION: "Go back to work when your doctor says it's okay"
• "Resume normal diet" → INSTRUCTION: "Eat your regular foods again"

═══════════════════════════════════════════════════════════════════════════════
🚨 KEY DISTINCTIONS (READ CAREFULLY!)
═══════════════════════════════════════════════════════════════════════════════

EXAMPLE 1: "Elevate leg above heart level when resting"
→ WARNING (ongoing state, not scheduled action)
→ Use simple words: "Keep your leg raised above your heart when resting"

EXAMPLE 2: "Elevate leg for 30 minutes every 3 hours"
→ TASK (specific timing, scheduled action)
→ Use simple words: "Raise your leg for 30 minutes every 3 hours"

EXAMPLE 3: "Use crutches for ambulation"
→ WARNING (ongoing equipment requirement)
→ Use simple words: "Use crutches when you walk"

EXAMPLE 4: "Practice walking with crutches for 10 minutes twice daily"
→ TASK (specific timing, scheduled practice)
→ Use simple words: "Practice walking with crutches for 10 minutes, 2 times a day"

EXAMPLE 5: "Do not submerge wound"
→ WARNING (prohibition)
→ Use simple words: "Don't get your wound wet underwater"

EXAMPLE 6: "Pat wound dry after showering"
→ TASK if scheduled (e.g., "after each shower")
→ Use simple words: "Gently dry your wound after you shower"

EXAMPLE 7: "No driving until cleared by orthopedics"
→ WARNING (prohibition with condition)
→ Use simple words: "Don't drive until your bone doctor says it's okay"

═══════════════════════════════════════════════════════════════════════════════
📞 MEDICAL CONTACTS EXTRACTION (VERY IMPORTANT)
═══════════════════════════════════════════════════════════════════════════════

ALWAYS extract medical contacts from the discharge text, including:

✅ EXTRACT AS CONTACTS (use simple specialty names):
• Doctor names with phone numbers → Use simple titles: "Dr. Smith (Heart Doctor)"
• Clinic/Office phone numbers
• Hospital contact information
• Department phone numbers → Use simple names: "Heart Doctor Department: 555-0123"
• Emergency contact numbers for medical services
• Specialist contact information → Simplify: "Bone Doctor", "Heart Doctor", "Skin Doctor"
• Pharmacy phone numbers
• Follow-up appointment scheduling numbers

SIMPLIFY SPECIALTY NAMES IN CONTACTS:
• "Cardiology" → "Heart Doctor"
• "Orthopedics" → "Bone Doctor"
• "Dermatology" → "Skin Doctor"
• "Gastroenterology" → "Stomach Doctor"
• "Pulmonology" → "Lung Doctor"
• "Nephrology" → "Kidney Doctor"
• "Neurology" → "Brain Doctor"
• "Ophthalmology" → "Eye Doctor"
• "Otolaryngology" / "ENT" → "Ear, Nose, and Throat Doctor"
• "Podiatry" → "Foot Doctor"
• "Urology" → "Bladder and Kidney Doctor"

EXAMPLES:
• "Dr. Smith (Cardiology): 555-0123" →
  {"name": "Dr. Smith", "phone": "555-0123", "notes": "Heart Doctor"}

• "For emergencies, call 911 or hospital at (555) 789-0000" →
  {"name": "Hospital Emergency", "phone": "(555) 789-0000", "notes": "Emergency"}

• "Follow-up with Orthopedics at 555-1234" →
  {"name": "Bone Doctor Department", "phone": "555-1234", "notes": "Follow-up"}

═══════════════════════════════════════════════════════════════════════════════
📅 FOLLOW-UP APPOINTMENTS - EXACT DATE EXTRACTION (CRITICAL!)
═══════════════════════════════════════════════════════════════════════════════

// ...existing date extraction rules...

═══════════════════════════════════════════════════════════════════════════════
⏰ TIMING RULES FOR TASKS (Medications & Scheduled Actions)
═══════════════════════════════════════════════════════════════════════════════

// ...existing timing rules...

═══════════════════════════════════════════════════════════════════════════════
✅ FINAL CHECKLIST BEFORE CATEGORIZING
═══════════════════════════════════════════════════════════════════════════════

Before adding to TASKS array, verify ALL are true:
□ Patient must perform a specific action (not just be aware)
□ Action has clear timing (frequency, schedule, or deadline)
□ Action can be marked "done" at a specific time
□ Action is NOT "don't do X" or "avoid X" (those are warnings)
□ Action is NOT "use X for walking" or ongoing equipment (those are warnings)
□ Action is NOT monitoring/watching (those are warnings)
□ Action is NOT maintaining a continuous state (those are warnings)
□ Action is NOT conditional ("if X happens, do Y") (those are warnings)

Before adding to WARNINGS array, check if it is:
□ A restriction or prohibition (don't do, no doing, avoid)
□ An ongoing equipment requirement (use crutches, wear brace)
□ A monitoring instruction (watch for, check for)
□ A continuous state to maintain (keep dry, stay elevated)
□ A conditional instruction (if X, then Y)

REMEMBER: Use SIMPLE, EVERYDAY WORDS in all your output! Write like you're explaining to a friend or family member.

═══════════════════════════════════════════════════════════════════════════════

Discharge Text:
$reviewedText

Response (JSON only, with simple everyday language):''';

      final response = await geminiService.sendMessage(prompt);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/parsedSummary',
          arguments: {'parsedJson': response});
    } catch (e) {
      setState(() => _error = 'Parsing failed: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          child: Semantics(
            label: _error == null ? 'Parsing in progress' : 'Parsing error',
            liveRegion: true,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'RxMind logo',
                    child: SvgPicture.asset(
                      'assets/illus/logo.svg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: 'Progress indicator',
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor:
                          AlwaysStoppedAnimation(theme.colorScheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error ?? 'Parsing Your Discharge Text...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few seconds. Please wait...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
