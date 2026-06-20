import 'package:flutter/material.dart';
import 'package:tudloapp/core/models/learner_profile.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/features/navigation/app_shell.dart';
import 'package:tudloapp/features/onboarding/screens/username_screen.dart';

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final compact = height < 680 || width < 380;
            final logoWidth = (width * .74).clamp(210.0, 360.0);
            final headWidth = (width * 1.02).clamp(300.0, 560.0);
            final cardSize = (width * (compact ? .30 : .33)).clamp(
              104.0,
              138.0,
            );

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: compact ? 22 : height * .08,
                  child: Image.asset(
                    'assets/images/onbaording/Tudlo.png',
                    width: logoWidth,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: compact ? height * .22 : height * .27,
                  left: 20,
                  right: 20,
                  bottom: compact ? height * .28 : height * .24,
                  child: _ProfileGrid(
                    profiles: appState.profiles,
                    cardSize: cardSize,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UsernameScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: compact ? -18 : -8,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/onbaording/head.png',
                      width: headWidth,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileGrid extends StatelessWidget {
  final List<LearnerProfile> profiles;
  final double cardSize;
  final VoidCallback onTap;

  const _ProfileGrid({
    required this.profiles,
    required this.cardSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleProfiles = profiles.take(3).toList();
    return Center(
      child: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 22,
          runSpacing: 16,
          children: [
            for (final profile in visibleProfiles)
              _ProfileCard(profile: profile, size: cardSize),
            _CreateAccountButton(size: cardSize, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _CreateAccountButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _CreateAccountButton({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TudloColors.forest, width: 3),
                ),
                child: const Icon(
                  Icons.add_box_rounded,
                  color: Color(0xFF55E65E),
                  size: 64,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add Profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final LearnerProfile profile;
  final double size;

  const _ProfileCard({required this.profile, required this.size});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await AppStateScope.of(context).selectProfile(profile.id);
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 0)),
          );
        },
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TudloColors.forest, width: 3),
                ),
                child: _ProfileSelectionAvatar(asset: profile.avatarAsset),
              ),
              const SizedBox(height: 8),
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSelectionAvatar extends StatelessWidget {
  final String asset;

  const _ProfileSelectionAvatar({required this.asset});

  @override
  Widget build(BuildContext context) {
    if (asset.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.add_rounded, color: TudloColors.green, size: 64),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(asset, fit: BoxFit.cover),
    );
  }
}
