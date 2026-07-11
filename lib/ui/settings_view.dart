import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_localizations.dart';
import '../models/provider_model.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import 'app_theme.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _minBalanceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _keyController.dispose();
    _minBalanceController.dispose();
    super.dispose();
  }

  Future<void> _deleteProvider(ProviderConfig p) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.dialogBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        title: Text(
          AppLocalizations.of('remove_provider'),
          style: TextStyle(
            fontSize: 14,
            color: colors.primaryText,
          ),
        ),
        content: Text(
          AppLocalizations.of('delete_confirm', {'name': p.name}),
          style: TextStyle(
            fontSize: 12,
            color: colors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.of('cancel'),
              style: TextStyle(color: colors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(providersProvider.notifier).deleteProvider(p.id);
    }
  }

  void _showEditor({ProviderConfig? existing}) {
    final colors = AppColors.of(context);
    if (existing != null) {
      _nameController.text = existing.name;
      _urlController.text = existing.baseUrl;
      _keyController.text = existing.apiKey;
      _minBalanceController.text =
          existing.minBalance?.toStringAsFixed(2) ?? '';
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
          backgroundColor: colors.dialogBg,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          title: Text(
            existing == null
                ? AppLocalizations.of('add_provider')
                : AppLocalizations.of('edit_provider'),
            style: TextStyle(
              fontSize: 14,
              color: colors.primaryText,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(
                AppLocalizations.of('name'),
                _nameController,
                hint: AppLocalizations.of('hint_name'),
              ),
              const SizedBox(height: 12),
              _buildField(
                AppLocalizations.of('base_url'),
                _urlController,
                hint: AppLocalizations.of('hint_url'),
              ),
              const SizedBox(height: 12),
              _buildField(
                AppLocalizations.of('api_key'),
                _keyController,
                hint: AppLocalizations.of('hint_key'),
                obscure: true,
              ),
              const SizedBox(height: 12),
              _buildField(
                AppLocalizations.of('min_balance'),
                _minBalanceController,
                hint: AppLocalizations.of('hint_min_balance'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    AppLocalizations.of('auto_refresh'),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.mutedText,
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
                      backgroundColor:
                          WidgetStateProperty.all(colors.menuBg),
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
                            color: colors.hoverBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.primaryText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: colors.accentText,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () =>
                            setDialogState(() => refreshInterval = 0),
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
                        onPressed: () =>
                            setDialogState(() => refreshInterval = 10),
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
                        onPressed: () =>
                            setDialogState(() => refreshInterval = 30),
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
                        onPressed: () =>
                            setDialogState(() => refreshInterval = 60),
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
                style: TextStyle(color: colors.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final url = _urlController.text.trim();
                final key = _keyController.text.trim();

                if (name.isEmpty) return;
                if (url.isEmpty ||
                    (!url.startsWith('http://') &&
                        !url.startsWith('https://'))) {
                  return;
                }
                if (key.isEmpty) return;

                final minBalText = _minBalanceController.text.trim();
                double? minBalance;
                if (minBalText.isNotEmpty) {
                  final parsed = double.tryParse(minBalText);
                  if (parsed == null || parsed < 0) return;
                  minBalance = parsed;
                }

                final notifier = ref.read(providersProvider.notifier);
                if (existing != null) {
                  await notifier.updateProvider(existing.copyWith(
                    name: name,
                    baseUrl: url,
                    apiKey: key,
                    refreshIntervalMinutes: refreshInterval,
                    minBalance: minBalance,
                  ));
                } else {
                  await notifier.addProvider(
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
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(
                AppLocalizations.of('save'),
                style: TextStyle(color: colors.primaryText),
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
    final colors = AppColors.of(context);
    final borderColor = colors.dimText.withValues(alpha: 0.3);
    return TextField(
      controller: controller,
      obscureText: obscure,
      cursorColor: colors.primaryText,
      style: TextStyle(
        fontSize: 13,
        color: colors.primaryText,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: 11,
          color: colors.secondaryText,
        ),
        hintStyle: TextStyle(
          fontSize: 12,
          color: colors.faintText,
        ),
        filled: true,
        fillColor: colors.cardBg,
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
          borderSide: BorderSide(color: colors.dimText),
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
    final colors = AppColors.of(context);
    final providersAsync = ref.watch(providersProvider);
    final localeCode =
        ref.watch(localeSettingProvider).asData?.value ?? 'en';
    final themeMode =
        ref.watch(themeModeSettingProvider).asData?.value ?? 'system';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of('settings'),
          style: TextStyle(
            fontSize: 14,
            color: colors.primaryText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actionsPadding: const EdgeInsets.only(right: 16),
        iconTheme: IconThemeData(color: colors.secondaryText),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 24, color: colors.secondaryText),
            onPressed: () => _showEditor(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
        ],
      ),
      body: providersAsync.when(
        data: (providers) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              AppLocalizations.of('general_settings'),
              colors,
            ),
            _buildLanguageSelector(localeCode, colors),
            _buildThemeSelector(themeMode, colors),
            const SizedBox(height: 8),
            _buildSectionHeader(
              AppLocalizations.of('model_settings'),
              colors,
            ),
            Expanded(
              child: providers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.dns_outlined,
                            size: 36,
                            color: colors.subtleText,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of('no_providers'),
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showEditor(),
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(
                              AppLocalizations.of('add_first'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.overlayBg,
                              foregroundColor: colors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: providers.length,
                      itemBuilder: (context, idx) {
                        final p = providers[idx];
                        return ListTile(
                          title: Text(
                            p.name,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            p.baseUrl,
                            style: TextStyle(
                              color: colors.secondaryText,
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
                                  color: colors.secondaryText,
                                ),
                                onPressed: () =>
                                    _showEditor(existing: p),
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
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: colors.mutedText),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(String themeMode, AppColors colors) {
    final label = switch (themeMode) {
      'light' => AppLocalizations.of('light'),
      'dark' => AppLocalizations.of('dark'),
      _ => AppLocalizations.of('follow_system'),
    };
    final icon = switch (themeMode) {
      'light' => Icons.light_mode,
      'dark' => Icons.dark_mode,
      _ => Icons.brightness_auto,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.mutedText),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of('theme_mode'),
            style: TextStyle(
              fontSize: 13,
              color: colors.primaryText,
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
              backgroundColor:
                  WidgetStateProperty.all(colors.menuBg),
              elevation: WidgetStateProperty.all(4),
            ),
            builder:
                (BuildContext context, MenuController controller,
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
                    color: colors.hoverBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: colors.accentText,
                      ),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [
              MenuItemButton(
                onPressed: () => ref
                    .read(themeModeSettingProvider.notifier)
                    .setThemeMode('system'),
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
                    fontWeight: themeMode == 'system'
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () => ref
                    .read(themeModeSettingProvider.notifier)
                    .setThemeMode('light'),
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
                    fontWeight: themeMode == 'light'
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () => ref
                    .read(themeModeSettingProvider.notifier)
                    .setThemeMode('dark'),
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
                    fontWeight: themeMode == 'dark'
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

  Widget _buildLanguageSelector(String localeCode, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.language_outlined,
            size: 16,
            color: colors.mutedText,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of('language'),
            style: TextStyle(
              fontSize: 13,
              color: colors.primaryText,
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
              backgroundColor:
                  WidgetStateProperty.all(colors.menuBg),
              elevation: WidgetStateProperty.all(4),
            ),
            builder:
                (BuildContext context, MenuController controller,
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
                    color: colors.hoverBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localeCode == 'en' ? 'English' : '中文',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: colors.accentText,
                      ),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [
              MenuItemButton(
                onPressed: () => ref
                    .read(localeSettingProvider.notifier)
                    .setLocale('en'),
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
                    fontWeight: localeCode == 'en'
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () => ref
                    .read(localeSettingProvider.notifier)
                    .setLocale('zh'),
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
                    fontWeight: localeCode == 'zh'
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

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: colors.primaryText,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
