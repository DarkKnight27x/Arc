import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final themeCtrl = ValueNotifier<ThemeMode>(ThemeMode.dark);

void toggleArcTheme() {
  themeCtrl.value =
  themeCtrl.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

TextStyle arcDisplay(ArcColors c, {double size = 36, bool italic = false}) {
  return GoogleFonts.spaceGrotesk(
    fontSize: size,
    height: 1.05,
    fontWeight: FontWeight.w500,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: c.ink,
  );
}
bool get isArcDark => themeCtrl.value == ThemeMode.dark;

class ArcColors {
  const ArcColors._({
    required this.page,
    required this.shell,
    required this.surface,
    required this.raised,
    required this.chip,
    required this.line,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.cta,
    required this.ctaInk,
    required this.ice,
    required this.brand,
    required this.ok,
  });

  final Color page;
  final Color shell;
  final Color surface;
  final Color raised;
  final Color chip;
  final Color line;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color cta;
  final Color ctaInk;
  final Color ice;
  final Color brand;
  final Color ok;

  static const dark = ArcColors._(
    page: Color(0xFF121317),
    shell: Color(0xFF0B0C0F),
    surface: Color(0xFF1C1E24),
    raised: Color(0xFF24262D),
    chip: Color(0xFF16181D),
    line: Color(0x66C5CCD6),
    ink: Color(0xFFE8EEF4),
    muted: Color(0xFF8B939E),
    faint: Color(0xFF5C636C),
    cta: Color(0xFF141518),
    ctaInk: Color(0xFFF3F6F8),
    ice: Color(0xFFB7C0CA),
    brand: Color(0xFF5B8DEF),
    ok: Color(0xFF3FAE7F),
  );

  static const cream = ArcColors._(
    page: Color(0xFFE7E0D4),
    shell: Color(0xFFD4CBBB),
    surface: Color(0xFFF4EFE6),
    raised: Color(0xFFFAF6EE),
    chip: Color(0xFFD9D0C0),
    line: Color(0xB3B7A98F),
    ink: Color(0xFF1A1814),
    muted: Color(0xFF6F675C),
    faint: Color(0xFF9A9184),
    cta: Color(0xFF141518),
    ctaInk: Color(0xFFF3F6F8),
    ice: Color(0xFF3A5A8A),
    brand: Color(0xFF3B82F6),
    ok: Color(0xFF2F8F64),
  );

  static ArcColors of(BuildContext context) {
    return themeCtrl.value == ThemeMode.dark ? ArcColors.dark : ArcColors.cream;
  }
}

// ── Motion tokens ──────────────────────────────────────────────────────────
// A shared vocabulary of durations / curves so every page moves the same way.
class ArcMotion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const enter = Curves.easeOutCubic;
  static const press = Curves.easeOutQuint;
  static const spring = Curves.easeOutBack;
}

// ── Surfaces ────────────────────────────────────────────────────────────────
// Hard, uniform 1px borders read as "wireframe". Real hardware reads as depth:
// a soft cast shadow below, a hairline of light catching the top edge only,
// and a gradient body. That's what these decorations build instead of a
// Border.all() on every card.

BoxDecoration metalPanel(ArcColors c, {bool glow = false, double radius = 22}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c.raised, c.surface],
    ),
    border: Border.all(color: c.line, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(glow ? 0.5 : 0.34),
        blurRadius: glow ? 30 : 20,
        offset: const Offset(0, 10),
        spreadRadius: -4,
      ),
    ],
  );
}

BoxDecoration metalWell(ArcColors c, {double radius = 18}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(c.chip, Colors.black, 0.12)!,
        c.chip,
      ],
    ),
    boxShadow: [
      // Inset-look: a faint dark ring instead of a drawn border.
      BoxShadow(
        color: Colors.black.withOpacity(0.30),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
    border: Border.all(color: c.ink.withOpacity(isArcDark ? 0.06 : 0.20), width: 1),
  );
}

BoxDecoration metalPrimary(ArcColors c) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(999),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF4A555B),
        Color(0xFF252B2F),
        Color(0xFF3A4449),
      ],
      stops: [0.0, 0.35, 1.25],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.45),
        blurRadius: 18,
        offset: const Offset(0, 8),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.06),
        blurRadius: 0,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: const Color(0xFF8FA7B2).withOpacity(0.22),
        blurRadius: 12,
        spreadRadius: 0,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: const Color(0xFF6F858F).withOpacity(0.12),
        blurRadius: 30,
        spreadRadius: 2,
      ),
    ],

    border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
  );
}

// ── Motion primitives ───────────────────────────────────────────────────────

/// Wrap any tappable surface to get a premium, physical press response:
/// a quick scale-down + shadow compression on press, spring back on release.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.965,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: ArcMotion.fast,
        curve: ArcMotion.press,
        child: AnimatedOpacity(
          opacity: _down ? 0.88 : 1.0,
          duration: ArcMotion.fast,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Staggered entrance: fades and rises into place. Give each item in a list
/// an increasing [index] and the page will animate in like it's loading real
/// data, not just appearing.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delayStep = const Duration(milliseconds: 45),
    this.dy = 14,
  });

  final Widget child;
  final int index;
  final Duration delayStep;
  final double dy;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: ArcMotion.slow);
    _fade = CurvedAnimation(parent: _ctrl, curve: ArcMotion.enter);
    _slide = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_fade);
    _ctrl.value = 1;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: FractionalTranslation(
          translation: _slide.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
class ArcLogo extends StatelessWidget {
  const ArcLogo({super.key, this.height = 28});
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return Image.asset(
      themeCtrl.value == ThemeMode.dark
          ? 'assets/images/logo_white.png'
          : 'assets/images/logo.png',
      height: height,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Text(
        'ARC',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: c.ink,
        ),
      ),
    );
  }
}

class MetalBtn extends StatefulWidget {
  const MetalBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.ghost = false,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool ghost;

  @override
  State<MetalBtn> createState() => _MetalBtnState();
}

class _MetalBtnState extends State<MetalBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.978 : 1.0,
        duration: ArcMotion.fast,
        curve: ArcMotion.press,
        child: AnimatedContainer(
          duration: ArcMotion.fast,
          height: 52,
          width: double.infinity,
          decoration: widget.ghost ? metalWell(c) : metalPrimary(c),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: widget.ghost ? c.ink : c.ctaInk),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: widget.ghost ? c.ink : c.ctaInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ThemeData arcDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: GoogleFonts.spaceGroteskTextTheme(),
    primaryTextTheme: GoogleFonts.spaceGroteskTextTheme(),
    scaffoldBackgroundColor: ArcColors.dark.page,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _ArcFadeUpTransition(),
        TargetPlatform.iOS: _ArcFadeUpTransition(),
      },
    ),
  );
}

ThemeData arcCreamTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: GoogleFonts.spaceGroteskTextTheme(),
    primaryTextTheme: GoogleFonts.spaceGroteskTextTheme(),
    scaffoldBackgroundColor: ArcColors.cream.page,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _ArcFadeUpTransition(),
        TargetPlatform.iOS: _ArcFadeUpTransition(),
      },
    ),
  );
}

/// Subtle fade + rise page transition used app-wide instead of the default
/// Material slide, so pushed routes (Coach, etc.) feel premium and calm.
class _ArcFadeUpTransition extends PageTransitionsBuilder {
  const _ArcFadeUpTransition();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final curved = CurvedAnimation(parent: animation, curve: ArcMotion.enter);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}