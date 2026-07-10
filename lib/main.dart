import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'i18n/app_localizations.dart';
import 'models/provider_model.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'ui/app_theme.dart';
import 'ui/dashboard_view.dart';
import 'ui/tray_popup_view.dart';

const _kPopupSize = Size(250, 190);
const _kFullSize = Size(520, 520);

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

  const windowOptions = WindowOptions(
    size: _kFullSize,
    center: true,
    backgroundColor: Colors.white,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setResizable(false);
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
  String _localeCode = 'en';
  ThemeMode _themeMode = ThemeMode.system;
  Future<BalanceResult>? _balanceFuture;
  Timer? _refreshTimer;
  Color _balanceColor = AppColors.primaryText;

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initTrayAndData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
    await _loadLocale();
    await _loadTheme();
    try {
      await trayManager.setToolTip(AppLocalizations.of('balance_monitor'));
    } catch (e) {
      debugPrint('⚠ Tray setToolTip error: $e');
    }
    await _syncAppState();
    await _fetchBalance();
    _scheduleTimer();
  }

  Future<void> _loadLocale() async {
    final code = await StorageService.loadLocale();
    _localeCode = code;
    AppLocalizations.setLocale(code);
    if (mounted) { setState(() {}); }
  }

  Future<void> _loadTheme() async {
    final mode = await StorageService.loadThemeMode();
    _themeMode = _parseThemeMode(mode);
    AppColors.setMode(_themeMode);
    if (mounted) { setState(() {}); }
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _syncAppState() async {
    try {
      final list = await StorageService.loadProviders();
      final savedId = await StorageService.loadSelectedId();
      final active = list.firstWhere(
        (p) => p.id == savedId,
        orElse: () => list.first,
      );
      final savedLocale = await StorageService.loadLocale();
      _localeCode = savedLocale;
      AppLocalizations.setLocale(savedLocale);
      final savedTheme = await StorageService.loadThemeMode();
      _themeMode = _parseThemeMode(savedTheme);
      AppColors.setMode(_themeMode);
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

  Future<void> _fetchBalance() async {
    if (_activeProvider == null) return;
    final future = ApiService.fetchBalance(_activeProvider!);
    if (mounted) {
      setState(() {
        _balanceFuture = future;
      });
    }
    try {
      final result = await future;
      _lastBalance = result;
      _onBalanceUpdated(result);
    } catch (_) {}
    if (mounted) { setState(() {}); }
  }

  void _scheduleTimer() {
    _refreshTimer?.cancel();
    final interval = _activeProvider?.refreshIntervalMinutes ?? 0;
    if (interval > 0) {
      _refreshTimer = Timer.periodic(
        Duration(minutes: interval),
        (_) => _fetchBalance(),
      );
    }
  }

  Future<void> _onRefreshRequested() async {
    await _syncAppState();
    _scheduleTimer();
    await _fetchBalance();
  }

  void _onBalanceUpdated(BalanceResult? result) {
    _lastBalance = result;
    _balanceColor = _calcBalanceColor(result, _activeProvider);
    _updateTrayTitle();
  }

  Color _calcBalanceColor(BalanceResult? balance, ProviderConfig? provider) {
    if (balance == null || provider == null) {
      return AppColors.primaryText;
    }
    if (balance.remaining < 0) return Colors.red.shade700;
    if (provider.minBalance != null &&
        balance.remaining < provider.minBalance!) {
      return Colors.amber.shade700;
    }
    return AppColors.primaryText;
  }

  void _updateTrayTitle() {
    final provider = _activeProvider;
    if (provider == null) return;
    final String title;
    if (_lastBalance != null) {
      final sym = _lastBalance!.currencySymbol;
      title =
          '${provider.name} $sym ${_lastBalance!.remaining.toStringAsFixed(2)}';
    } else {
      title = provider.name;
    }
    final remaining = _lastBalance?.remaining.toStringAsFixed(2) ?? '--.--';
    final used = _lastBalance?.used.toStringAsFixed(2) ?? '--.--';
    final sym = _lastBalance?.currencySymbol ?? '\$';
    try {
      trayManager.setTitle(title);
      trayManager.setToolTip(
        AppLocalizations.of('balance_monitor_long', {
          'name': provider.name,
          'symbol': sym,
          'remaining': remaining,
          'used': used,
        }),
      );
    } catch (e) {
      debugPrint('⚠ Tray title update error: $e');
    }
  }

  Future<void> _showTrayPopup() async {
    await windowManager.setSize(_kPopupSize);
    if (mounted) {
      setState(() {
        _isFullView = false;
      });
    }
    try {
      final trayBounds = await trayManager.getBounds();
      if (trayBounds != null && Platform.isMacOS) {
        await windowManager.setPosition(
          Offset(trayBounds.left - 110, trayBounds.bottom + 4),
        );
      } else {
        await windowManager.center();
      }
    } catch (_) {
      await windowManager.center();
    }
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _showFullWindow() async {
    await windowManager.setSize(_kFullSize);
    if (mounted) {
      setState(() {
        _isFullView = true;
      });
    }
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
    if (mounted) {
      setState(() {
        _isFullView = false;
      });
    }
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
    if (mounted) {
      setState(() {
        _isFullView = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeProvider == null || _providers.isEmpty) {
      return MaterialApp(
        key: const ValueKey('empty'),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: Platform.isMacOS ? 'SF Pro Text' : 'Segoe UI',
          scaffoldBackgroundColor: AppColors.background,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: Platform.isMacOS ? 'SF Pro Text' : 'Segoe UI',
          scaffoldBackgroundColor: AppColors.background,
        ),
        themeMode: _themeMode,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.dns_outlined,
                  size: 48,
                  color: AppColors.subtleText,
                ),
                const SizedBox(height: 16),
                Text(
                  'No providers configured',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add one in Settings to get started',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.faintText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      key: ValueKey('view_$_isFullView$_localeCode$_themeMode'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: Platform.isMacOS ? 'SF Pro Text' : 'Segoe UI',
        scaffoldBackgroundColor: AppColors.background,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: Platform.isMacOS ? 'SF Pro Text' : 'Segoe UI',
        scaffoldBackgroundColor: AppColors.background,
      ),
      themeMode: _themeMode,
      home: _isFullView
          ? DashboardView(
              activeProvider: _activeProvider!,
              allProviders: _providers,
              balanceFuture: _balanceFuture,
              onRefresh: _fetchBalance,
              onRefreshRequested: _onRefreshRequested,
              balanceColor: _balanceColor,
            )
          : TrayPopupView(
              activeProvider: _activeProvider!,
              balanceFuture: _balanceFuture,
              onOpenFullWindow: _showFullWindow,
              balanceColor: _balanceColor,
            ),
    );
  }
}
