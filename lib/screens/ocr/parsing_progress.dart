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

═══════════════════════════════════════════════════════════════════════════════
📐 REQUIRED JSON STRUCTURE
═══════════════════════════════════════════════════════════════════════════════

{
  "medications": [
    {
      "name": "medication name",
      "dose": "dosage amount",
      "frequency": "how often to take"
    }
  ],
  "follow_ups": [
    {
      "name": "doctor/department name",
      "date": "YYYY-MM-DD HH:MM",
      "hasSpecificDate": true
    }
  ],
  "instructions": [
    {
      "name": "general instruction text"
    }
  ],
  "tasks": [
    {
      "title": "specific actionable task",
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
      "text": "warning or restriction"
    }
  ],
  "contacts": [
    {
      "name": "doctor/clinic/hospital name",
      "phone": "phone number with area code",
      "address": "full address if mentioned",
      "notes": "specialty, department, or context (e.g., 'Primary Care', 'Surgeon', 'Emergency')"
    }
  ]
}

═══════════════════════════════════════════════════════════════════════════════
📞 MEDICAL CONTACTS EXTRACTION (VERY IMPORTANT)
═══════════════════════════════════════════════════════════════════════════════

ALWAYS extract medical contacts from the discharge text, including:

✅ EXTRACT AS CONTACTS:
• Doctor names with phone numbers
• Clinic/Office phone numbers
• Hospital contact information
• Department phone numbers (e.g., "Cardiology: 555-0123")
• Emergency contact numbers for medical services
• Specialist contact information
• Pharmacy phone numbers
• Follow-up appointment scheduling numbers

FORMAT PHONE NUMBERS:
• Keep original format (e.g., "(555) 123-4567" or "555-123-4567" or "+1-555-123-4567")
• Include area codes and country codes when present
• If multiple numbers for same contact, create separate entries

CONTACT NOTES FIELD:
• Add specialty: "Cardiologist", "Primary Care Physician", "Orthopedic Surgeon"
• Add department: "Emergency Department", "Radiology", "Lab Services"
• Add context: "24/7 Nurse Line", "Appointment Scheduling", "Main Hospital"

EXAMPLES:
• "Dr. Smith (Cardiology): 555-0123" →
  {"name": "Dr. Smith", "phone": "555-0123", "notes": "Cardiology"}

• "For emergencies, call 911 or hospital at (555) 789-0000" →
  {"name": "Hospital Emergency", "phone": "(555) 789-0000", "notes": "Emergency"}

• "Follow-up with Orthopedics at 555-1234" →
  {"name": "Orthopedics Department", "phone": "555-1234", "notes": "Follow-up"}

❌ DO NOT extract:
• Personal emergency contacts (family/friends)
• Non-medical phone numbers
• Patient's own phone number

═══════════════════════════════════════════════════════════════════════════════
📅 FOLLOW-UP APPOINTMENTS - EXACT DATE EXTRACTION (CRITICAL!)
═══════════════════════════════════════════════════════════════════════════════

🔴 EXTREMELY IMPORTANT: Extract EXACT dates and times from follow-up appointments!

When the discharge paper says things like:
• "Follow up with Dr. Smith on November 15, 2025 at 2:00 PM"
• "Cardiology appointment scheduled for 11/20/2025 at 10:30 AM"
• "Return to clinic in 2 weeks (approximately November 1, 2025)"
• "Suture removal on Oct 25th at 9 AM"

You MUST extract the EXACT date and time:
{
  "name": "Dr. Smith",
  "date": "2025-11-15 14:00",
  "hasSpecificDate": true
}

DATE FORMAT RULES:
• Always use "YYYY-MM-DD HH:MM" format (24-hour time)
• If only date is given (no time), default to "09:00"
• If relative date like "in 2 weeks", calculate from today (2025-10-18)
• Parse dates like "Nov 15", "11/15/2025", "November 15th" correctly
• Common date formats: "MM/DD/YYYY", "Month DD, YYYY", "DD-MM-YYYY"

EXAMPLES OF CORRECT EXTRACTION:
Input: "Follow-up with cardiology on 11/20/2025 at 2:30 PM"
Output: {"name": "Cardiology", "date": "2025-11-20 14:30", "hasSpecificDate": true}

Input: "Return to surgeon Dr. Johnson on December 1st"
Output: {"name": "Dr. Johnson", "date": "2025-12-01 09:00", "hasSpecificDate": true}

Input: "Physical therapy starts on Oct 25, 2025 at 8 AM"
Output: {"name": "Physical Therapy", "date": "2025-10-25 08:00", "hasSpecificDate": true}

Input: "Follow-up in 3 weeks" (today is Oct 18, 2025)
Output: {"name": "Follow-up", "date": "2025-11-08 09:00", "hasSpecificDate": true}

If NO date is mentioned (very rare), use hasSpecificDate: false and omit date field.

═══════════════════════════════════════════════════════════════════════════════
🎯 THE GOLDEN RULE: TASK vs WARNING vs INSTRUCTION
═══════════════════════════════════════════════════════════════════════════════

A statement goes into TASKS if and ONLY if ALL THREE conditions are met:
1. ✅ It requires a SPECIFIC ACTION by the patient (not just awareness)
2. ✅ It has TIMING information (frequency, schedule, or deadline)
3. ✅ It can be CHECKED OFF as complete at a specific point in time

If ANY condition is not met → NOT a task!

═══════════════════════════════════════════════════════════════════════════════
📋 TASKS - COMPREHENSIVE EXAMPLES (What GOES in tasks array)
═══════════════════════════════════════════════════════════════════════════════

✅ DEFINITELY TASKS:
• "Take Acetaminophen 500mg every 6 hours" → TASK (specific action + timing + checkable)
• "Change wound dressing every 48 hours" → TASK (specific action + timing + checkable)
• "Apply antibiotic ointment twice daily" → TASK (specific action + timing + checkable)
• "Check your temperature every morning" → TASK (specific action + timing + checkable)
• "Take blood pressure reading daily at 8am" → TASK (specific action + timing + checkable)
• "Perform ankle exercises 3 times per day" → TASK (specific action + timing + checkable)
• "Elevate leg for 30 minutes every 4 hours" → TASK (specific action + timing + checkable)
• "Remove sutures in 10 days" → TASK (specific action + deadline + checkable)
• "Start physical therapy on June 15th" → TASK (specific action + date + checkable)

✅ BORDERLINE CASES:
• "Change dressing when wet" → NO - timing is conditional, not scheduled
• "Ice the area for 20 minutes 3x daily" → YES - has frequency and duration
• "Rest with leg elevated" → NO - continuous state, not time-based action

═══════════════════════════════════════════════════════════════════════════════
⛔ WARNINGS - COMPREHENSIVE EXAMPLES (What GOES in warnings array)
═══════════════════════════════════════════════════════════════════════════════

❌ DEFINITELY WARNINGS (NOT tasks):
• "Watch for signs of infection" → WARNING (monitoring, not action)
• "Monitor for fever above 101°F" → WARNING (watching, not doing)
• "Look for increased redness or swelling" → WARNING (observation, not action)
• "Be aware of chest pain or shortness of breath" → WARNING (awareness, not action)
• "Keep the surgical site clean and dry" → WARNING (general hygiene, not scheduled action)
• "Avoid alcohol while taking medication" → WARNING (restriction, not action)
• "Do not drive for 2 weeks" → WARNING (prohibition, not action)
• "No heavy lifting for 6 weeks" → WARNING (restriction, not action)
• "Avoid strenuous activity" → WARNING (avoidance, not action)
• "Rest as needed" → WARNING (general advice, not scheduled)
• "Stay hydrated" → WARNING (general wellness, not specific action)
• "Call doctor if symptoms worsen" → WARNING (conditional instruction)
• "Seek immediate care for severe pain" → WARNING (emergency instruction)
• "Contact surgeon with any concerns" → WARNING (conditional contact)
• "If you experience dizziness, stop medication" → WARNING (conditional instruction)

❌ PASSIVE HYGIENE/MAINTENANCE (NOT tasks):
• "Keep wound clean" → WARNING (continuous state, not time-based)
• "Maintain good hand hygiene" → WARNING (general practice)
• "Ensure dressing stays dry" → WARNING (continuous vigilance)
• "Protect surgical site from sun" → WARNING (ongoing protection)

❌ LIFESTYLE/DIET RESTRICTIONS (NOT tasks):
• "Follow a low-sodium diet" → WARNING (dietary restriction)
• "Eat plenty of fruits and vegetables" → WARNING (general nutrition)
• "Reduce caffeine intake" → WARNING (dietary modification)
• "Maintain a healthy weight" → WARNING (general goal)

❌ MOBILITY/ACTIVITY RESTRICTIONS (NOT tasks):
• "Non-weight bearing on left leg" → WARNING (restriction)
• "Use crutches for ambulation" → WARNING (ongoing requirement)
• "Avoid stairs when possible" → WARNING (limitation)
• "No swimming for 4 weeks" → WARNING (prohibition)

═══════════════════════════════════════════════════════════════════════════════
📝 INSTRUCTIONS - COMPREHENSIVE EXAMPLES (What GOES in instructions array)
═══════════════════════════════════════════════════════════════════════════════

ℹ️ INSTRUCTIONS are GENERAL GUIDANCE without specific timing:
• "Gradually increase activity as tolerated" → INSTRUCTION
• "You may shower after 48 hours" → INSTRUCTION
• "Return to work when cleared by physician" → INSTRUCTION
• "Resume normal diet" → INSTRUCTION
• "Wear compression stockings during the day" → INSTRUCTION (continuous, not scheduled)
• "Use crutches until follow-up appointment" → INSTRUCTION
• "Take medications with food" → INSTRUCTION (general guidance for meds)

═══════════════════════════════════════════════════════════════════════════════
🚫 NEVER PUT THESE IN TASKS ARRAY
═══════════════════════════════════════════════════════════════════════════════

NEVER tasks (always warnings or instructions):
❌ Anything starting with "Watch for", "Monitor", "Look for", "Be aware"
❌ Anything starting with "Avoid", "Do not", "No", "Refrain from"
❌ Anything starting with "Keep", "Maintain", "Ensure", "Protect"
❌ Anything starting with "Call doctor if", "Seek care if", "Contact if"
❌ Statements about diagnosis (e.g., "Patient has diabetes")
❌ Statements about prognosis (e.g., "Recovery expected in 6 weeks")
❌ Continuous states (e.g., "Rest", "Stay elevated", "Remain non-weight bearing")
❌ Conditional actions (e.g., "If pain worsens, increase dose")
❌ General lifestyle advice without timing

═══════════════════════════════════════════════════════════════════════════════
⏰ TIMING RULES FOR TASKS (Medications & Scheduled Actions)
═══════════════════════════════════════════════════════════════════════════════

Current context: Today is 2025-10-18, current time assumed 12:00 PM

🔴 CRITICAL: PRESERVE EXACT DATES FROM DISCHARGE PAPERS
If a task or follow-up has a SPECIFIC DATE mentioned (like "Follow up on Nov 15" or "Remove sutures on October 25"),
you MUST use that EXACT date in the dueDate field. DO NOT change it to tomorrow or any other date!

FOR TASKS WITH SPECIFIC DATES (e.g., "Follow-up appointment on November 15, 2025 at 2:00 PM"):
{
  "title": "Follow-up appointment",
  "dueDate": "2025-11-15",
  "dueTime": "14:00",
  "isRecurring": false,
  "recurringPattern": null,
  "recurringInterval": null,
  "startDate": "2025-11-15",
  "type": "task",
  "hasSpecificDate": true
}

FOR TASKS WITH SPECIFIC DATES BUT NO TIME (e.g., "Remove sutures in 10 days" where today is Oct 18):
{
  "title": "Remove sutures",
  "dueDate": "2025-10-28",
  "dueTime": "09:00",
  "isRecurring": false,
  "recurringPattern": null,
  "recurringInterval": null,
  "startDate": "2025-10-28",
  "type": "task",
  "hasSpecificDate": true
}

FOR MEDICATIONS WITH "EVERY X HOURS" (no specific date, starts today):
{
  "title": "Take [medication name] [dose]",
  "dueDate": "2025-10-18",
  "dueTime": "12:05",
  "isRecurring": true,
  "recurringPattern": "hourly",
  "recurringInterval": X,
  "startDate": "2025-10-18",
  "type": "task",
  "hasSpecificDate": false
}

FREQUENCY TRANSLATIONS:
• "Every 6 hours" → recurringPattern: "hourly", recurringInterval: 6
• "Every 8 hours" → recurringPattern: "hourly", recurringInterval: 8
• "Twice daily" / "BID" → recurringPattern: "hourly", recurringInterval: 12
• "Three times daily" / "TID" → recurringPattern: "hourly", recurringInterval: 8
• "Four times daily" / "QID" → recurringPattern: "hourly", recurringInterval: 6
• "Once daily" / "Daily" → recurringPattern: "daily", recurringInterval: 1
• "Every other day" → recurringPattern: "daily", recurringInterval: 2
• "Twice weekly" → recurringPattern: "weekly", recurringInterval: 1
• "Weekly" → recurringPattern: "weekly", recurringInterval: 1
• "Monthly" → recurringPattern: "monthly", recurringInterval: 1

FOR NEW RECURRING TASKS (without specific dates): SET dueTime to "12:05" (prevents showing as immediately overdue)
FOR TASKS WITH SPECIFIC DATES: USE THE EXACT DATE AND TIME FROM THE DISCHARGE PAPER

═══════════════════════════════════════════════════════════════════════════════
� DECISION FLOWCHART FOR CATEGORIZATION
═══════════════════════════════════════════════════════════════════════════════

For each sentence in the discharge summary, ask:

1. Is it diagnosis/medical history information?
   YES → IGNORE (don't include anywhere)
   NO → Continue to #2

2. Does it tell patient to actively DO something specific?
   NO → Go to #3
   YES → Go to #2a

   2a. Does it have frequency/timing/schedule?
       NO → Put in INSTRUCTIONS
       YES → Put in TASKS (this is a task!)

3. Is it a prohibition/restriction/thing to avoid?
   YES → Put in WARNINGS
   NO → Go to #4

4. Is it telling patient to watch for/monitor something?
   YES → Put in WARNINGS
   NO → Go to #5

5. Is it general health advice or continuous guidance?
   YES → Put in INSTRUCTIONS
   NO → Go to #6

6. Is it emergency contact info or conditional instruction?
   YES → Put in WARNINGS
   NO → Put in INSTRUCTIONS (default for uncategorized guidance)

═══════════════════════════════════════════════════════════════════════════════
� DETAILED CLASSIFICATION EXAMPLES
═══════════════════════════════════════════════════════════════════════════════

Example 1: "Keep the incision site clean and dry"
→ No specific timing, continuous state → WARNING

Example 2: "Change dressing every 2 days"
→ Specific action + timing → TASK

Example 3: "Watch for signs of infection such as redness, warmth, or pus"
→ Monitoring instruction → WARNING

Example 4: "Take Naproxen 250mg twice daily with food"
→ Specific action + timing → TASK (medication)

Example 5: "Avoid driving until cleared by doctor"
→ Prohibition → WARNING

Example 6: "You may resume light activities as tolerated"
→ General permission without timing → INSTRUCTION

Example 7: "Apply ice pack for 20 minutes every 4 hours"
→ Specific action + timing → TASK

Example 8: "Call surgeon if fever exceeds 101°F"
→ Conditional emergency instruction → WARNING

Example 9: "Attend follow-up appointment on June 15 at 2pm"
→ Specific action + date/time → Put in follow_ups array (NOT tasks)

Example 10: "Non-weight bearing on left ankle"
→ Ongoing restriction → WARNING

Example 11: "Elevate leg above heart level when resting"
→ Conditional action (when resting), not scheduled → INSTRUCTION

Example 12: "Elevate leg for 30 minutes every 3 hours"
→ Specific action + timing → TASK

═══════════════════════════════════════════════════════════════════════════════
✅ FINAL CHECKLIST BEFORE CATEGORIZING AS TASK
═══════════════════════════════════════════════════════════════════════════════

Before adding something to tasks array, verify ALL are true:
□ Patient must perform a specific action (not just be aware)
□ Action has clear timing (frequency, schedule, or deadline)
□ Action can be marked "done" at a specific time
□ Action is NOT monitoring/watching
□ Action is NOT avoiding/abstaining
□ Action is NOT maintaining a continuous state
□ Action is NOT conditional ("if X happens, do Y")
□ Action is NOT a general lifestyle recommendation

If ANY checkbox is unchecked → DO NOT put in tasks!

═══════════════════════════════════════════════════════════════════════════════

Discharge Text:
$reviewedText

Response (JSON only):''';

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
