import 'package:flutter/material.dart';
import '../i18n/app_localizations.dart';
import '../models/provider_model.dart';
import '../services/storage_service.dart';
import 'app_theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  List<ProviderConfig> _providers = [];
  bool _loading = true;
  String _localeCode = 'en';
  String _themeMode = 'system';

  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _minBalanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _keyController.dispose();
    _minBalanceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final list = await StorageService.loadProviders();
    final locale = await StorageService.loadLocale();
    final theme = await StorageService.loadThemeMode();
    setState(() {
      _providers = list;
      _localeCode = locale;
      _themeMode = theme;
      _loading = false;
    });
  }

  Future<void> _changeLocale(String code) async {
    AppLocalizations.setLocale(code);
    await StorageService.saveLocale(code);
    setState(() => _localeCode = code);
  }

  Future<void> _changeTheme(String mode) async {
    await StorageService.saveThemeMode(mode);
    setState(() => _themeMode = mode);
  }

  Future<void> _deleteProvider(ProviderConfig p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dialogBg,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        title: Text(
          AppLocalizations.of('remove_provider'),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primaryText,
          ),
        ),
        content: Text(
          AppLocalizations.of('delete_confirm', {'name': p.name}),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text(0.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.of('cancel'),
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of('delete'),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _providers.removeWhere((item) => item.id == p.id);
      await StorageService.saveProviders(_providers);
      _loadData();
    }
  }

  void _showEditor({ProviderConfig? existing}) {
    if (existing != null) {
      _nameController.text = existing.name;
      _urlController.text = existing.baseUrl;
      _keyController.text = existing.apiKey;
      _minBalanceController.text = existing.minBalance?.toStringAsFixed(2) ?? '';
    } else {
      _nameController.clear();
      _urlController.clear();
      _keyController.clear();
      _minBalanceController.clear();
    }

    int refreshInterval = existing?.refreshIntervalMinutes ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.dialogBg,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
          title: Text(
            existing == null
                ? AppLocalizations.of('add_provider')
                : AppLocalizations.of('edit_provider'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryText,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(
                  AppLocalizations.of('name'), _nameController,
                  hint: AppLocalizations.of('hint_name')),
              const SizedBox(height: 12),
              _buildField(
                  AppLocalizations.of('base_url'), _urlController,
                  hint: AppLocalizations.of('hint_url')),
              const SizedBox(height: 12),
              _buildField(
                  AppLocalizations.of('api_key'), _keyController,
                  hint: AppLocalizations.of('hint_key'), obscure: true),
              const SizedBox(height: 12),
              _buildField(
                  AppLocalizations.of('min_balance'), _minBalanceController,
                  hint: AppLocalizations.of('hint_min_balance')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    AppLocalizations.of('auto_refresh'),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const Spacer(),
                  MenuAnchor(
                    alignmentOffset: const Offset(0, 4),
                    style: MenuStyle(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                      backgroundColor: WidgetStateProperty.all(AppColors.menuBg),
                      elevation: WidgetStateProperty.all(4),
                    ),
                    builder: (context, controller, child) {
                      final label = switch (refreshInterval) {
                        10 => AppLocalizations.of('every_10m'),
                        30 => AppLocalizations.of('every_30m'),
                        60 => AppLocalizations.of('every_60m'),
                        _ => AppLocalizations.of('off'),
                      };
                      return InkWell(
                        onTap: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.hoverBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: AppColors.accentText,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () => setDialogState(() => refreshInterval = 0),
                        style: MenuItemButton.styleFrom(
                          minimumSize: const Size(100, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of('off'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: refreshInterval == 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      MenuItemButton(
                        onPressed: () => setDialogState(() => refreshInterval = 10),
                        style: MenuItemButton.styleFrom(
                          minimumSize: const Size(100, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of('every_10m'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: refreshInterval == 10
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      MenuItemButton(
                        onPressed: () => setDialogState(() => refreshInterval = 30),
                        style: MenuItemButton.styleFrom(
                          minimumSize: const Size(100, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of('every_30m'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: refreshInterval == 30
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      MenuItemButton(
                        onPressed: () => setDialogState(() => refreshInterval = 60),
                        style: MenuItemButton.styleFrom(
                          minimumSize: const Size(100, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of('every_60m'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: refreshInterval == 60
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocalizations.of('cancel'),
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final url = _urlController.text.trim();
                final key = _keyController.text.trim();
                if (name.isEmpty || url.isEmpty || key.isEmpty) return;

                final minBalText = _minBalanceController.text.trim();
                final minBalance = minBalText.isEmpty
                    ? null
                    : double.tryParse(minBalText);

                if (existing != null) {
                  final index = _providers.indexWhere((p) => p.id == existing.id);
                  if (index != -1) {
                    _providers[index] = existing.copyWith(
                      name: name,
                      baseUrl: url,
                      apiKey: key,
                      refreshIntervalMinutes: refreshInterval,
                      minBalance: minBalance,
                    );
                  }
                } else {
                  _providers.add(
                    ProviderConfig(
                      id: ProviderConfig.generateId(),
                      name: name,
                      baseUrl: url,
                      apiKey: key,
                      refreshIntervalMinutes: refreshInterval,
                      minBalance: minBalance,
                    ),
                  );
                }
                final nav = Navigator.of(ctx);
                await StorageService.saveProviders(_providers);
                nav.pop();
                _loadData();
              },
              child: Text(
                AppLocalizations.of('save'),
                style: TextStyle(color: AppColors.primaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool obscure = false,
  }) {
    final borderColor = AppColors.border(0.12);
    return TextField(
      controller: controller,
      obscureText: obscure,
      cursorColor: AppColors.primaryText,
      style: TextStyle(
        fontSize: 13,
        color: AppColors.primaryText,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: 11,
          color: AppColors.text(0.4),
        ),
        hintStyle: TextStyle(
          fontSize: 12,
          color: AppColors.faintText,
        ),
        filled: true,
        fillColor: AppColors.surface(0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.border(0.35)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of('settings'),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primaryText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actionsPadding: const EdgeInsets.only(right: 16),
        iconTheme: IconThemeData(color: AppColors.text(0.6)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 24, color: AppColors.text(0.45)),
            onPressed: () => _showEditor(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryText,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(AppLocalizations.of('general_settings')),
                _buildLanguageSelector(),
                _buildThemeSelector(),
                const SizedBox(height: 8),
                _buildSectionHeader(AppLocalizations.of('model_settings')),
                Expanded(
                  child: _providers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.dns_outlined,
                                size: 36,
                                color: AppColors.subtleText,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of('no_providers'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showEditor(),
                                icon: const Icon(Icons.add, size: 16),
                                label: Text(
                                    AppLocalizations.of('add_first')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.overlayBg,
                                  foregroundColor: AppColors.text(0.75),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _providers.length,
                          itemBuilder: (context, idx) {
                            final p = _providers[idx];
                            return ListTile(
                              title: Text(
                                p.name,
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                p.baseUrl,
                                style: TextStyle(
                                  color: AppColors.text(0.4),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: AppColors.text(0.4),
                                    ),
                                    onPressed: () => _showEditor(existing: p),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _deleteProvider(p),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildThemeSelector() {
    final label = switch (_themeMode) {
      'light' => AppLocalizations.of('light'),
      'dark' => AppLocalizations.of('dark'),
      _ => AppLocalizations.of('follow_system'),
    };
    final icon = switch (_themeMode) {
      'light' => Icons.light_mode,
      'dark' => Icons.dark_mode,
      _ => Icons.brightness_auto,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.mutedText),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of('theme_mode'),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.text(0.7),
            ),
          ),
          const Spacer(),
          MenuAnchor(
            alignmentOffset: const Offset(0, 4),
            style: MenuStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              backgroundColor: WidgetStateProperty.all(AppColors.menuBg),
              elevation: WidgetStateProperty.all(4),
            ),
            builder: (BuildContext context, MenuController controller,
                Widget? child) {
              return InkWell(
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.hoverBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.accentText,
                      ),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [
              MenuItemButton(
                onPressed: () => _changeTheme('system'),
                style: MenuItemButton.styleFrom(
                  minimumSize: const Size(120, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  AppLocalizations.of('follow_system'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _themeMode == 'system'
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () => _changeTheme('light'),
                style: MenuItemButton.styleFrom(
                  minimumSize: const Size(120, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  AppLocalizations.of('light'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _themeMode == 'light'
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () => _changeTheme('dark'),
                style: MenuItemButton.styleFrom(
                  minimumSize: const Size(120, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  AppLocalizations.of('dark'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _themeMode == 'dark'
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.language_outlined,
              size: 16, color: AppColors.mutedText),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of('language'),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.text(0.7),
            ),
          ),
          const Spacer(),
          MenuAnchor(
            alignmentOffset: const Offset(0, 4),
            style: MenuStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              backgroundColor: WidgetStateProperty.all(AppColors.menuBg),
              elevation: WidgetStateProperty.all(4),
            ),
            builder: (BuildContext context, MenuController controller,
                Widget? child) {
              return InkWell(
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.hoverBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _localeCode == 'en' ? 'English' : '中文',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.accentText,
                      ),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [
              MenuItemButton(
                onPressed: () => _changeLocale('en'),
                style: MenuItemButton.styleFrom(
                  minimumSize: const Size(100, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  'English',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _localeCode == 'en'
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () => _changeLocale('zh'),
                style: MenuItemButton.styleFrom(
                  minimumSize: const Size(100, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  '中文',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _localeCode == 'zh'
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.dimText,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
