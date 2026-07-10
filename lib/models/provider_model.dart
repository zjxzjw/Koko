class ProviderConfig {
  final String id;
  final String name;
  final String baseUrl;
  String apiKey;
  final String? customBalancePath;
  final int refreshIntervalMinutes;
  final double? minBalance;

  static int _nextId = 0;

  ProviderConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    this.customBalancePath,
    this.refreshIntervalMinutes = 0,
    this.minBalance,
  });

  static String generateId() {
    _nextId++;
    return 'p_${DateTime.now().microsecondsSinceEpoch}_$_nextId';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'customBalancePath': customBalancePath,
    'refreshIntervalMinutes': refreshIntervalMinutes,
    'minBalance': minBalance,
  };

  factory ProviderConfig.fromMap(Map<String, dynamic> map) => ProviderConfig(
    id: map['id'] as String,
    name: map['name'] as String,
    baseUrl: map['baseUrl'] as String,
    apiKey: map['apiKey'] as String,
    customBalancePath: map['customBalancePath'] as String?,
    refreshIntervalMinutes: map['refreshIntervalMinutes'] as int? ?? 0,
    minBalance: (map['minBalance'] as num?)?.toDouble(),
  );

  ProviderConfig copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? customBalancePath,
    int? refreshIntervalMinutes,
    double? minBalance,
  }) => ProviderConfig(
    id: id,
    name: name ?? this.name,
    baseUrl: baseUrl ?? this.baseUrl,
    apiKey: apiKey ?? this.apiKey,
    customBalancePath: customBalancePath ?? this.customBalancePath,
    refreshIntervalMinutes:
        refreshIntervalMinutes ?? this.refreshIntervalMinutes,
    minBalance: minBalance ?? this.minBalance,
  );
}

class BalanceResult {
  final double remaining;
  final double used;
  final List<ModelUsage> details;
  final String currency;
  final List<DailyUsage> daily;

  BalanceResult({
    required this.remaining,
    required this.used,
    required this.details,
    this.currency = 'USD',
    this.daily = const [],
  });

  double get total => remaining + used;

  String get currencySymbol {
    switch (currency) {
      case 'CNY':
        return '¥';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '\$';
    }
  }
}

class ModelUsage {
  final String modelName;
  final int promptTokens;
  final int completionTokens;
  final double cost;

  ModelUsage({
    required this.modelName,
    required this.promptTokens,
    required this.completionTokens,
    required this.cost,
  });

  int get totalTokens => promptTokens + completionTokens;
}

class DailyUsage {
  final DateTime date;
  final double cost;
  final int tokens;

  const DailyUsage({
    required this.date,
    required this.cost,
    required this.tokens,
  });
}
