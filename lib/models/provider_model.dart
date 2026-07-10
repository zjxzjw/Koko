class ProviderConfig {
  final String id;
  String name;
  String baseUrl;
  String apiKey;
  String? customBalancePath;

  ProviderConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    this.customBalancePath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'customBalancePath': customBalancePath,
      };

  factory ProviderConfig.fromMap(Map<String, dynamic> map) => ProviderConfig(
        id: map['id'] as String,
        name: map['name'] as String,
        baseUrl: map['baseUrl'] as String,
        apiKey: map['apiKey'] as String,
        customBalancePath: map['customBalancePath'] as String?,
      );

  ProviderConfig copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? customBalancePath,
  }) =>
      ProviderConfig(
        id: id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        customBalancePath: customBalancePath ?? this.customBalancePath,
      );
}

class BalanceResult {
  final double remaining;
  final double used;
  final List<ModelUsage> details;
  final String currency;
  final List<DailyUsage> daily; // per-day cost & tokens for charts

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

/// A single day's aggregated usage for charting.
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
