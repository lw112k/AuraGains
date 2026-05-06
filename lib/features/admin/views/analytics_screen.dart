import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/constants.dart';
import '../view_models/admin_viewmodel.dart';

/// Admin analytics dashboard.
///
/// Wraps itself in a local [ChangeNotifierProvider<AdminViewModel>] so it can
/// be pushed onto the navigator stack from anywhere without requiring
/// [AdminViewModel] to be registered in the global provider tree.
///
/// Data sources (all via [AdminViewModel] → [AdminRepository] → Supabase):
///   • Total / active user counts  → `users` table
///   • Posts created               → `posts` table
///   • Challenges completed        → `challenge_submissions` WHERE status='approved'
///   • Reports received / resolved → `reports` table
///   • Moderation actions          → `users` WHERE level ILIKE suspended/banned
///   • User growth chart           → `users.created_at` grouped by week (last 7 weeks)
///   • Posts per day chart         → `posts.created_at` grouped by day  (last 7 days)
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide a local AdminViewModel so this screen is self-contained and
    // does not require changes to main.dart.
    return ChangeNotifierProvider(
      create: (_) => AdminViewModel()..loadAnalytics(),
      child: const _AnalyticsView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private view — consumes [AdminViewModel]
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsView extends StatefulWidget {
  const _AnalyticsView();

  @override
  State<_AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<_AnalyticsView> {
  String _selectedRange = 'Last 30 Days';
  bool _isExporting = false;

  static const List<String> _ranges = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'Year to Date',
  ];

  // ── Category mock distribution — visual only, not from DB ──────────────────
  static const List<_CategoryShare> _categoryShares = [
    _CategoryShare(label: 'Strength',  value: 0.36, color: AppColors.acid),
    _CategoryShare(label: 'Recovery',  value: 0.24, color: AppColors.orange),
    _CategoryShare(label: 'Nutrition', value: 0.18, color: Color(0xFF65D6FF)),
    _CategoryShare(label: 'Cardio',    value: 0.22, color: Color(0xFFB388FF)),
  ];

  Future<void> _exportReports() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isExporting = true);

    // Simulated export delay — replace with real PDF/CSV export logic if needed.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isExporting = false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Analytics report exported successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      // ── AppBar (replaces AppNavBar which is currently an empty file) ────────
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white, size: AppIconSizes.md),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('ANALYTICS', style: AppTextStyles.displaySmall),
        centerTitle: false,
      ),
      body: Consumer<AdminViewModel>(
        builder: (context, vm, _) {
          // ── Error state ──────────────────────────────────────────────────────
          if (vm.error != null && !vm.isLoading) {
            return _buildErrorState(vm);
          }

          return RefreshIndicator(
            // Pull-to-refresh re-fetches all analytics data from Supabase.
            onRefresh: vm.loadAnalytics,
            color: AppColors.acid,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.mdd),
              children: [
                _buildRangeSelector(),
                const SizedBox(height: AppSpacing.md),
                // ── KPI cards ────────────────────────────────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.15,
                  children: [
                    _StatCard(
                      label: 'Total Users',
                      // Queries `users` table row count via AdminRepository.fetchUserCount()
                      value: vm.isLoading ? '—' : '${vm.totalUsers}',
                      icon: Icons.groups_rounded,
                      isLoading: vm.isLoading,
                    ),
                    _StatCard(
                      label: 'Active Users',
                      // Queries `users` WHERE level NOT ILIKE '%suspended%' AND NOT ILIKE '%banned%'
                      value: vm.isLoading ? '—' : '${vm.activeUsers}',
                      icon: Icons.trending_up_rounded,
                      variant: _StatVariant.success,
                      isLoading: vm.isLoading,
                    ),
                    _StatCard(
                      label: 'Posts Created',
                      // Queries `posts` table row count via AdminRepository.fetchPostCount()
                      value: vm.isLoading ? '—' : '${vm.totalPosts}',
                      icon: Icons.photo_library_outlined,
                      isLoading: vm.isLoading,
                    ),
                    _StatCard(
                      label: 'Challenges Completed',
                      // Queries `challenge_submissions` WHERE status = 'approved'
                      value: vm.isLoading ? '—' : '${vm.completedChallenges}',
                      icon: Icons.emoji_events_outlined,
                      variant: _StatVariant.warning,
                      isLoading: vm.isLoading,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // ── User growth line chart ────────────────────────────────────
                // Data: `users.created_at` grouped into 7 weekly buckets
                // (AdminRepository.fetchWeeklyUserGrowth)
                _ChartCard(
                  title: 'User Growth',
                  subtitle: 'Weekly sign-up trend — last 7 weeks',
                  isLoading: vm.isLoading,
                  child: SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _LineChartPainter(points: vm.weeklyGrowthPoints),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // ── Posts per day bar chart ───────────────────────────────────
                // Data: `posts.created_at` grouped into 7 daily buckets
                // (AdminRepository.fetchDailyPostCounts)
                _ChartCard(
                  title: 'Posts Per Day',
                  subtitle: 'Content activity — last 7 days',
                  isLoading: vm.isLoading,
                  child: SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _BarChartPainter(values: vm.dailyPostBars),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // ── Top categories donut ─────────────────────────────────────
                // Visual distribution only — no DB query.
                // TODO: Replace with real category data from `posts.category`
                //       when the posts feature is fully implemented.
                _ChartCard(
                  title: 'Top Categories',
                  subtitle: 'Distribution of post themes',
                  isLoading: false,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 116,
                        height: 116,
                        child: CustomPaint(
                          painter:
                              _DonutChartPainter(shares: _categoryShares),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          children: _categoryShares
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: item.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(item.label,
                                            style: AppTextStyles.bodySmall),
                                      ),
                                      Text(
                                        '${(item.value * 100).round()}%',
                                        style: AppTextStyles.monoSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // ── Moderation metrics ───────────────────────────────────────
                Text('MODERATION METRICS',
                    style: AppTextStyles.displayMedium),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.cardBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Queries: AdminRepository.fetchTotalReportCount()
                      _MetricRow(
                        label: 'Reports received',
                        value: vm.isLoading ? '—' : '${vm.reportsReceived}',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Queries: AdminRepository.fetchResolvedReportCount()
                      _MetricRow(
                        label: 'Reports resolved',
                        value: vm.isLoading ? '—' : '${vm.reportsResolved}',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Queries: AdminRepository.fetchModerationActionCount()
                      // users WHERE level ILIKE '%suspended%' OR '%banned%'
                      _MetricRow(
                        label: 'Ban/Suspend actions',
                        value: vm.isLoading
                            ? '—'
                            : '${vm.moderationActions}',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Derived from activeUsers / totalUsers
                      _MetricRow(
                        label: 'Active members',
                        value: vm.isLoading
                            ? '—'
                            : '${vm.activeUsers} / ${vm.totalUsers}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isExporting ? null : _exportReports,
                    style: AppButtonStyles.primary,
                    child: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.black,
                            ),
                          )
                        : const Text('Export Reports'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Error state widget ──────────────────────────────────────────────────────

  Widget _buildErrorState(AdminViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text('Failed to load analytics',
                style: AppTextStyles.labelLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              vm.error ?? 'Unknown error',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: vm.loadAnalytics,
              style: AppButtonStyles.primary,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date range selector ─────────────────────────────────────────────────────

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DATE RANGE', style: AppTextStyles.monoLabel),
                const SizedBox(height: AppSpacing.xxs),
                Text(_selectedRange, style: AppTextStyles.labelLarge),
              ],
            ),
          ),
          PopupMenuButton<String>(
            initialValue: _selectedRange,
            color: AppColors.card,
            onSelected: (value) {
              setState(() => _selectedRange = value);
              // TODO: Pass selected range to AdminViewModel and re-fetch
              // once the repository supports date-range scoped queries.
            },
            itemBuilder: (context) => _ranges
                .map(
                  (item) => PopupMenuItem<String>(
                    value: item,
                    child: Text(item, style: AppTextStyles.bodyMedium),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.steel,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Change', style: AppTextStyles.monoSmall),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.acid),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable private widgets
// ─────────────────────────────────────────────────────────────────────────────

enum _StatVariant { normal, success, warning }

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.variant = _StatVariant.normal,
    this.isLoading = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final _StatVariant variant;
  final bool isLoading;

  Color get _accentColor => switch (variant) {
        _StatVariant.success => AppColors.acid,
        _StatVariant.warning => AppColors.warning,
        _StatVariant.normal  => AppColors.muted,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: _accentColor, size: AppIconSizes.md),
          const Spacer(),
          isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.acid,
                  ),
                )
              : Text(value, style: AppTextStyles.statMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.isLoading = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.acid),
              ),
            )
          else
            child,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        Text(value,
            style: AppTextStyles.monoSmall
                .copyWith(color: AppColors.acid)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painters — identical to prototype; only data source changed
// ─────────────────────────────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    // Horizontal grid lines
    final gridPaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1;

    for (var i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = AppColors.acid
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.acid.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path     = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / math.max(points.length - 1, 1));
      final y = size.height - (points[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.points != points;
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (values.length * 1.6);
    final gap      = barWidth * 0.6;
    final paint    = Paint()..color = AppColors.orange;

    for (var i = 0; i < values.length; i++) {
      final left      = i * (barWidth + gap);
      final barHeight = values[i] * size.height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(AppRadius.sm),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.values != values;
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.shares});

  final List<_CategoryShare> shares;

  @override
  void paint(Canvas canvas, Size size) {
    final center      = Offset(size.width / 2, size.height / 2);
    final rect        = Rect.fromCircle(center: center, radius: size.width / 2.4);
    const strokeWidth = 18.0;
    var startAngle    = -math.pi / 2;

    for (final share in shares) {
      final sweep = 2 * math.pi * share.value;
      final paint = Paint()
        ..color       = share.color
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryShare {
  const _CategoryShare({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color  color;
}
