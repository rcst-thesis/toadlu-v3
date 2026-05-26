import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/streak/helpers/streak_helper.dart';

enum _ProfileTab { about, streak }

/// Profile dashboard screen.
///
/// It shows the saved onboarding info, editable username, streak summary, and
/// per-unit learning progress from AppData.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  _ProfileTab _selectedTab = _ProfileTab.about;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final username = appState.displayUsername;

    return Scaffold(
      backgroundColor: TudloColors.green,
      body: Stack(
        children: [
          const Positioned.fill(child: _ProfileBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 126),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Edit profile',
                      // Edit button:
                      // Opens a dialog where the user can change their
                      // username.
                      onPressed: () => _showEditProfileDialog(context),
                      icon: const Icon(Icons.edit_rounded),
                      color: TudloColors.green,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .78),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MainProfileCard(
                    username: username,
                    ageRange: appState.ageRange,
                    joinedOn: appState.joinedOn,
                    selectedTab: _selectedTab,
                    // Profile tabs switch the content below the main profile
                    // card between About details and weekly streak details.
                    onTabSelected: (tab) => setState(() => _selectedTab = tab),
                  ),
                  const SizedBox(height: 18),
                  if (_selectedTab == _ProfileTab.about)
                    const _AboutCard()
                  else
                    const _WeeklyStreakCard(),
                  const SizedBox(height: 18),
                  const _StreakSummaryCard(),
                  const SizedBox(height: 28),
                  _ProgressSection(username: username),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    // The edit button currently supports username changes. It updates AppState,
    // so all widgets reading displayUsername rebuild automatically.
    final appState = AppStateScope.of(context);
    final controller = TextEditingController(text: appState.username);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Edit username'),
          content: TextField(
            controller: controller,
            autofocus: true,
            cursorColor: TudloColors.green,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Type your name',
              filled: true,
              fillColor: TudloColors.paper,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: TudloColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: TudloColors.green,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              // Cancel closes the edit dialog without saving changes.
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Save updates AppState, which refreshes the username across
                // Profile, Home Map greeting, and other screens.
                final value = controller.text.trim();
                if (value.isEmpty) return;
                appState.setUsername(value);
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }
}

class _MainProfileCard extends StatelessWidget {
  final String username;
  final String ageRange;
  final DateTime joinedOn;
  final _ProfileTab selectedTab;
  final ValueChanged<_ProfileTab> onTabSelected;

  const _MainProfileCard({
    required this.username,
    required this.ageRange,
    required this.joinedOn,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    // The profile card keeps permanent user info at the top and switches the
    // lower tab content between ABOUT and Streak.
    return Container(
      decoration: _softCardDecoration(radius: 34),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F9EA),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(child: TudloMascot(size: 112)),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: TudloColors.ink,
                          fontSize: 31,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Age: ${ageRange.isEmpty ? 'Not set' : ageRange}',
                        style: GoogleFonts.nunito(
                          color: TudloColors.forest,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Joined on ${_formatDate(joinedOn)}',
                        style: GoogleFonts.nunito(
                          color: TudloColors.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFFF7FAEC),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _ProfileTabButton(
                  label: 'ABOUT',
                  selected: selectedTab == _ProfileTab.about,
                  onTap: () => onTabSelected(_ProfileTab.about),
                ),
                const SizedBox(width: 10),
                _ProfileTabButton(
                  label: 'Streak',
                  selected: selectedTab == _ProfileTab.streak,
                  onTap: () => onTabSelected(_ProfileTab.streak),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? TudloColors.softGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: selected ? TudloColors.forest : TudloColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _softCardDecoration(radius: 24),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.map_rounded,
            label: 'Levels completed',
            value: '${AppData.completedLevels.length}',
          ),
        ],
      ),
    );
  }
}

class _WeeklyStreakCard extends StatelessWidget {
  const _WeeklyStreakCard();

  @override
  Widget build(BuildContext context) {
    final completedDays = StreakHelper.current().completedDaysThisWeek;
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _softCardDecoration(radius: 24),
      child: Row(
        children: List.generate(7, (index) {
          final completed = index < completedDays;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: completed ? TudloColors.green : TudloColors.paper,
                    shape: BoxShape.circle,
                    border: Border.all(color: TudloColors.line),
                  ),
                  child: Icon(
                    completed ? Icons.check_rounded : Icons.circle_outlined,
                    color: completed ? Colors.white : TudloColors.muted,
                    size: completed ? 22 : 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[index],
                  style: GoogleFonts.nunito(
                    color: completed ? TudloColors.forest : TudloColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: TudloColors.softGreen,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: TudloColors.forest),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: TudloColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakSummaryCard extends StatelessWidget {
  const _StreakSummaryCard();

  @override
  Widget build(BuildContext context) {
    final streak = StreakHelper.current().days;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: _softCardDecoration(radius: 26),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDE6B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF4E7D24),
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak day streak',
                  style: GoogleFonts.nunito(
                    color: TudloColors.forest,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Longest learning streak ever!',
                  style: GoogleFonts.nunito(
                    color: TudloColors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatefulWidget {
  final String username;

  const _ProgressSection({required this.username});

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    // The progress card starts with three units and expands to all six when
    // the user taps "View all".
    final units = List.generate(6, (index) => index + 1);
    final visibleUnits = expanded ? units : units.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            "${widget.username}'s Progress",
            style: GoogleFonts.nunito(
              color: TudloColors.cloud,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 203, 253, 159),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                    bottom: Radius.circular(24),
                  ),
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 8,
                    childAspectRatio: .78,
                    children: visibleUnits.map((unit) {
                      return _UnitProgressTile(unit: unit);
                    }).toList(),
                  ),
                ),
              ),
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                // View all button:
                // Expands the progress card to show every unit instead of the
                // first three only.
                onTap: () => setState(() => expanded = !expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View all',
                        style: GoogleFonts.nunito(
                          color: TudloColors.forest,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: expanded ? .5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: TudloColors.forest,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitProgressTile extends StatelessWidget {
  final int unit;

  const _UnitProgressTile({required this.unit});

  @override
  Widget build(BuildContext context) {
    // Completed levels are counted by global level ID, grouped into visible
    // units of five levels each.
    final start = (unit - 1) * 5 + 1;
    final end = start + 4;
    final count = AppData.completedLevels
        .where((level) => level >= start && level <= end)
        .length;

    return Column(
      children: [
        Text(
          'Unit $unit',
          style: GoogleFonts.nunito(
            color: TudloColors.ink,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6EC),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: 58,
                  height: .95,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Level',
                style: GoogleFonts.nunito(
                  color: TudloColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ProfileBackgroundPainter());
  }
}

class _ProfileBackgroundPainter extends CustomPainter {
  const _ProfileBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = TudloColors.green);

    final lower = Path()
      ..moveTo(0, size.height * .52)
      ..lineTo(size.width, size.height * .46)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      lower,
      Paint()..color = TudloColors.green.withValues(alpha: .82),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration _softCardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: TudloColors.line),
    boxShadow: [
      BoxShadow(
        color: TudloColors.forest.withValues(alpha: .08),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

String _formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
