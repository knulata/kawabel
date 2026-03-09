import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_service.dart';
import '../../core/models/student.dart';
import '../../core/theme/kawabel_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton_loader.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Map<String, dynamic>> _progress = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final student = context.read<StudentProvider>().student!;
    final progress = await ApiService.getProgress(studentId: student.id);
    if (mounted) {
      setState(() {
        _progress = progress;
        _loading = false;
      });
    }
  }

  Map<String, Map<String, dynamic>> _getSubjectStats() {
    final stats = <String, Map<String, dynamic>>{};
    for (final p in _progress) {
      final subject = p['subject'] as String? ?? 'Lainnya';
      if (!stats.containsKey(subject)) {
        stats[subject] = {'total_score': 0, 'total_questions': 0, 'sessions': 0};
      }
      stats[subject]!['total_score'] += (p['score'] as int? ?? 0);
      stats[subject]!['total_questions'] += (p['total'] as int? ?? 0);
      stats[subject]!['sessions'] += 1;
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>().student!;
    final isWide = MediaQuery.of(context).size.width > 600;
    final subjectStats = _getSubjectStats();

    return Scaffold(
      backgroundColor: KColors.surface,
      appBar: AppBar(
        backgroundColor: KColors.green,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Text('🦉 ', style: TextStyle(fontSize: 24)),
            Text('Progressku', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: _loading
          ? Padding(
              padding: EdgeInsets.all(isWide ? 32 : 20),
              child: Column(
                children: [
                  const SkeletonLoader(height: 120, borderRadius: BorderRadius.all(Radius.circular(20))),
                  const SizedBox(height: 24),
                  Row(
                    children: List.generate(3, (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i > 0 ? 12 : 0),
                        child: const SkeletonLoader(height: 100, borderRadius: BorderRadius.all(Radius.circular(14))),
                      ),
                    )),
                  ),
                  const SizedBox(height: 28),
                  const SkeletonLoader(height: 20, width: 180),
                  const SizedBox(height: 16),
                  ...List.generate(3, (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonLoader(height: 80, borderRadius: BorderRadius.all(Radius.circular(12))),
                  )),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 32 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student stats card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('🦉', style: TextStyle(fontSize: 48)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                student.grade,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(200),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 28)),
                            Text(
                              '${student.stars}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Level ${student.level}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats overview
                  Row(
                    children: [
                      _StatCard(
                        label: 'Sesi Belajar',
                        value: '${_progress.length}',
                        icon: '📚',
                        color: KColors.blue,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Mata Pelajaran',
                        value: '${subjectStats.length}',
                        icon: '📖',
                        color: KColors.purple,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Rata-rata',
                        value: _progress.isEmpty
                            ? '-'
                            : '${(_progress.map((p) => (p['score'] ?? 0) / (p['total'] ?? 1) * 100).reduce((a, b) => a + b) / _progress.length).round()}%',
                        icon: '📊',
                        color: KColors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Subject breakdown
                  const Text(
                    'Per Mata Pelajaran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (subjectStats.isEmpty)
                    EmptyState(
                      emoji: '\u{1F4DD}',
                      title: 'Belum ada data',
                      subtitle: 'Yuk mulai belajar supaya progressmu terlihat di sini!',
                      actionLabel: 'Mulai Belajar',
                      onAction: () => Navigator.of(context).pop(),
                    )
                  else
                    ...subjectStats.entries.map((entry) {
                      final subject = entry.key;
                      final stats = entry.value;
                      final totalQ = stats['total_questions'] as int;
                      final totalS = stats['total_score'] as int;
                      final pct = totalQ > 0 ? (totalS / totalQ * 100).round() : 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _subjectEmoji(subject),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      subject,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$pct%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: pct >= 70
                                          ? KColors.green
                                          : pct >= 50
                                              ? KColors.orange
                                              : KColors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100,
                                  backgroundColor: Colors.grey[200],
                                  color: pct >= 70
                                      ? Colors.green
                                      : pct >= 50
                                          ? Colors.orange
                                          : Colors.red,
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${stats['sessions']} sesi | $totalS/$totalQ benar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 28),

                  // Recent activity
                  const Text(
                    'Aktivitas Terakhir',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...(_progress.reversed.take(10).map((p) {
                    final type = p['type'] ?? 'homework';
                    final icon = type == 'dictation'
                        ? '✍️'
                        : type == 'test'
                            ? '📝'
                            : '📸';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${p['subject']} — ${p['topic']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${p['score']}/${p['total']} benar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatDate(p['created_at']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })),
                ],
              ),
            ),
    );
  }

  String _subjectEmoji(String subject) {
    final map = {
      'Matematika': '🔢',
      'Bahasa Indonesia': '🇮🇩',
      'Bahasa Mandarin': '🇨🇳',
      'IPA (Sains)': '🔬',
      'IPS': '🌍',
      'English': '🇬🇧',
      'PKN': '🏛️',
    };
    return map[subject] ?? '📖';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
      if (diff.inHours < 24) return '${diff.inHours}j lalu';
      if (diff.inDays < 7) return '${diff.inDays}h lalu';
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
