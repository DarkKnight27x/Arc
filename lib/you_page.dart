import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/profile_service.dart';
import 'profile_edit_page.dart';
import 'theme_ctrl.dart';
import 'widgets/profile_surface.dart';

class YouPage extends StatefulWidget {
  const YouPage({super.key, this.isActive = true, this.service});
  final bool isActive;
  final ProfileService? service;
  @override
  State<YouPage> createState() => _YouPageState();
}

class _YouPageState extends State<YouPage> with WidgetsBindingObserver {
  late final ProfileService _service;
  StreamSubscription? _auth;
  ProfileRow? _profile;
  String? _userId;
  String? _error;
  bool _loading = true;
  bool _signingOut = false;
  int _request = 0;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ProfileService(Supabase.instance.client);
    _userId = _service.currentUserId;
    WidgetsBinding.instance.addObserver(this);
    ProfileService.changes.addListener(_invalidate);
    _auth = _service.authChanges.listen((_) {
      if (!mounted || _userId == _service.currentUserId) return;
      _request++;
      setState(() {
        _userId = _service.currentUserId;
        _profile = null;
        _error = null;
        _loading = true;
        _tab = 0;
      });
      if (widget.isActive) _load();
    });
    if (widget.isActive) _load();
  }

  @override
  void didUpdateWidget(covariant YouPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) _load();
  }

  void _invalidate() {
    if (widget.isActive) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    final userId = _service.currentUserId;
    setState(() {
      if (_profile?.userId != userId) _profile = null;
      _userId = userId;
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _service.fetchCurrentUser().timeout(
        const Duration(seconds: 20),
      );
      if (!mounted || request != _request || userId != _service.currentUserId) {
        return;
      }
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request || userId != _service.currentUserId) {
        return;
      }
      setState(() {
        _loading = false;
        _error =
            'Could not refresh your profile. Check your connection and retry.';
      });
    }
  }

  Future<void> _edit() async {
    final profile = _profile;
    if (profile == null || profile.userId != _service.currentUserId) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileEditPage(profile: profile, service: _service),
      ),
    );
    if (!mounted || profile.userId != _service.currentUserId) return;
    await _load();
    if (saved == true && mounted && profile.userId == _service.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved and name synchronized.')),
      );
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not sign out. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  void dispose() {
    _request++;
    WidgetsBinding.instance.removeObserver(this);
    ProfileService.changes.removeListener(_invalidate);
    _auth?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: themeCtrl,
    builder: (context, _, _) {
      final c = ArcColors.of(context);
      final profile = _profile?.userId == _service.currentUserId
          ? _profile
          : null;
      return Theme(
        data: profileTheme(context, c),
        child: ColoredBox(
          color: c.page,
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _load,
              color: c.ink,
              backgroundColor: c.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
                children: [
                  Row(
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
                        child: const ArcLogo(),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: toggleArcTheme,
                        icon: Icon(
                          isArcDark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          size: 18,
                        ),
                        label: Text(isArcDark ? 'Dark' : 'Light'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'YOU',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 11,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (profile != null) ...[
                    Text(
                      profile.displayName?.trim().isNotEmpty == true
                          ? profile.displayName!.trim()
                          : 'Your profile',
                      style: arcDisplay(c, size: 36),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      [profile.fitnessGoal, profile.experienceLevel]
                          .whereType<String>()
                          .where((s) => s.trim().isNotEmpty)
                          .join(' · '),
                      style: TextStyle(color: c.muted, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _edit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit profile'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_loading)
                      LinearProgressIndicator(
                        color: c.muted,
                        backgroundColor: c.line,
                        minHeight: 2,
                      ),
                  ] else if (_loading)
                    ProfileSection(
                      title: 'Your personal hub',
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.muted,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Loading your profile…',
                                style: TextStyle(color: c.ink),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  if (_error != null)
                    ProfileSection(
                      title: 'Refresh needed',
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(color: c.ink, height: 1.5),
                        ),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  if (!_loading && _error == null && profile == null)
                    ProfileSection(
                      title: 'Profile unavailable',
                      children: [
                        Text(
                          'Your saved profile could not be found. Retry to check again.',
                          style: TextStyle(color: c.ink, height: 1.5),
                        ),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (final entry in ['Brief', 'Body'].asMap().entries)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Semantics(
                              selected: _tab == entry.key,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _tab == entry.key
                                      ? c.chip
                                      : Colors.transparent,
                                ),
                                onPressed: () =>
                                    setState(() => _tab = entry.key),
                                child: Text(entry.value),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    key: ValueKey(_service.currentUserId),
                    duration: ArcMotion.base,
                    child: _tab == 1
                        ? ProfileSection(
                            key: const ValueKey('body'),
                            title: 'Body visualization',
                            children: [
                              Icon(
                                Icons.accessibility_new_rounded,
                                color: c.muted,
                                size: 48,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'A clearer view of your progress, coming later.',
                                style: TextStyle(
                                  color: c.ink,
                                  fontSize: 19,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your saved height and weight live in Brief. Body composition and measurements will appear here when supported.',
                                style: TextStyle(color: c.muted, height: 1.5),
                              ),
                            ],
                          )
                        : profile == null
                        ? const SizedBox.shrink()
                        : _brief(profile, c),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _signingOut ? null : _signOut,
                    child: Text(_signingOut ? 'Signing out…' : 'Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _brief(ProfileRow p, ArcColors c) => Column(
    key: const ValueKey('brief'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ProfileSection(
        title: 'Personal metrics',
        children: [
          _row(
            'Height',
            p.heightCm == null ? 'Not set' : '${profileNumber(p.heightCm)} cm',
            c,
          ),
          _row(
            'Weight',
            p.weightKg == null ? 'Not set' : '${profileNumber(p.weightKg)} kg',
            c,
          ),
          _row(
            'Age',
            p.ageAt(DateTime.now()) == null
                ? 'Not set'
                : '${p.ageAt(DateTime.now())} years',
            c,
          ),
        ],
      ),
      ProfileSection(
        title: 'Training rhythm',
        children: [
          _row('Goal', profileLabel(p.fitnessGoal), c),
          _row('Experience', profileLabel(p.experienceLevel), c),
          _row('Setting', profileLabel(p.workoutLocation), c),
          _row(
            'Frequency',
            p.trainDays == null ? 'Not set' : '${p.trainDays} days / week',
            c,
          ),
        ],
      ),
      ProfileSection(
        title: 'Nutrition preferences',
        children: [
          _row('Diet', dietLabel(p.dietType), c),
          _row(
            'Allergies',
            p.allergies.isEmpty
                ? 'Not set'
                : p.allergies.length == 1 && p.allergies.first == 'None'
                ? 'None reported'
                : p.allergies.join(', '),
            c,
          ),
        ],
      ),
    ],
  );

  Widget _row(String label, String value, ArcColors c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: c.ink,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}
