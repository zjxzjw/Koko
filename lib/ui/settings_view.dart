import 'package:flutter/material.dart';
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
    setState(() {
      _providers = list;
      _loading = false;
    });
  }

  Future<void> _deleteProvider(ProviderConfig p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'Remove provider?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.85),
          ),
        ),
        content: Text(
          'Delete "${p.name}"? This cannot be undone.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          existing == null ? 'Add Provider' : 'Edit Provider',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.85),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField('Name', _nameController, hint: 'e.g. DeepSeek'),
            const SizedBox(height: 12),
            _buildField(
              'Base URL (OpenAI-compatible)',
              _urlController,
              hint: 'https://api.deepseek.com',
            ),
            const SizedBox(height: 12),
            _buildField(
              'API Key',
              _keyController,
              hint: 'sk-...',
              obscure: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
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
              'Save',
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
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
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
          'Model Providers',
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
            icon: Icon(
              Icons.add,
              size: 20,
              color: Colors.black.withValues(alpha: 0.6),
            ),
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
          : _providers.isEmpty
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
                    'No providers configured',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showEditor(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add your first provider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.06),
                      foregroundColor: Colors.black.withValues(alpha: 0.75),
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
    );
  }
}
