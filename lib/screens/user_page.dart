import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_data.dart';
import '../app_state.dart';
import '../forest_art.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final username = appState.username.isEmpty ? 'nicole' : appState.username;

    return Scaffold(
      backgroundColor: const Color(0xFF4EAA6D),
      body: Stack(
        children: [
          const Positioned.fill(child: _ProfileBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 126),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopActions(),
                  const SizedBox(height: 38),
                  _ProfileHero(username: username),
                  const SizedBox(height: 36),
                  _OverviewCard(
                    ageRange: appState.ageRange,
                    knowledgeLevel: appState.knowledgeLevel,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _GlassIconButton(icon: Icons.favorite_rounded),
        SizedBox(width: 14),
        _GlassIconButton(icon: Icons.settings_rounded),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;

  const _GlassIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String username;

  const _ProfileHero({required this.username});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(bottom: 0, child: _MascotShadow()),
              TudloMascot(size: 178),
              Positioned(left: 30, top: 56, child: _FloatDot(size: 7)),
              Positioned(left: 48, top: 69, child: _FloatDot(size: 6)),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 35,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Guest mode',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ],
              ),
              Text(
                'Log in first!',
                style: GoogleFonts.nunito(
                  color: Colors.white.withValues(alpha: .88),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String ageRange;
  final int knowledgeLevel;

  const _OverviewCard({required this.ageRange, required this.knowledgeLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .20),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OVERVIEW',
            style: GoogleFonts.nunito(
              color: Colors.white.withValues(alpha: .86),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.local_fire_department_rounded,
                  label: '${AppData.streakDays} days',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricTile(
                  icon: Icons.bolt_rounded,
                  label: '${AppData.energyPoints} XP',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.cake_rounded,
                  label: ageRange.isEmpty ? 'Age not set' : ageRange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricTile(
                  icon: Icons.school_rounded,
                  label: 'Level $knowledgeLevel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .26),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _ProfileBackgroundPainter()),
    );
  }
}

class _ProfileBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xFF4EAA6D);
    canvas.drawRect(Offset.zero & size, base);

    final shapes = [
      _Shape(
        Offset(size.width * .10, size.height * .10),
        size.width * .48,
        Colors.white.withValues(alpha: .05),
      ),
      _Shape(
        Offset(size.width * .86, size.height * .05),
        size.width * .54,
        Colors.white.withValues(alpha: .08),
      ),
      _Shape(
        Offset(size.width * .02, size.height * .34),
        size.width * .32,
        const Color(0xFF3F9860).withValues(alpha: .12),
      ),
      _Shape(
        Offset(size.width * .75, size.height * .34),
        size.width * .42,
        Colors.white.withValues(alpha: .06),
      ),
    ];

    for (final shape in shapes) {
      canvas.drawCircle(
        shape.center,
        shape.radius,
        Paint()..color = shape.color,
      );
    }

    final wave = Path()
      ..moveTo(0, size.height * .22)
      ..quadraticBezierTo(
        size.width * .34,
        size.height * .17,
        size.width * .58,
        size.height * .27,
      )
      ..quadraticBezierTo(
        size.width * .82,
        size.height * .37,
        size.width,
        size.height * .28,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(
      wave,
      Paint()..color = const Color(0xFF3F9860).withValues(alpha: .36),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Shape {
  final Offset center;
  final double radius;
  final Color color;

  const _Shape(this.center, this.radius, this.color);
}

class _MascotShadow extends StatelessWidget {
  const _MascotShadow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _FloatDot extends StatelessWidget {
  final double size;

  const _FloatDot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE0FFAA),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.white.withValues(alpha: .40), blurRadius: 8),
        ],
      ),
    );
  }
}
