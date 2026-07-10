import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../i18n/app_localizations.dart';
import '../models/provider_model.dart';
import '../services/storage_service.dart';
import 'app_theme.dart';
import 'balance_future_builder.dart';
import 'settings_view.dart';

class DashboardView extends StatefulWidget {
  final ProviderConfig activeProvider;
  final List<ProviderConfig> allProviders;
  final Future<BalanceResult>? balanceFuture;
  final VoidCallback onRefresh;
  final VoidCallback onRefreshRequested;
  final Color balanceColor;

  const DashboardView({
    super.key,
    required this.activeProvider,
    required this.allProviders,
    required this.balanceFuture,
    required this.onRefresh,
    required this.onRefreshRequested,
    required this.balanceColor,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProvider.id != widget.activeProvider.id) {
      widget.onRefresh();
    }
  }

  Future<void> _switchProvider(String newId) async {
    await StorageService.saveSelectedId(newId);
    widget.onRefreshRequested();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BalanceFutureBuilder(
        future: widget.balanceFuture,
        builder: (context, data) => _buildContent(data, null),
        errorBuilder: (context, error) => _buildContent(null, error),
      ),
    );
  }

  Widget _buildContent(BalanceResult? data, Object? error) {
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
            AppLocalizations.of('remaining_balance'),
            style: TextStyle(
              fontSize: 10,
              color: AppColors.dimText,
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
                ? '${data.currencySymbol} ${data.remaining.toStringAsFixed(2)}'
                : '--.--',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w300,
              color: widget.balanceColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (data != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of('used_total', {
                'symbol': data.currencySymbol,
                'used': data.used.toStringAsFixed(2),
                'total': data.total.toStringAsFixed(2),
              }),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.text(0.35),
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
                _chartLabel(AppLocalizations.of('daily_cost')),
                const Spacer(),
                _chartChip(
                  AppLocalizations.of('cost'),
                  '${data.currencySymbol} ${data.used.toStringAsFixed(2)}',
                  const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                _chartChip(
                  AppLocalizations.of('tokens'),
                  _fmtTokens(
                    data.daily.fold<int>(0, (s, d) => s + d.tokens),
                  ),
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
            AppLocalizations.of('model_breakdown'),
            style: TextStyle(
              fontSize: 10,
              color: AppColors.dimText,
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
      ],
    );
  }

  Widget _buildChart(BalanceResult data) {
    final now = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;
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
                '${d.date.day}/${d.date.month}\n${data.currencySymbol} ${d.cost.toStringAsFixed(3)}',
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
                v == 0 ? '' : '${data.currencySymbol} ${v.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 8,
                  color: AppColors.text(0.3),
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
                if (idx < 0 || idx >= daily.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${daily[idx].date.day}',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.text(0.3),
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
            color: AppColors.text(0.05),
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
                width: (screenWidth - 64) / daily.length * 0.6,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
                color: daily[i].cost > 0
                    ? AppColors.chartBlue
                    : AppColors.border(0.12),
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
      color: AppColors.secondaryText,
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
          color: AppColors.mutedText,
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
            color: AppColors.hoverBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: MenuAnchor(
            alignmentOffset: const Offset(0, 4),
            style: MenuStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              elevation: WidgetStateProperty.all(4),
            ),
            builder:
                (
                  BuildContext context,
                  MenuController controller,
                  Widget? child,
                ) {
                  return InkWell(
                    onTap: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.activeProvider.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: AppColors.accentText,
                          ),
                        ],
                      ),
                    ),
                  );
                },
            menuChildren: widget.allProviders
                .map(
                  (p) => MenuItemButton(
                    onPressed: () {
                      if (p.id != widget.activeProvider.id) {
                        _switchProvider(p.id);
                      }
                    },
                    style: MenuItemButton.styleFrom(
                      minimumSize: const Size(160, 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: Text(
                      p.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: p.id == widget.activeProvider.id
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                )
                .toList(),
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
                  color: AppColors.statusGreen,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                size: 16,
                color: AppColors.text(0.35),
              ),
              onPressed: () async {
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
                widget.onRefreshRequested();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: AppLocalizations.of('settings'),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 16,
                color: AppColors.text(0.35),
              ),
              onPressed: widget.onRefresh,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: AppLocalizations.of('refresh'),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.faintText,
              ),
              onPressed: () => windowManager.hide(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: AppLocalizations.of('hide'),
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
                    color: AppColors.faintText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of('api_unreachable'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of('check_network'),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.faintText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: widget.onRefresh,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: AppColors.text(0.5),
                    ),
                    label: Text(
                      AppLocalizations.of('refresh'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text(0.5),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.hoverBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
          AppLocalizations.of('no_data'),
          style: TextStyle(
            fontSize: 13,
            color: AppColors.text(0.35),
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
            color: AppColors.cardBg,
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
                        color: AppColors.text(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.totalTokens > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of('tokens_in_out', {
                          'in_tokens': (item.promptTokens / 1000)
                              .toStringAsFixed(0),
                          'out_tokens': (item.completionTokens / 1000)
                              .toStringAsFixed(0),
                        }),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.text(0.35),
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
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
