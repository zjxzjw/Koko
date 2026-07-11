import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:window_manager/window_manager.dart';

import '../i18n/app_localizations.dart';
import '../models/provider_model.dart';
import '../providers/providers.dart';
import 'app_theme.dart';

class TrayPopupView extends ConsumerWidget {
  final VoidCallback onOpenFullWindow;

  const TrayPopupView({super.key, required this.onOpenFullWindow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final balanceAsync = ref.watch(balanceProvider);
    final activeProvider = ref.watch(activeProviderProvider);
    final data = balanceAsync.asData?.value;
    final activeName = activeProvider?.name ?? '';
    final balanceColor = _calcBalanceColor(ref, data, activeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data != null)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.statusGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      activeName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: colors.faintText,
                  ),
                  onPressed: () => windowManager.hide(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              AppLocalizations.of('remaining_balance'),
              style: TextStyle(
                fontSize: 10,
                color: colors.dimText,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            balanceAsync.when(
              data: (d) {
                if (d == null) {
                  return Text(
                    AppLocalizations.of('api_unreachable_short'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: colors.mutedText,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.currencySymbol} ${d.remaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                        color: balanceColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      AppLocalizations.of('used_label', {
                        'symbol': d.currencySymbol,
                        'used': d.used.toStringAsFixed(2),
                      }),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.dimText,
                      ),
                    ),
                  ],
                );
              },
              loading: () => Shimmer.fromColors(
                baseColor: colors.cardBg,
                highlightColor: colors.hoverBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors.cardBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.cardBg,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              error: (_, _) => Text(
                AppLocalizations.of('api_unreachable_short'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colors.mutedText,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onOpenFullWindow,
                icon: Icon(
                  Icons.settings_outlined,
                  size: 15,
                  color: colors.secondaryText,
                ),
                label: Text(
                  AppLocalizations.of('open_dashboard'),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.secondaryText,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: colors.hoverBg,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _calcBalanceColor(
    WidgetRef ref,
    BalanceResult? balance,
    ProviderConfig? provider,
  ) {
    final colors = AppColors.of(ref.context);
    if (balance == null || provider == null) return colors.primaryText;
    if (balance.remaining < 0) return Colors.red.shade700;
    if (provider.minBalance != null &&
        balance.remaining < provider.minBalance!) {
      return Colors.amber.shade700;
    }
    return colors.primaryText;
  }
}
