import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../i18n/app_localizations.dart';
import '../models/provider_model.dart';
import 'app_theme.dart';
import 'balance_future_builder.dart';

class TrayPopupView extends StatefulWidget {
  final ProviderConfig activeProvider;
  final Future<BalanceResult>? balanceFuture;
  final VoidCallback onOpenFullWindow;
  final Color balanceColor;

  const TrayPopupView({
    super.key,
    required this.activeProvider,
    required this.balanceFuture,
    required this.onOpenFullWindow,
    required this.balanceColor,
  });

  @override
  State<TrayPopupView> createState() => _TrayPopupViewState();
}

class _TrayPopupViewState extends State<TrayPopupView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BalanceFutureBuilder(
        future: widget.balanceFuture,
        idle: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        loading: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        builder: (context, data) => _buildContent(data),
        errorBuilder: (context, _) => _buildContent(null),
      ),
    );
  }

  Widget _buildContent(BalanceResult? data) {
    return Container(
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
                    widget.activeProvider.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: AppColors.faintText,
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
              color: AppColors.text(0.35),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          if (data == null)
            Text(
              AppLocalizations.of('api_unreachable_short'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.mutedText,
              ),
            )
          else ...[
            Text(
              '${data.currencySymbol} ${data.remaining.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w300,
                color: widget.balanceColor,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              AppLocalizations.of('used_label', {
                'symbol': data.currencySymbol,
                'used': data.used.toStringAsFixed(2),
              }),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.text(0.35),
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: widget.onOpenFullWindow,
              icon: Icon(
                Icons.settings_outlined,
                size: 15,
                color: AppColors.secondaryText,
              ),
              label: Text(
                AppLocalizations.of('open_dashboard'),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.hoverBg,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
