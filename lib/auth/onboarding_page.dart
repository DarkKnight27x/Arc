import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme_ctrl.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _steps = 5;

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _dobController = TextEditingController();

  int _step = 0;
  bool _saving = false;
  String? _error;

  DateTime? _dateOfBirth;
  String? _gender;
  String? _fitnessGoal;
  String? _experienceLevel;
  String? _workoutLocation;
  int? _sessionDurationMinutes;
  String? _dietType;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  List<String> get _stepTitles => const [
    'Basic info',
    'Body info',
    'Fitness',
    'Training',
    'Nutrition',
  ];

  bool get _canContinue => _validateStep(_step);

  bool _validateStep(int index) {
    switch (index) {
      case 0:
        return _dateOfBirth != null && _gender != null && _gender!.isNotEmpty;
      case 1:
        final height = double.tryParse(_heightController.text.trim());
        final weight = double.tryParse(_weightController.text.trim());
        return height != null && height > 0 && weight != null && weight > 0;
      case 2:
        return _fitnessGoal != null && _experienceLevel != null;
      case 3:
        return _workoutLocation != null && _sessionDurationMinutes != null;
      case 4:
        return _dietType != null && _dietType!.isNotEmpty;
      default:
        return false;
    }
  }

  void _submitStep() {
    if (!_validateStep(_step)) {
      setState(() {
        _error = 'Please complete all required fields before continuing.';
      });
      return;
    }

    setState(() {
      _error = null;
    });

    if (_step < _steps - 1) {
      setState(() {
        _step += 1;
      });
      return;
    }

    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    if (_saving) return;

    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    if (user == null) {
      setState(() {
        _error = 'No authenticated user is available. Please sign in again.';
      });
      return;
    }

    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (height == null || height <= 0 || weight == null || weight <= 0) {
      setState(() {
        _error = 'Please enter valid height and weight.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'date_of_birth': _dateOfBirth?.toIso8601String(),
            'gender': _gender,
            'height_cm': height,
            'weight_kg': weight,
            'fitness_goal': _fitnessGoal,
            'experience_level': _experienceLevel,
            'workout_location': _workoutLocation,
            'session_duration_minutes': _sessionDurationMinutes,
            'diet_type': _dietType,
            'onboarding_complete': true,
          })
          .eq('user_id', user.id);

      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    } on PostgrestException catch (error) {
      setState(() {
        _error = 'Could not save your profile: ${error.message}';
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong while saving your onboarding details. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Select your date of birth',
      barrierColor: Colors.black.withOpacity(0.52),
      builder: (context, child) {
        final c = ArcColors.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF4A555B),
              onPrimary: Colors.white,
              surface: c.surface,
              onSurface: c.ink,
            ),
            dialogBackgroundColor: c.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _dateOfBirth = picked;
      _dobController.text = _formatDate(picked);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildOptionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final c = ArcColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ArcMotion.fast,
        curve: ArcMotion.press,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: selected ? metalPrimary(c) : metalWell(c, radius: 16),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.ctaInk : c.ink,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    final c = ArcColors.of(context);

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: c.ice,
          selectionColor: c.ice.withOpacity(0.28),
          selectionHandleColor: c.ice,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: c.chip,
          hintStyle: TextStyle(color: c.muted),
          labelStyle: TextStyle(color: c.muted),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              letterSpacing: 0.3,
              color: c.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            cursorColor: c.ice,
            style: TextStyle(
              color: c.ink,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: c.chip,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: hint,
              hintStyle: TextStyle(color: c.muted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.ink.withOpacity(0.4)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    final c = ArcColors.of(context);

    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _dobController,
              label: 'Date of birth',
              hint: 'DD/MM/YYYY',
              keyboardType: TextInputType.none,
              readOnly: true,
              onTap: _pickDate,
              validator: (value) {
                if (_dateOfBirth == null) {
                  return 'Select your date of birth';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            Text(
              'Gender',
              style: TextStyle(
                fontSize: 12.5,
                letterSpacing: 0.3,
                color: c.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                'Male',
                'Female',
                'Other',
                'Prefer not to say',
              ].map((option) {
                final selected = _gender == option;
                return _buildOptionChip(
                  label: option,
                  selected: selected,
                  onTap: () => setState(() => _gender = option),
                );
              }).toList(),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _heightController,
                    label: 'Height (cm)',
                    hint: '170',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (value) {
                      final v = double.tryParse(value?.trim() ?? '');
                      if (v == null || v <= 0) return 'Enter your height';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    hint: '72',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (value) {
                      final v = double.tryParse(value?.trim() ?? '');
                      if (v == null || v <= 0) return 'Enter your weight';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fitness goal',
              style: TextStyle(
                fontSize: 12.5,
                letterSpacing: 0.3,
                color: c.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                'Build muscle',
                'Lose fat',
                'Build strength',
                'Improve fitness',
                'Improve mobility',
                'General health',
              ].map((option) {
                final selected = _fitnessGoal == option;
                return _buildOptionChip(
                  label: option,
                  selected: selected,
                  onTap: () => setState(() => _fitnessGoal = option),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text(
              'Experience level',
              style: TextStyle(
                fontSize: 12.5,
                letterSpacing: 0.3,
                color: c.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['Beginner', 'Intermediate', 'Advanced'].map((option) {
                final selected = _experienceLevel == option;
                return _buildOptionChip(
                  label: option,
                  selected: selected,
                  onTap: () => setState(() => _experienceLevel = option),
                );
              }).toList(),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout location',
              style: TextStyle(
                fontSize: 12.5,
                letterSpacing: 0.3,
                color: c.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['Gym', 'Home', 'Outdoors'].map((option) {
                final selected = _workoutLocation == option;
                return _buildOptionChip(
                  label: option,
                  selected: selected,
                  onTap: () => setState(() => _workoutLocation = option),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text(
              'Preferred session duration',
              style: TextStyle(
                fontSize: 12.5,
                letterSpacing: 0.3,
                color: c.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [30, 45, 60, 90].map((option) {
                final selected = _sessionDurationMinutes == option;
                return _buildOptionChip(
                  label: '$option min',
                  selected: selected,
                  onTap: () => setState(() => _sessionDurationMinutes = option),
                );
              }).toList(),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diet type',
              style: TextStyle(
                fontSize: 12.5,
                letterSpacing: 0.3,
                color: c.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                'No preference',
                'Vegetarian',
                'Vegan',
                'Eggetarian',
                'Non-vegetarian',
              ].map((option) {
                final selected = _dietType == option;
                return _buildOptionChip(
                  label: option,
                  selected: selected,
                  onTap: () => setState(() => _dietType = option),
                );
              }).toList(),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const ArcLogo(height: 20),
                      const Spacer(),
                      Text(
                        'SETUP',
                        style: TextStyle(
                          color: c.muted,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Build your ARC profile',
                    style: TextStyle(
                      color: c.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A few details help ARC shape a plan around you.',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: metalPanel(c, glow: true, radius: 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              '${_step + 1} / $_steps',
                              style: TextStyle(
                                color: c.ink,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: (_step + 1) / _steps,
                                  minHeight: 8,
                                  backgroundColor: c.chip,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFF4A555B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: ArcMotion.base,
                          switchInCurve: ArcMotion.enter,
                          switchOutCurve: ArcMotion.enter,
                          transitionBuilder: (child, animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(20, 0),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: ArcMotion.enter)).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey<int>(_step),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _stepTitles[_step],
                                  style: TextStyle(
                                    color: c.ink,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildStepContent(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.red.withOpacity(0.08),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: _saving
                                  ? null
                                  : () => setState(() {
                                        _error = null;
                                        _step -= 1;
                                      }),
                              child: Container(
                                height: 52,
                                decoration: metalWell(c, radius: 999),
                                alignment: Alignment.center,
                                child: Text(
                                  'Back',
                                  style: TextStyle(
                                    color: c.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: _step > 0 ? 8 : 0),
                          child: GestureDetector(
                            onTap: _saving || !_canContinue ? null : _submitStep,
                            child: AnimatedContainer(
                              duration: ArcMotion.fast,
                              height: 52,
                              decoration: _saving || !_canContinue
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: c.chip,
                                      border: Border.all(color: c.line),
                                    )
                                  : metalPrimary(c),
                              alignment: Alignment.center,
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      _step == _steps - 1 ? 'Finish Setup' : 'Continue',
                                      style: TextStyle(
                                        color: _saving || !_canContinue ? c.muted : c.ctaInk,
                                        fontWeight: FontWeight.w700,
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
            ),
          ),
        ),
      ),
    );
  }
}
