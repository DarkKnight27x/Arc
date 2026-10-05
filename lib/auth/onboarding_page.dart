import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingAnswers {
  String? goal;
  String? sex;
  String? age;
  String? heightCm;
  String? weightKg;
  String? level;
  String? days;
  String? diet;
  List<String> allergies = [];
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final answers = OnboardingAnswers();
  final age = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();
  int step = 0;
  bool saving = false;
  String? error;

  static const page = Color(0xFF0E0E10);
  static const card = Color(0xFF17171A);
  static const line = Color(0xFF2A2A2E);
  static const ink = Color(0xFFF5F5F6);
  static const muted = Color(0xFF8B8B93);
  static const on = Color(0xFFECECEE);

  @override
  void dispose() {
    age.dispose();
    height.dispose();
    weight.dispose();
    super.dispose();
  }

  bool get ready {
    switch (step) {
      case 0:
        return answers.goal != null;
      case 1:
        return answers.sex != null;
      case 2:
        return (int.tryParse(age.text) ?? 0) >= 13;
      case 3:
        return height.text.trim().isNotEmpty && weight.text.trim().isNotEmpty;
      case 4:
        return answers.level != null;
      case 5:
        return answers.days != null;
      case 6:
        return answers.diet != null;
      case 7:
        return answers.allergies.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> next() async {
    if (!ready || saving) return;
    if (step == 2) answers.age = age.text.trim();
    if (step == 3) {
      answers.heightCm = height.text.trim();
      answers.weightKg = weight.text.trim();
    }
    if (step < 8) {
      setState(() => step += 1);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => error = 'Sign in again.');
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });
    try {
      await Supabase.instance.client.from('profiles').update({
        'fitness_goal': answers.goal,
        'gender': answers.sex,
        'age': int.tryParse(answers.age ?? ''),
        'height_cm': double.tryParse(answers.heightCm ?? ''),
        'weight_kg': double.tryParse(answers.weightKg ?? ''),
        'experience_level': answers.level,
        'train_days': int.tryParse(answers.days ?? ''),
        'diet_type': answers.diet,
        'allergies': answers.allergies,
        'onboarding_complete': true,
      }).eq('user_id', user.id);
      widget.onComplete?.call();
    } catch (e) {
      setState(() => error = 'Could not save. $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _ArcMark(),
                  const Spacer(),
                  Text('THANE', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.8)),
                ],
              ),
              const SizedBox(height: 14),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: step / 8),
                duration: const Duration(milliseconds: 420),
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 2,
                  backgroundColor: line,
                  color: ink,
                ),
              ),
              const SizedBox(height: 22),
              if (step > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: saving ? null : () => setState(() => step -= 1),
                    child: const Text('Back', style: TextStyle(color: muted)),
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(key: ValueKey(step), child: _body()),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: ready && !saving ? next : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: ready ? on : const Color(0xFF232328),
                    disabledBackgroundColor: const Color(0xFF232328),
                    foregroundColor: const Color(0xFF111111),
                    disabledForegroundColor: const Color(0xFF6E6E76),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(step == 8 ? 'Enter Arc' : 'Continue', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (step) {
      case 0:
        return _choices('GOAL · 01', 'What are you here for?', ['Build muscle', 'Lose fat', 'Stay consistent'], answers.goal, (v) => answers.goal = v);
      case 1:
        return _choices('YOU · 02', 'Sex.', ['Male', 'Female'], answers.sex, (v) => answers.sex = v);
      case 2:
        return _fields('YOU · 03', 'How old are you?', [TextField(controller: age, keyboardType: TextInputType.number, style: const TextStyle(color: ink), decoration: _dec('21'), onChanged: (_) => setState(() {}))]);
      case 3:
        return _fields('BODY · 04', 'Height and weight.', [
          TextField(controller: height, keyboardType: TextInputType.number, style: const TextStyle(color: ink), decoration: _dec('175 cm'), onChanged: (_) => setState(() {})),
          const SizedBox(width: 10),
          TextField(controller: weight, keyboardType: TextInputType.number, style: const TextStyle(color: ink), decoration: _dec('70 kg'), onChanged: (_) => setState(() {})),
        ], row: true);
      case 4:
        return _choices('LEVEL · 05', 'How active are you?', ['Beginner', 'Intermediate', 'Advanced'], answers.level, (v) => answers.level = v);
      case 5:
        return _choices('WEEK · 06', 'Days you can train.', ['3', '4', '5', '6'], answers.days, (v) => answers.days = v, days: true);
      case 6:
        return _choices('PLATE · 07', 'Food preference.', ['Veg', 'Nonveg', 'Vegan', 'Eggetarian'], answers.diet, (v) => answers.diet = v);
      case 7:
        return _multi();
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('READY', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.8)),
            const SizedBox(height: 12),
            Text('Your path is ready.', style: GoogleFonts.instrumentSerif(color: ink, fontSize: 34, height: 1.08)),
            const SizedBox(height: 8),
            const Text('Train, eat, recover.', style: TextStyle(color: muted, fontSize: 16)),
          ],
        );
    }
  }

  Widget _choices(String k, String q, List<String> options, String? selected, ValueChanged<String> onPick, {bool days = false}) {
    final chips = options.map((o) {
      return Padding(
        padding: EdgeInsets.only(right: days ? 8 : 0, bottom: days ? 0 : 10),
        child: _chip(o, selected == o, () => setState(() => onPick(o))),
      );
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(color: muted, fontSize: 11, letterSpacing: 1.8)),
        const SizedBox(height: 12),
        Text(q, style: GoogleFonts.instrumentSerif(color: ink, fontSize: 34, height: 1.08)),
        const SizedBox(height: 22),
        if (days) Row(children: chips.map((c) => Expanded(child: c)).toList()) else Column(children: chips),
      ],
    );
  }

  Widget _multi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PLATE · 08', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.8)),
        const SizedBox(height: 12),
        Text('Any food allergies?', style: GoogleFonts.instrumentSerif(color: ink, fontSize: 34, height: 1.08)),
        const SizedBox(height: 22),
        for (final o in ['Dairy', 'Gluten', 'Nuts', 'Eggs', 'None'])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _chip(o, answers.allergies.contains(o), () {
              setState(() {
                if (o == 'None') {
                  answers.allergies = ['None'];
                } else {
                  answers.allergies.remove('None');
                  answers.allergies.contains(o) ? answers.allergies.remove(o) : answers.allergies.add(o);
                }
              });
            }),
          ),
      ],
    );
  }

  Widget _fields(String k, String q, List<Widget> fields, {bool row = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(color: muted, fontSize: 11, letterSpacing: 1.8)),
        const SizedBox(height: 12),
        Text(q, style: GoogleFonts.instrumentSerif(color: ink, fontSize: 34, height: 1.08)),
        const SizedBox(height: 22),
        if (row) Row(children: fields.map((f) => f is SizedBox ? f : Expanded(child: f)).toList()) else ...fields,
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? on : card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? on : line),
          ),
          child: Text(label, style: TextStyle(color: selected ? const Color(0xFF111111) : ink, fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: muted),
    filled: true,
    fillColor: card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: line)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: ink)),
  );
}

class _ArcMark extends StatelessWidget {
  const _ArcMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(28, 18), painter: _MarkPainter());
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFF5F5F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(2, size.height - 1)
      ..lineTo(2, size.height * .55)
      ..arcToPoint(Offset(size.width - 2, size.height * .55), radius: Radius.circular(size.width / 2), clockwise: true)
      ..lineTo(size.width - 2, size.height - 1);
    canvas.drawPath(path, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .42, size.height * .48, size.width * .46, 4.5), const Radius.circular(1)),
      Paint()..color = const Color(0xFFF5F5F6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}