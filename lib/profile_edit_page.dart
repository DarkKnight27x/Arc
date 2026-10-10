import 'dart:async';

import 'package:flutter/material.dart';

import 'data/profile_service.dart';
import 'data/profile_validation.dart';
import 'theme_ctrl.dart';
import 'widgets/profile_surface.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.profile,
    required this.service,
  });
  final ProfileRow profile;
  final ProfileService service;
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _controllers = <String, TextEditingController>{};
  late ProfileRow _original;
  late Map<String, dynamic> _values;
  StreamSubscription? _auth;
  bool _saving = false;
  bool _sessionChanged = false;
  bool _syncFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _original = widget.profile;
    _values = Map.of(_original.editableFields);
    _values['allergies'] = List<String>.of(_original.allergies);
    for (final field in ['display_name', 'height_cm', 'weight_kg', 'age']) {
      final value = _values[field];
      _controllers[field] = TextEditingController(
        text: value is num ? profileNumber(value) : value?.toString() ?? '',
      );
    }
    _sessionChanged = widget.service.currentUserId != _original.userId;
    _auth = widget.service.authChanges.listen((_) {
      if (mounted && widget.service.currentUserId != _original.userId) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _sessionChanged = true);
      }
    });
  }

  @override
  void dispose() {
    _auth?.cancel();
    _scroll.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _sessionChanged) return;
    if (!_form.currentState!.validate()) {
      setState(
        () =>
            _error = 'Check the highlighted name or measurement fields above.',
      );
      _scroll.animateTo(0, duration: ArcMotion.base, curve: ArcMotion.enter);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final edited = Map<String, dynamic>.of(_values);
    edited['display_name'] = _controllers['display_name']!.text.trim();
    for (final field in ['height_cm', 'weight_kg', 'age']) {
      final number = double.tryParse(_controllers[field]!.text.trim());
      edited[field] = field == 'age' ? number?.toInt() : number;
    }
    final patch = ProfileValidation.changedFields(
      _original.editableFields,
      edited,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.service.updateCurrentUser(
        original: _original,
        patch: patch,
      );
      if (!mounted ||
          _sessionChanged ||
          widget.service.currentUserId != _original.userId) {
        return;
      }
      _original = result.profile;
      if (result.metadataSynced) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _syncFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile saved. Sign-in name sync failed; retry to finish.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted && !_sessionChanged) {
        setState(
          () => _error = 'Could not confirm the save. Your entries are still here. Retry, or go back and refresh your profile.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: themeCtrl,
    builder: (context, _, _) {
      final c = ArcColors.of(context);
      return Theme(
        data: profileTheme(context, c),
        child: PopScope(
          canPop: !_saving,
          child: Scaffold(
            backgroundColor: c.page,
            appBar: AppBar(
              backgroundColor: c.page,
              foregroundColor: c.ink,
              title: Text('Edit profile', style: TextStyle(color: c.ink)),
              surfaceTintColor: Colors.transparent,
            ),
            body: _sessionChanged
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Your account changed. Return to You to load your current profile.',
                        style: TextStyle(color: c.ink),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Form(
                    key: _form,
                    child: AbsorbPointer(
                      absorbing: _saving,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Make it yours.',
                              style: arcDisplay(c, size: 30),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Your details help ARC fit your routine. Measurements and preferences are optional.',
                              style: TextStyle(color: c.muted, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            if (_syncFailed)
                              ProfileSection(
                                title: 'Name synchronization pending',
                                children: [
                                  Text(
                                    'Your profile was saved. Your sign-in name could not be synchronized. Retry to finish; ARC already uses your saved profile name.',
                                    style: TextStyle(color: c.ink, height: 1.5),
                                  ),
                                ],
                              ),
                            ProfileSection(
                              title: 'Personal details',
                              children: [
                                _input('display_name', 'Display name', c),
                                const SizedBox(height: 18),
                                _input('age', 'Age (years)', c),
                                const SizedBox(height: 18),
                                _input('height_cm', 'Height (cm)', c),
                                const SizedBox(height: 18),
                                _input('weight_kg', 'Weight (kg)', c),
                              ],
                            ),
                            ProfileSection(
                              title: 'Your training',
                              children: [
                                _choices(
                                  'fitness_goal',
                                  'Fitness goal',
                                  ProfileValidation.goals,
                                  c,
                                ),
                                _choices(
                                  'experience_level',
                                  'Experience',
                                  ProfileValidation.levels,
                                  c,
                                ),
                                _choices(
                                  'train_days',
                                  'Days per week',
                                  List.generate(7, (i) => i + 1),
                                  c,
                                ),
                                _choices(
                                  'workout_location',
                                  'Workout setting',
                                  ProfileValidation.locations,
                                  c,
                                ),
                              ],
                            ),
                            ProfileSection(
                              title: 'Nutrition preferences',
                              children: [
                                _choices(
                                  'diet_type',
                                  'Diet preference',
                                  ProfileValidation.diets,
                                  c,
                                ),
                                Text(
                                  'Allergies',
                                  style: TextStyle(
                                    color: c.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Select all that apply. Choose None only if you have no allergies to report.',
                                  style: TextStyle(color: c.muted),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    for (final allergy in {
                                      ...ProfileValidation.allergies,
                                      ...(_values['allergies'] as List<String>),
                                    })
                                      _chip(
                                        allergy,
                                        (_values['allergies'] as List<String>)
                                            .contains(allergy),
                                        () {
                                          final list = List<String>.of(
                                            _values['allergies']
                                                as List<String>,
                                          );
                                          if (list.contains(allergy)) {
                                            list.remove(allergy);
                                          } else if (allergy == 'None') {
                                            list.clear();
                                            list.add(allergy);
                                          } else {
                                            list.remove('None');
                                            list.add(allergy);
                                          }
                                          setState(
                                            () => _values['allergies'] = list,
                                          );
                                        },
                                        c,
                                        multiple: true,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: c.ink, height: 1.5),
                                ),
                              ),
                            FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: c.muted,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(
                                _saving
                                    ? 'Saving…'
                                    : _syncFailed
                                    ? 'Retry save & name sync'
                                    : 'Save changes',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Text(
                                _syncFailed ? 'Back to profile' : 'Cancel',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      );
    },
  );

  Widget _input(String field, String label, ArcColors c) => TextFormField(
    controller: _controllers[field],
    style: TextStyle(color: c.ink),
    keyboardType: field == 'display_name'
        ? TextInputType.name
        : TextInputType.numberWithOptions(decimal: field != 'age'),
    textCapitalization: field == 'display_name'
        ? TextCapitalization.words
        : TextCapitalization.none,
    textInputAction: TextInputAction.next,
    maxLength: field == 'display_name' ? 80 : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: field == 'display_name' ? 'Your name' : 'Not set',
    ),
    validator: (value) {
      if (field == 'display_name') return ProfileValidation.name(value);
      // Unchanged legacy values do not prevent unrelated edits.
      if (value == profileNumber(_original.editableFields[field] as num?)) {
        return null;
      }
      return ProfileValidation.numeric(value, field);
    },
  );

  Widget _choices(
    String field,
    String label,
    List<Object> choices,
    ArcColors c,
  ) {
    final current = _values[field];
    final options = <Object>{...choices, ?current};
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: c.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _chip(
                'Not set',
                current == null,
                () => setState(() => _values[field] = null),
                c,
              ),
              for (final option in options)
                _chip(
                  field == 'diet_type'
                      ? dietLabel(option.toString())
                      : option.toString(),
                  current == option,
                  () => setState(() => _values[field] = option),
                  c,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String label,
    bool selected,
    VoidCallback onTap,
    ArcColors c, {
    bool multiple = false,
  }) => multiple
      ? FilterChip(
          label: Text(
            label,
            style: TextStyle(color: selected ? c.page : c.ink),
          ),
          selected: selected,
          onSelected: (_) => onTap(),
          materialTapTargetSize: MaterialTapTargetSize.padded,
        )
      : ChoiceChip(
          label: Text(
            label,
            style: TextStyle(color: selected ? c.page : c.ink),
          ),
          selected: selected,
          onSelected: (_) => onTap(),
          materialTapTargetSize: MaterialTapTargetSize.padded,
        );
}
