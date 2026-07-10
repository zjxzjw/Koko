class AppLocalizations {
  static String _localeCode = 'en';

  static String get localeCode => _localeCode;

  static void setLocale(String code) {
    _localeCode = code;
  }

  static String of(String key, [Map<String, String>? params]) {
    String text;
    if (_localeCode == 'zh' && _zh.containsKey(key)) {
      text = _zh[key]!;
    } else {
      text = _en[key] ?? key;
    }
    if (params != null) {
      for (final entry in params.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return text;
  }

  static const Map<String, String> _en = {
    'remaining_balance': 'REMAINING BALANCE',
    'model_breakdown': 'MODEL BREAKDOWN',
    'daily_cost': 'Daily Cost',
    'cost': 'Cost',
    'tokens': 'Tokens',
    'api_unreachable': 'Unable to reach API',
    'check_network': 'Check your API key and network',
    'no_data': 'No usage data yet',
    'preferences': 'Preferences...',
    'open_dashboard': 'Open Dashboard',
    'api_unreachable_short': 'API unreachable',
    'remove_provider': 'Remove provider?',
    'delete_confirm': 'Delete "{name}"? This cannot be undone.',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'add_provider': 'Add Provider',
    'edit_provider': 'Edit Provider',
    'name': 'Name',
    'base_url': 'Base URL (OpenAI-compatible)',
    'api_key': 'API Key',
    'save': 'Save',
    'model_providers': 'Model Providers',
    'no_providers': 'No providers configured',
    'add_first': 'Add your first provider',
    'hide': 'Hide to menu bar',
    'refresh': 'Refresh',
    'used_total':
        'Used {symbol}{used}  \u00b7  Total {symbol}{total}',
    'tokens_in_out':
        'Tokens: In {in_tokens}k | Out {out_tokens}k',
    'used_label': 'Used {symbol}{used}',
    'trailing_used': 'Used {symbol}{amount}',
    'hint_name': 'e.g. DeepSeek',
    'hint_url': 'https://api.deepseek.com',
    'hint_key': 'sk-...',
    'language': 'Language',
    'settings': 'Settings',
    'general_settings': 'General',
    'model_settings': 'Model Providers',
    'today_usage': "Today's Usage",
    'balance_monitor': 'KOKO \u2014 LLM Balance Monitor',
    'balance_monitor_long':
        '{name}\nRemaining: {symbol}{remaining}\nUsed: {symbol}{used}',
  };

  static const Map<String, String> _zh = {
    'remaining_balance': '剩余余额',
    'model_breakdown': '模型用量明细',
    'daily_cost': '每日费用',
    'cost': '费用',
    'tokens': 'Token 数',
    'api_unreachable': '无法访问 API',
    'check_network': '请检查 API Key 和网络连接',
    'no_data': '暂无用量数据',
    'preferences': '偏好设置...',
    'open_dashboard': '打开仪表盘',
    'api_unreachable_short': 'API 无法访问',
    'remove_provider': '删除提供商？',
    'delete_confirm': '删除 "{name}"？此操作不可撤销。',
    'cancel': '取消',
    'delete': '删除',
    'add_provider': '添加提供商',
    'edit_provider': '编辑提供商',
    'name': '名称',
    'base_url': '基础 URL（OpenAI 兼容）',
    'api_key': 'API Key',
    'save': '保存',
    'model_providers': '模型提供商',
    'no_providers': '未配置任何提供商',
    'add_first': '添加第一个提供商',
    'hide': '隐藏到菜单栏',
    'refresh': '刷新',
    'used_total':
        '已用 {symbol}{used}  \u00b7  总计 {symbol}{total}',
    'tokens_in_out':
        'Token：输入 {in_tokens}k | 输出 {out_tokens}k',
    'used_label': '已用 {symbol}{used}',
    'trailing_used': '已用 {symbol}{amount}',
    'hint_name': '例如 DeepSeek',
    'hint_url': 'https://api.deepseek.com',
    'hint_key': 'sk-...',
    'language': '语言',
    'settings': '设置',
    'general_settings': '通用设置',
    'model_settings': '模型设置',
    'today_usage': '今日用量',
    'balance_monitor': 'KOKO \u2014 LLM 余额监控',
    'balance_monitor_long':
        '{name}\n剩余：{symbol}{remaining}\n已用：{symbol}{used}',
  };
}
