import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ProvidersNotifier extends AsyncNotifier<List<ProviderConfig>> {
  @override
  Future<List<ProviderConfig>> build() async {
    return StorageService.loadProviders();
  }

  Future<void> addProvider(ProviderConfig config) async {
    final current = state.asData?.value ?? <ProviderConfig>[];
    final list = [...current, config];
    await StorageService.saveProviders(list);
    ref.invalidateSelf();
  }

  Future<void> updateProvider(ProviderConfig config) async {
    final current = state.asData?.value ?? <ProviderConfig>[];
    final index = current.indexWhere((p) => p.id == config.id);
    if (index != -1) {
      final list = [...current];
      list[index] = config;
      await StorageService.saveProviders(list);
      ref.invalidateSelf();
    }
  }

  Future<void> deleteProvider(String id) async {
    final current = state.asData?.value ?? <ProviderConfig>[];
    final list = current.where((p) => p.id != id).toList();
    await StorageService.saveProviders(list);
    ref.invalidateSelf();
  }
}

final providersProvider =
    AsyncNotifierProvider<ProvidersNotifier, List<ProviderConfig>>(
  ProvidersNotifier.new,
);

class ActiveProviderIdNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return StorageService.loadSelectedId();
  }

  Future<void> setActiveId(String id) async {
    await StorageService.saveSelectedId(id);
    state = AsyncData(id);
  }
}

final activeProviderIdProvider =
    AsyncNotifierProvider<ActiveProviderIdNotifier, String?>(
  ActiveProviderIdNotifier.new,
);

final activeProviderProvider = Provider<ProviderConfig?>((ref) {
  final providers = ref.watch(providersProvider).asData?.value ?? [];
  final activeId = ref.watch(activeProviderIdProvider).asData?.value;
  if (providers.isEmpty) return null;
  try {
    return providers.firstWhere((p) => p.id == activeId);
  } catch (_) {
    return providers.first;
  }
});

class BalanceNotifier extends AsyncNotifier<BalanceResult?> {
  Timer? _timer;

  @override
  Future<BalanceResult?> build() async {
    _timer?.cancel();
    ref.onDispose(() => _timer?.cancel());

    final provider = ref.watch(activeProviderProvider);
    if (provider == null || provider.apiKey.isEmpty) return null;

    final interval = provider.refreshIntervalMinutes;
    if (interval > 0) {
      _timer = Timer.periodic(Duration(minutes: interval), (_) {
        ref.invalidateSelf();
      });
    }

    return ApiService.fetchBalance(provider);
  }

  void refresh() {
    _timer?.cancel();
    ref.invalidateSelf();
  }
}

final balanceProvider =
    AsyncNotifierProvider<BalanceNotifier, BalanceResult?>(
  BalanceNotifier.new,
);
