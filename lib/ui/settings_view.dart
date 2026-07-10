import 'package:flutter/material.dart';
import '../i18n/app_localizations.dart';
import '../models/provider_model.dart';
import '../services/storage_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  List<ProviderConfig> _providers = [];
  bool _loading = true;
  String _localeCode = 'en';

  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();

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
    super.dispose();
  }

  Future<void> _loadData() async {
    final list = await StorageService.loadProviders();
    final locale = await StorageService.loadLocale();
    setState(() {
      _providers = list;
      _localeCode = locale;
      _loading = false;
    });
  }

  Future<void> _changeLocale(String code) async {
    AppLocalizations.setLocale(code);
    await StorageService.saveLocale(code);
    setState(() => _localeCode = code);
  }

  Future<void> _deleteProvider(ProviderConfig p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        title: Text(
          AppLocalizations.of('remove_provider'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.85),
          ),
        ),
        content: Text(
          AppLocalizations.of('delete_confirm', {'name': p.name}),
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.of('cancel'),
              style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
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
    } else {
      _nameController.clear();
      _urlController.clear();
      _keyController.clear();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        title: Text(
          existing == null
              ? AppLocalizations.of('add_provider')
              : AppLocalizations.of('edit_provider'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.85),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of('cancel'),
              style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final url = _urlController.text.trim();
              final key = _keyController.text.trim();
              if (name.isEmpty || url.isEmpty || key.isEmpty) return;

              if (existing != null) {
                existing.name = name;
                existing.baseUrl = url;
                existing.apiKey = key;
              } else {
                _providers.add(
                  ProviderConfig(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    baseUrl: url,
                    apiKey: key,
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
              style: TextStyle(color: Colors.black.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool obscure = false,
  }) {
    final borderColor = Colors.black.withValues(alpha: 0.12);
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(
        fontSize: 13,
        color: Colors.black.withValues(alpha: 0.85),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: 11,
          color: Colors.black.withValues(alpha: 0.4),
        ),
        hintStyle: TextStyle(
          fontSize: 12,
          color: Colors.black.withValues(alpha: 0.2),
        ),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.02),
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
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.35)),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of('settings'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.85),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black.withValues(alpha: 0.6)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditor(),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(AppLocalizations.of('general_settings')),
                _buildLanguageSelector(),
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
                                color: Colors.black.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of('no_providers'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black.withValues(alpha: 0.45),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showEditor(),
                                icon: const Icon(Icons.add, size: 16),
                                label: Text(
                                    AppLocalizations.of('add_first')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.black.withValues(alpha: 0.06),
                                  foregroundColor:
                                      Colors.black.withValues(alpha: 0.75),
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
                                  color: Colors.black.withValues(alpha: 0.85),
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                p.baseUrl,
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.4),
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
                                      color: Colors.black.withValues(alpha: 0.4),
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

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.language_outlined,
              size: 16, color: Colors.black.withValues(alpha: 0.45)),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of('language'),
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.7),
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
              backgroundColor: WidgetStateProperty.all(Colors.white),
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
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _localeCode == 'en' ? 'English' : '中文',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.black.withValues(alpha: 0.4),
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
          color: Colors.black.withValues(alpha: 0.35),
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
