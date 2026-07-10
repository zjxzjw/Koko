import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/provider_model.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (_) => true,
    ),
  )..interceptors.add(_LogInterceptor());

  static Future<BalanceResult> fetchBalance(ProviderConfig config) async {
    final base = config.baseUrl
        .replaceAll(RegExp(r'/+$'), '')
        .replaceAll(RegExp(r'/v1$'), '');

    final headers = {
      'Authorization': 'Bearer ${config.apiKey}',
      'Accept': 'application/json',
    };

    if (base.contains('deepseek.com')) return _fetchDeepSeek(base, headers);
    if (base.contains('openai.com')) return _fetchOpenAI(base, headers);

    final r = await _tryDeepSeekStyle(base, headers);
    if (r != null) return r;
    return _tryOpenAIStyle(base, headers);
  }

  static Future<BalanceResult> _fetchDeepSeek(
    String base,
    Map<String, String> headers,
  ) async {
    // 1. Balance
    final balUrl = '$base/user/balance';
    final balRes = await _dio.get(balUrl, options: Options(headers: headers));
    if (balRes.statusCode != 200) {
      throw DioException(
        requestOptions: RequestOptions(path: balUrl),
        response: balRes,
        message: 'DeepSeek returned ${balRes.statusCode}',
      );
    }

    final balData = balRes.data as Map<String, dynamic>;

    final infos =
        (balData['balance_infos'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final available = balData['is_available'] == true;

    double totalBalance = 0;
    double toppedUp = 0;
    String currency = 'USD';
    for (final info in infos) {
      final c = info['currency']?.toString() ?? 'USD';
      if (currency == 'USD' && c == 'CNY') currency = 'CNY';
      totalBalance += _toDouble(info['total_balance'] ?? 0);
      toppedUp += _toDouble(info['topped_up_balance'] ?? 0);
    }

    // 2. Usage (daily breakdown for charts) — try known paths.
    final now = DateTime.now();
    final pad = (int n) => n.toString().padLeft(2, '0');
    final startDate = '${now.year}-${pad(now.month)}-01';
    final endDate = '${now.year}-${pad(now.month)}-${pad(now.day)}';

    double totalCost = 0;
    int totalTokens = 0;
    final dayAgg = <String, _DayAgg>{};
    final modelAgg = <String, _ModelAgg2>{};
    Map<String, dynamic>? uData;

    for (final path in [
      '/v1/usage/metrics',
      '/v1/usage',
      '/v1/metrics',
      '/usage',
    ]) {
      final usageUrl =
          '$base$path'
          '?start_time=$startDate&end_time=$endDate';
      try {
        final uRes = await _dio.get(
          usageUrl,
          options: Options(headers: headers),
        );
        if (uRes.statusCode == 200 && uRes.data is Map) {
          uData = uRes.data as Map<String, dynamic>;
          debugPrint('   Body: ${_truncate(uData)}');
          break;
        }
      } catch (e) {
        debugPrint('   ← error: $e');
      }
    }

    if (uData != null) {
      final items =
          (uData['data'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];

      for (final item in items) {
        final date =
            item['date']?.toString() ?? item['timestamp']?.toString() ?? '';
        final model =
            item['model']?.toString() ??
            item['model_name']?.toString() ??
            'unknown';
        final prompt = _toInt(
          item['prompt_tokens'] ?? item['input_tokens'] ?? 0,
        );
        final completion = _toInt(
          item['completion_tokens'] ?? item['output_tokens'] ?? 0,
        );
        final cost = _toDouble(item['cost'] ?? 0);

        final dayKey = date.isNotEmpty ? date.substring(8, 10) : '??';
        dayAgg.update(
          dayKey,
          (a) {
            a.cost += cost;
            a.tokens += prompt + completion;
            return a;
          },
          ifAbsent: () => _DayAgg()
            ..cost = cost
            ..tokens = prompt + completion,
        );

        modelAgg.update(model, (m) {
          m.cost += cost;
          return m;
        }, ifAbsent: () => _ModelAgg2()..cost = cost);
        totalCost += cost;
        totalTokens += prompt + completion;
      }
    }

    final details = <ModelUsage>[];
    if (modelAgg.isNotEmpty) {
      for (final e in modelAgg.entries) {
        details.add(
          ModelUsage(
            modelName: e.key,
            promptTokens: 0,
            completionTokens: 0,
            cost: e.value.cost,
          ),
        );
      }
    } else {
      for (final i in infos) {
        details.add(
          ModelUsage(
            modelName: 'Balance (${i['currency']})',
            promptTokens: 0,
            completionTokens: 0,
            cost: _toDouble(i['total_balance'] ?? 0),
          ),
        );
      }
    }

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daily = <DailyUsage>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final k = d.toString().padLeft(2, '0');
      final a = dayAgg[k];
      daily.add(
        DailyUsage(
          date: DateTime(now.year, now.month, d),
          cost: a?.cost ?? 0,
          tokens: a?.tokens ?? 0,
        ),
      );
    }

    return BalanceResult(
      remaining: totalBalance,
      used: totalCost > 0
          ? totalCost
          : toppedUp > 0
          ? 0
          : 0,
      details: details,
      currency: currency,
      daily: daily,
    );
  }

  static Future<BalanceResult?> _tryDeepSeekStyle(
    String base,
    Map<String, String> headers,
  ) async {
    try {
      return await _fetchDeepSeek(base, headers);
    } catch (_) {
      return null;
    }
  }

  static Future<BalanceResult> _fetchOpenAI(
    String base,
    Map<String, String> headers,
  ) async {
    final now = DateTime.now();
    final pad = (int n) => n.toString().padLeft(2, '0');
    final start = '${now.year}-${pad(now.month)}-01';
    final end = '${now.year}-${pad(now.month)}-${pad(now.day)}';

    try {
      final costUrl =
          '$base/v1/organization/costs?start_date=$start&end_date=$end';
      debugPrint('   ➤ GET $costUrl');
      final r = await _dio.get(costUrl, options: Options(headers: headers));
      debugPrint('   ← ${r.statusCode}');
      if (r.statusCode == 200) {
        return _parseOpenAICosts(r.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      debugPrint('   ← ${e.response?.statusCode} — trying usage endpoint');
    }

    final dateStr = '${now.year}-${pad(now.month)}-${pad(now.day)}';
    final usageUrl = '$base/v1/usage?date=$dateStr';

    final u = await _dio.get(usageUrl, options: Options(headers: headers));

    if (u.statusCode == 200) {
      return _parseOpenAIUsage(u.data as Map<String, dynamic>);
    }

    throw DioException(
      requestOptions: RequestOptions(path: '$base/v1/...'),
      message:
          'OpenAI billing requires an Admin API key.\n'
          'Create one at platform.openai.com → Settings → Admin Keys.',
    );
  }

  static Future<BalanceResult> _tryOpenAIStyle(
    String base,
    Map<String, String> headers,
  ) async {
    try {
      return await _fetchOpenAI(base, headers);
    } catch (_) {
      return _tryLegacyBilling(base, headers);
    }
  }

  static BalanceResult _parseOpenAICosts(Map<String, dynamic> data) {
    final results = data['data'] as List<dynamic>? ?? [];
    final modelAgg = <String, double>{};
    final dayAgg = <String, _DayAgg>{};
    double totalCost = 0;

    for (final day in results) {
      final d = day as Map<String, dynamic>;
      final ts = _toInt(d['timestamp'] ?? 0);
      final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      final key =
          '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final items = d['line_items'] as List? ?? [];
      double dayCost = 0;
      for (final item in items) {
        final m = item as Map<String, dynamic>;
        final name = m['name']?.toString() ?? 'unknown';
        final cost = _toDouble(m['cost'] ?? 0);
        modelAgg.update(name, (c) => c + cost, ifAbsent: () => cost);
        totalCost += cost;
        dayCost += cost;
      }
      dayAgg.update(
        key,
        (a) => a..cost += dayCost,
        ifAbsent: () => _DayAgg()..cost = dayCost,
      );
    }

    final details = modelAgg.entries
        .map(
          (e) => ModelUsage(
            modelName: e.key,
            promptTokens: 0,
            completionTokens: 0,
            cost: double.parse(e.value.toStringAsFixed(4)),
          ),
        )
        .toList();
    if (details.isEmpty) {
      details.add(
        ModelUsage(
          modelName: 'No data',
          promptTokens: 0,
          completionTokens: 0,
          cost: 0,
        ),
      );
    }

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daily = <DailyUsage>[];
    for (var dd = 1; dd <= daysInMonth; dd++) {
      final k =
          '${now.month.toString().padLeft(2, '0')}-${dd.toString().padLeft(2, '0')}';
      final a = dayAgg[k];
      daily.add(
        DailyUsage(
          date: DateTime(now.year, now.month, dd),
          cost: a?.cost ?? 0,
          tokens: a?.tokens ?? 0,
        ),
      );
    }

    return BalanceResult(
      remaining: 0,
      used: totalCost,
      details: details,
      daily: daily,
    );
  }

  static BalanceResult _parseOpenAIUsage(Map<String, dynamic> data) {
    final modelAgg = <String, ModelUsage>{};
    final usageData = data['data'] as List<dynamic>? ?? [];
    for (final item in usageData) {
      final m = item as Map<String, dynamic>;
      final name = m['snapshot_id']?.toString() ?? 'usage';
      modelAgg.update(
        name,
        (u) => ModelUsage(
          modelName: name,
          promptTokens:
              u.promptTokens + _toInt(m['n_context_tokens_total'] ?? 0),
          completionTokens:
              u.completionTokens + _toInt(m['n_generated_tokens_total'] ?? 0),
          cost: 0,
        ),
        ifAbsent: () => ModelUsage(
          modelName: name,
          promptTokens: _toInt(m['n_context_tokens_total'] ?? 0),
          completionTokens: _toInt(m['n_generated_tokens_total'] ?? 0),
          cost: 0,
        ),
      );
    }
    final details = modelAgg.values.toList();
    if (details.isEmpty) {
      details.add(
        ModelUsage(
          modelName: 'No usage today',
          promptTokens: 0,
          completionTokens: 0,
          cost: 0,
        ),
      );
    }
    return BalanceResult(remaining: 0, used: 0, details: details, daily: []);
  }

  static Future<BalanceResult> _tryLegacyBilling(
    String base,
    Map<String, String> headers,
  ) async {
    throw DioException(
      requestOptions: RequestOptions(path: '$base/v1/...'),
      message:
          'No compatible billing API found.\n'
          'Use https://api.deepseek.com or https://api.openai.com.',
    );
  }

  static String _truncate(dynamic d, {int maxLen = 400}) {
    final s = d.toString();
    return s.length > maxLen ? '${s.substring(0, maxLen)}...' : s;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class _DayAgg {
  double cost = 0;
  int tokens = 0;
}

class _ModelAgg2 {
  double cost = 0;
}

class _LogInterceptor extends Interceptor {
  @override
  void onResponse(Response r, ResponseInterceptorHandler h) => h.next(r);

  @override
  void onError(DioException e, ErrorInterceptorHandler h) => h.next(e);
}
