import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../i18n/app_localizations.dart';
import '../models/provider_model.dart';

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
      backgroundColor: Colors.white,
      body: FutureBuilder<BalanceResult>(
        future: widget.balanceFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;

          if (widget.balanceFuture == null) {
            return const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          return Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: name + status + close
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
                              color: Color(0xFF34C759),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          widget.activeProvider.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: Colors.black.withValues(alpha: 0.25),
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
                // Balance
                Text(
                  AppLocalizations.of('remaining_balance'),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                if (snapshot.hasError)
                  Text(
                    AppLocalizations.of('api_unreachable_short'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  )
                else ...[
                  Text(
                    data != null
                        ? '${data.currencySymbol} ${data.remaining.toStringAsFixed(2)}'
                        : '--.--',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                      color: widget.balanceColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (data != null)
                    Text(
                      AppLocalizations.of('used_label', {
                        'symbol': data.currencySymbol,
                        'used': data.used.toStringAsFixed(2),
                      }),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                ],
                const Spacer(),
                // Settings button — flat, no shadow
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: widget.onOpenFullWindow,
                    icon: Icon(
                      Icons.settings_outlined,
                      size: 15,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                    label: Text(
                      AppLocalizations.of('open_dashboard'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.04),
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
        },
      ),
    );
  }
}
