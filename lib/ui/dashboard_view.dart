import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../models/provider_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'settings_view.dart';

class DashboardView extends StatefulWidget {
  final ProviderConfig activeProvider;
  final List<ProviderConfig> allProviders;
  final VoidCallback onRefreshRequested;
  final void Function(BalanceResult?) onBalanceUpdated;

  const DashboardView({
    super.key,
    required this.activeProvider,
    required this.allProviders,
    required this.onRefreshRequested,
    required this.onBalanceUpdated,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<BalanceResult> _balanceFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProvider.id != widget.activeProvider.id) {
      _refreshData();
    }
  }

  void _refreshData() {
    setState(() {
      _balanceFuture = ApiService.fetchBalance(widget.activeProvider);
    });
  }

  Future<void> _switchProvider(String newId) async {
    await StorageService.saveSelectedId(newId);
    widget.onRefreshRequested();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<BalanceResult>(
        future: _balanceFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final error = snapshot.error;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onBalanceUpdated(data);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHeader(data, error),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'REMAINING BALANCE',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  data != null
                      ? '${data.currencySymbol}${data.remaining.toStringAsFixed(2)}'
                      : '--.--',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    color: Colors.black.withValues(alpha: 0.85),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (data != null) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Used ${data.currencySymbol}${data.used.toStringAsFixed(2)}  ·  '
                    'Total ${data.currencySymbol}${data.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
              if (data != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _chartLabel('Daily Cost'),
                      const Spacer(),
                      _chartChip(
                        'Cost',
                        '${data.currencySymbol}${data.used.toStringAsFixed(2)}',
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 12),
                      _chartChip(
                        'Tokens',
                        '${_fmtTokens(data.daily.fold<int>(0, (s, d) => s + d.tokens))}',
                        const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 140,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildChart(data),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'MODEL BREAKDOWN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildUsageList(
                  data,
                  error,
                  data?.currencySymbol ?? '\$',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildFooter(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChart(BalanceResult data) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daily = data.daily.isNotEmpty
        ? data.daily
        : List.generate(
            daysInMonth,
            (i) => DailyUsage(
              date: DateTime(now.year, now.month, i + 1),
              cost: 0,
              tokens: 0,
            ),
          );
    final maxCost = daily
        .map((d) => d.cost)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: (maxCost * 1.25).clamp(0.01, double.infinity),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 6,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = daily[groupIndex];
              return BarTooltipItem(
                '${d.date.day}/${d.date.month}\n${data.currencySymbol}${d.cost.toStringAsFixed(3)}',
                TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) => Text(
                v == 0 ? '' : '${data.currencySymbol}${v.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: (daily.length / 6).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= daily.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${daily[idx].date.day}',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxCost / 4).clamp(0.01, double.infinity),
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.black.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(daily.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: daily[i].cost,
                width: (520 - 64) / daily.length * 0.6,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
                color: daily[i].cost > 0
                    ? const Color(0xFF3B82F6)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _chartLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Colors.black.withValues(alpha: 0.55),
    ),
  );

  Widget _chartChip(String label, String value, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        '$label $value',
        style: TextStyle(
          fontSize: 10,
          color: Colors.black.withValues(alpha: 0.45),
        ),
      ),
    ],
  );

  String _fmtTokens(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }

  Widget _buildHeader(BalanceResult? data, Object? error) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.activeProvider.id,
              dropdownColor: Colors.white,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.black.withValues(alpha: 0.4),
              ),
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              items: widget.allProviders
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id != null && id != widget.activeProvider.id) {
                  _switchProvider(id);
                }
              },
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data != null && data.details.isNotEmpty)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 16,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              onPressed: _refreshData,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.black.withValues(alpha: 0.25),
              ),
              onPressed: () => windowManager.hide(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Hide to menu bar',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsageList(BalanceResult? data, Object? error, String symbol) {
    if (data == null) {
      return Center(
        child: error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 28,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to reach API',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check your API key and network',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              )
            : const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
      );
    }

    if (data.details.isEmpty) {
      return Center(
        child: Text(
          'No usage data yet',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: data.details.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final item = data.details[idx];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.modelName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.totalTokens > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tokens: In ${(item.promptTokens / 1000).toStringAsFixed(0)}k'
                        ' | Out ${(item.completionTokens / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '$symbol${item.cost.toStringAsFixed(3)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
        widget.onRefreshRequested();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Preferences...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
