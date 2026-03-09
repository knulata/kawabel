import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/models/student.dart';
import '../../core/models/parent_data.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/kawabel_theme.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../chat/chat_screen.dart';
import '../dictation/dictation_screen.dart';
import '../test_prep/test_prep_screen.dart';
import '../parent/parent_dashboard_screen.dart';
import '../progress/progress_screen.dart';
import '../leaderboard/leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _assignments = [];
  bool _loadingAssignments = true;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
    _registerStudent();
  }

  Future<void> _registerStudent() async {
    final student = context.read<StudentProvider>().student!;
    await ApiService.registerStudent(name: student.name, grade: student.grade);
  }

  Future<void> _loadAssignments() async {
    if (!_loadingAssignments) {
      setState(() => _loadingAssignments = true);
    }
    final student = context.read<StudentProvider>().student!;
    final assignments = await ApiService.getAssignments(grade: student.grade);
    if (mounted) {
      setState(() {
        _assignments = assignments;
        _loadingAssignments = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  /// Wraps [child] in a fade animation only on the first build.
  Widget _onceAnimation({
    required Widget child,
    required Widget Function({required Widget child}) animationBuilder,
  }) {
    if (_hasAnimated) return child;
    return animationBuilder(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>().student!;
    final parentData = context.watch<ParentDataProvider>();
    final isWide = Responsive.isTabletOrLarger(context);
    final padding = Responsive.pagePadding(context);
    final actionColumns = Responsive.actionColumns(context);
    final actionAspectRatio = Responsive.actionAspectRatio(context);
    final gridColumns = Responsive.gridColumns(context);

    final body = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              Expanded(
                child: _onceAnimation(
                  animationBuilder: ({required child}) =>
                      FadeInLeft(child: child),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}!',
                        style: TextStyle(
                          fontSize: isWide ? 16 : 14,
                          color: KColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.name,
                        style: TextStyle(
                          fontSize: isWide ? 28 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _onceAnimation(
                animationBuilder: ({required child}) =>
                    FadeInRight(child: child),
                child: Row(
                  children: [
                    // Stars
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: KColors.surfaceOrange,
                        borderRadius: KRadius.xl,
                      ),
                      child: Row(
                        children: [
                          const Text(
                              '\u2B50', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '${student.stars}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: KColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Leaderboard button
                    IconButton(
                      icon: const Icon(Icons.leaderboard_rounded),
                      color: KColors.orange,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen(),
                        ),
                      ),
                      tooltip: 'Papan Peringkat',
                    ),
                    // Progress button
                    IconButton(
                      icon: const Icon(Icons.bar_chart_rounded),
                      color: KColors.green,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProgressScreen(),
                        ),
                      ),
                      tooltip: 'Lihat Progress',
                    ),
                    // Profile menu
                    PopupMenuButton(
                      icon: CircleAvatar(
                        backgroundColor: KColors.green,
                        child: Text(
                          student.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Text(
                            '${student.grade} | Level ${student.level}',
                          ),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.bar_chart, size: 18),
                              SizedBox(width: 8),
                              Text('Progressku'),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProgressScreen(),
                              ),
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.leaderboard, size: 18),
                              SizedBox(width: 8),
                              Text('Peringkat'),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LeaderboardScreen(),
                              ),
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.logout, size: 18),
                              SizedBox(width: 8),
                              Text('Keluar'),
                            ],
                          ),
                          onTap: () =>
                              context.read<StudentProvider>().logout(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KSpace.lg),

          // Kawi greeting card
          _onceAnimation(
            animationBuilder: ({required child}) =>
                FadeInUp(delay: const Duration(milliseconds: 200), child: child),
            child: Container(
              padding: const EdgeInsets.all(KSpace.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                ),
                borderRadius: KRadius.xl,
                boxShadow: [
                  BoxShadow(
                    color: KColors.green.withAlpha(60),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('\uD83E\uDD89',
                      style: TextStyle(fontSize: 52)),
                  const SizedBox(width: KSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Halo dari Kawi!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mau belajar apa hari ini? Foto PR-mu atau pilih pelajaran di bawah!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(230),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KSpace.lg),

          // Upcoming assignments (loading skeleton or content)
          if (_loadingAssignments || _assignments.isNotEmpty) ...[
            _onceAnimation(
              animationBuilder: ({required child}) =>
                  FadeInUp(delay: const Duration(milliseconds: 250), child: child),
              child: const Text(
                'Tugas & Ujian Mendatang',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _onceAnimation(
              animationBuilder: ({required child}) =>
                  FadeInUp(delay: const Duration(milliseconds: 300), child: child),
              child: SizedBox(
                height: 100,
                child: _loadingAssignments
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 2,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (_, __) => const SkeletonCard(),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _assignments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final a = _assignments[index];
                          final isTest = a['type'] == 'test';
                          return Container(
                            width: 220,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isTest
                                  ? KColors.surfaceOrange
                                  : Colors.white,
                              borderRadius: KRadius.md,
                              border: Border.all(
                                color: isTest
                                    ? KColors.orange
                                    : Colors.grey[200]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isTest ? '\uD83D\uDCDD' : '\uD83D\uDCDA',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        a['title'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${a['subject'] ?? ''} \u2014 ${a['topic'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: KColors.textMedium,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Deadline: ${a['due_date'] ?? '-'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isTest
                                        ? const Color(0xFFE65100)
                                        : KColors.textLight,
                                    fontWeight: isTest
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: KSpace.lg),
          ],

          // Upcoming reminders banner
          if (parentData.upcomingReminders.isNotEmpty)
            _onceAnimation(
              animationBuilder: ({required child}) =>
                  FadeInUp(delay: const Duration(milliseconds: 300), child: child),
              child: Builder(
                builder: (context) {
                  final upcoming = parentData.upcomingReminders;
                  final soonest = upcoming.first;
                  final daysLeft = soonest.dueDate
                      .difference(DateTime.now())
                      .inDays;
                  final isUrgent = daysLeft <= 1;
                  return Container(
                    margin: const EdgeInsets.only(bottom: KSpace.md),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFFFF3E0),
                      borderRadius: KRadius.md,
                      border: Border.all(
                        color: isUrgent
                            ? Colors.red.withAlpha(100)
                            : Colors.orange.withAlpha(100),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParentDashboardScreen(),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            isUrgent ? '\uD83D\uDEA8' : '\uD83D\uDCC5',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  daysLeft <= 0
                                      ? 'Hari ini: ${soonest.title}'
                                      : daysLeft == 1
                                          ? 'Besok: ${soonest.title}'
                                          : '$daysLeft hari lagi: ${soonest.title}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isUrgent
                                        ? Colors.red[800]
                                        : Colors.orange[900],
                                  ),
                                ),
                                Text(
                                  '${soonest.subject}${upcoming.length > 1 ? ' (+${upcoming.length - 1} lainnya)' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Quick actions
          _onceAnimation(
            animationBuilder: ({required child}) =>
                FadeInUp(delay: const Duration(milliseconds: 350), child: child),
            child: const Text(
              'Mau ngapain?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: KSpace.md),

          // Main action cards
          _onceAnimation(
            animationBuilder: ({required child}) =>
                FadeInUp(delay: const Duration(milliseconds: 400), child: child),
            child: GridView.count(
              crossAxisCount: actionColumns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: KSpace.md,
              crossAxisSpacing: KSpace.md,
              childAspectRatio: actionAspectRatio,
              children: [
                _ActionCard(
                  icon: '\uD83D\uDCF8',
                  title: 'Foto PR',
                  subtitle: 'Foto soal, Kawi bantu jawab',
                  color: KColors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ChatScreen(mode: ChatMode.homework),
                    ),
                  ),
                ),
                _ActionCard(
                  icon: '\u270D\uFE0F',
                  title: 'Dikte Mandarin',
                  subtitle: 'Latihan menulis \u542C\u5199',
                  color: KColors.red,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DictationScreen(),
                    ),
                  ),
                ),
                _ActionCard(
                  icon: '\uD83D\uDCDD',
                  title: 'Latihan Ujian',
                  subtitle: 'Persiapan ulangan & tes',
                  color: KColors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TestPrepScreen(),
                    ),
                  ),
                ),
                _ActionCard(
                  icon: '\uD83D\uDC68\u200D\uD83D\uDC69\u200D\uD83D\uDC67',
                  title: 'Laporan Orang Tua',
                  subtitle: 'Progress & pengingat PR/ujian',
                  color: const Color(0xFF7B1FA2),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentDashboardScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KSpace.xl),

          // Subject grid
          _onceAnimation(
            animationBuilder: ({required child}) =>
                FadeInUp(delay: const Duration(milliseconds: 500), child: child),
            child: const Text(
              'Mata Pelajaran',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: KSpace.md),

          _onceAnimation(
            animationBuilder: ({required child}) =>
                FadeInUp(delay: const Duration(milliseconds: 600), child: child),
            child: GridView.count(
              crossAxisCount: gridColumns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isWide ? 1.4 : 1.3,
              children: [
                _SubjectTile(
                  emoji: '\uD83D\uDD22',
                  name: 'Matematika',
                  onTap: () => _openSubject(context, 'Matematika'),
                ),
                _SubjectTile(
                  emoji: '\uD83C\uDDEE\uD83C\uDDE9',
                  name: 'B. Indonesia',
                  onTap: () => _openSubject(context, 'Bahasa Indonesia'),
                ),
                _SubjectTile(
                  emoji: '\uD83C\uDDE8\uD83C\uDDF3',
                  name: 'Mandarin',
                  onTap: () => _openSubject(context, 'Bahasa Mandarin'),
                ),
                _SubjectTile(
                  emoji: '\uD83D\uDD2C',
                  name: 'IPA',
                  onTap: () => _openSubject(context, 'IPA (Sains)'),
                ),
                _SubjectTile(
                  emoji: '\uD83C\uDF0D',
                  name: 'IPS',
                  onTap: () => _openSubject(context, 'IPS'),
                ),
                _SubjectTile(
                  emoji: '\uD83C\uDDEC\uD83C\uDDE7',
                  name: 'English',
                  onTap: () => _openSubject(context, 'English'),
                ),
                _SubjectTile(
                  emoji: '\uD83C\uDFDB\uFE0F',
                  name: 'PKN',
                  onTap: () => _openSubject(context, 'PKN'),
                ),
                _SubjectTile(
                  emoji: '\uD83D\uDCD6',
                  name: 'Lainnya',
                  onTap: () => _openSubject(context, 'Umum'),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Mark animations as done after first frame
    if (!_hasAnimated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _hasAnimated = true;
        }
      });
    }

    return Scaffold(
      backgroundColor: KColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: KColors.green,
          onRefresh: _loadAssignments,
          child: body,
        ),
      ),
    );
  }

  void _openSubject(BuildContext context, String subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          mode: ChatMode.subject,
          subject: subject,
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();
  void _onTapUp(TapUpDetails _) => _scaleController.reverse();
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: KRadius.lg,
        elevation: 2,
        shadowColor: widget.color.withAlpha(40),
        child: InkWell(
          borderRadius: KRadius.lg,
          onTap: widget.onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(25),
                    borderRadius: KRadius.md,
                  ),
                  child: Center(
                    child: Text(widget.icon,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: KColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: KColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectTile extends StatefulWidget {
  final String emoji;
  final String name;
  final VoidCallback onTap;

  const _SubjectTile({
    required this.emoji,
    required this.name,
    required this.onTap,
  });

  @override
  State<_SubjectTile> createState() => _SubjectTileState();
}

class _SubjectTileState extends State<_SubjectTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();
  void _onTapUp(TapUpDetails _) => _scaleController.reverse();
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: KRadius.lg,
        elevation: 1,
        child: InkWell(
          borderRadius: KRadius.lg,
          onTap: widget.onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
