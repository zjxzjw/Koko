import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import 'app_theme.dart';

class BalanceFutureBuilder extends StatelessWidget {
  final Future<BalanceResult>? future;
  final Widget Function(BuildContext, BalanceResult) builder;
  final Widget Function(BuildContext, Object?)? errorBuilder;
  final Widget? loading;
  final Widget? idle;

  const BalanceFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loading,
    this.idle,
  });

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return idle ??
          Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryText,
              ),
            ),
          );
    }

    return FutureBuilder<BalanceResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return builder(context, snapshot.data!);
        }
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error) ??
              const SizedBox.shrink();
        }
        return loading ??
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryText,
                ),
              ),
            );
      },
    );
  }
}
