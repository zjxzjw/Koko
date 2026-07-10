import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'models/provider_model.dart';
import 'services/storage_service.dart';
import 'ui/dashboard_view.dart';
import 'ui/tray_popup_view.dart';

const _kPopupSize = Size(250, 190);
const _kFullSize = Size(520, 700);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    if (details.exception is AssertionError &&
        details.exception.toString().contains('KeyDownEvent')) {
      return;
    }
    FlutterError.presentError(details);
  };

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    center: true,
    backgroundColor: Colors.white,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const BalanceMonitorApp());
}

class BalanceMonitorApp extends StatefulWidget {
  const BalanceMonitorApp({super.key});

  @override
  State<BalanceMonitorApp> createState() => _BalanceMonitorAppState();
}

class _BalanceMonitorAppState extends State<BalanceMonitorApp>
    with TrayListener, WindowListener {
  List<ProviderConfig> _providers = [];
  ProviderConfig? _activeProvider;
  BalanceResult? _lastBalance;
  bool _isFullView = true;

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initTrayAndData();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initTrayAndData() async {
    try {
      final iconPath = Platform.isWindows
          ? 'assets/app_icon.ico'
          : 'assets/tray_icon.png';
      await trayManager.setIcon(iconPath);
    } catch (e) {
      debugPrint('⚠ Tray setIcon error: $e');
    }
    try {
      await trayManager.setToolTip('KOKO — LLM Balance Monitor');
    } catch (e) {
      debugPrint('⚠ Tray setToolTip error: $e');
    }
    await _syncAppState();
  }

  Future<void> _syncAppState() async {
    try {
      final list = await StorageService.loadProviders();
      final savedId = await StorageService.loadSelectedId();
      final active = list.firstWhere(
        (p) => p.id == savedId,
        orElse: () => list.first,
      );
      if (mounted) {
        setState(() {
          _providers = list;
          _activeProvider = active;
        });
      }
      _updateTrayTitle();
    } catch (e) {
      debugPrint('⚠ Sync error: $e');
    }
  }

  void _onBalanceUpdated(BalanceResult? result) {
    _lastBalance = result;
    _updateTrayTitle();
  }

  void _updateTrayTitle() {
    final provider = _activeProvider;
    if (provider == null) return;
    final String title;
    if (_lastBalance != null) {
      title =
          '${provider.name} \$${_lastBalance!.remaining.toStringAsFixed(2)}';
    } else {
      title = provider.name;
    }
    final sym = _lastBalance?.currencySymbol ?? '\$';
    try {
      trayManager.setTitle(title);
      trayManager.setToolTip(
        '${provider.name}\n'
        'Remaining: $sym${_lastBalance?.remaining.toStringAsFixed(2) ?? "--.--"}\n'
        'Used: $sym${_lastBalance?.used.toStringAsFixed(2) ?? "--.--"}',
      );
    } catch (e) {
      debugPrint('⚠ Tray title update error: $e');
    }
  }

  Future<void> _showTrayPopup() async {
    await windowManager.setSize(_kPopupSize);
    if (mounted) setState(() => _isFullView = false);
    try {
      final trayBounds = await trayManager.getBounds();
      if (trayBounds != null && Platform.isMacOS) {
        await windowManager.setPosition(
          Offset(trayBounds.left - 110, trayBounds.bottom + 4),
        );
      }
    } catch (_) {}
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _showFullWindow() async {
    await windowManager.setSize(_kFullSize);
    if (mounted) setState(() => _isFullView = true);
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> onTrayIconMouseDown() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        await windowManager.hide();
      } else {
        await _showTrayPopup();
      }
    } catch (e) {
      debugPrint('⚠ Tray toggle error: $e');
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        await onTrayIconMouseDown();
      case 'quit':
        await windowManager.destroy();
    }
  }

  @override
  void onWindowBlur() async {
    await windowManager.hide();
    if (mounted) setState(() => _isFullView = false);
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
    if (mounted) setState(() => _isFullView = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_activeProvider == null || _providers.isEmpty) {
      return const SizedBox.shrink();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: Platform.isMacOS ? 'SF Pro Text' : 'Segoe UI',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: _isFullView
          ? DashboardView(
              activeProvider: _activeProvider!,
              allProviders: _providers,
              onRefreshRequested: _syncAppState,
              onBalanceUpdated: _onBalanceUpdated,
            )
          : TrayPopupView(
              activeProvider: _activeProvider!,
              onOpenFullWindow: _showFullWindow,
            ),
    );
  }
}
