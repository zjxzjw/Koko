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
    'no_providers': 'No providers configured',
    'add_first': 'Add your first provider',
    'hide': 'Hide to menu bar',
    'refresh': 'Refresh',
    'used_total':
        'Used {symbol}{used}  \u00b7  Total {symbol}{total}',
    'tokens_in_out':
        'Tokens: In {in_tokens}k | Out {out_tokens}k',
    'used_label': 'Used {symbol}{used}',
    'hint_name': 'e.g. DeepSeek',
    'hint_url': 'https://api.deepseek.com',
    'hint_key': 'sk-...',
    'language': 'Language',
    'settings': 'Settings',
    'general_settings': 'General',
    'model_settings': 'Model Providers',
    'balance_monitor': 'KOKO \u2014 LLM Balance Monitor',
    'balance_monitor_long':
        '{name}\nRemaining: {symbol}{remaining}\nUsed: {symbol}{used}',
    'auto_refresh': 'Auto Refresh',
    'off': 'Off',
    'every_10m': 'Every 10 min',
    'every_30m': 'Every 30 min',
    'every_60m': 'Every 60 min',
    'min_balance': 'Min Balance',
    'hint_min_balance': 'e.g. 10.00 (optional)',
    'appearance': 'Appearance',
    'theme_mode': 'Theme',
    'follow_system': 'Follow System',
    'light': 'Light',
    'dark': 'Dark',
    'low_balance_title': '{name}: low balance',
    'low_balance_body': '{symbol} {remaining} remaining',
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
    'no_providers': '未配置任何提供商',
    'add_first': '添加第一个提供商',
    'hide': '隐藏到菜单栏',
    'refresh': '刷新',
    'used_total':
        '已用 {symbol}{used}  \u00b7  总计 {symbol}{total}',
    'tokens_in_out':
        'Token：输入 {in_tokens}k | 输出 {out_tokens}k',
    'used_label': '已用 {symbol}{used}',
    'hint_name': '例如 DeepSeek',
    'hint_url': 'https://api.deepseek.com',
    'hint_key': 'sk-...',
    'language': '语言',
    'settings': '设置',
    'general_settings': '通用设置',
    'model_settings': '模型设置',
    'balance_monitor': 'KOKO \u2014 LLM 余额监控',
    'balance_monitor_long':
        '{name}\n剩余：{symbol}{remaining}\n已用：{symbol}{used}',
    'auto_refresh': '自动刷新',
    'off': '关闭',
    'every_10m': '每 10 分钟',
    'every_30m': '每 30 分钟',
    'every_60m': '每 60 分钟',
    'min_balance': '最低余额',
    'hint_min_balance': '例如 10.00（可选）',
    'appearance': '外观',
    'theme_mode': '主题模式',
    'follow_system': '跟随系统',
    'light': '浅色',
    'dark': '深色',
    'low_balance_title': '{name}: 余额不足',
    'low_balance_body': '剩余 {symbol}{remaining}',
  };
}
