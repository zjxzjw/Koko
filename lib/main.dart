import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'i18n/app_localizations.dart';
import 'models/provider_model.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'ui/app_theme.dart';
import 'ui/dashboard_view.dart';
import 'ui/settings_view.dart';
import 'ui/tray_popup_view.dart';

const _kPopupSize = Size(250, 190);
const _kFullSize = Size(520, 520);

final _notifications = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const initSettings = InitializationSettings(
    macOS: DarwinInitializationSettings(),
  );
  await _notifications.initialize(initSettings);

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
  bool _isFetching = false;
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
    final iconPath = Platform.isWindows
        ? 'assets/app_icon.ico'
        : 'assets/tray_icon.png';
    try {
      await trayManager.setIcon(iconPath);
    } catch (e) {
      debugPrint('Tray setIcon error: $e');
    }
    await _loadLocale();
    await _loadTheme();
    try {
      await trayManager.setToolTip(AppLocalizations.of('balance_monitor'));
    } catch (e) {
      debugPrint('Tray setToolTip error: $e');
    }
    await _loadProviders();
    if (_activeProvider != null && _activeProvider!.apiKey.isNotEmpty) {
      await _fetchBalance();
    }
    _scheduleTimer();
  }

  Future<void> _loadLocale() async {
    final code = await StorageService.loadLocale();
    _localeCode = code;
    AppLocalizations.setLocale(code);
    if (mounted) setState(() {});
  }

  Future<void> _loadTheme() async {
    final mode = await StorageService.loadThemeMode();
    _themeMode = _parseThemeMode(mode);
    AppColors.setMode(_themeMode);
    if (mounted) setState(() {});
  }

  static ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _loadProviders() async {
    try {
      final list = await StorageService.loadProviders();
      final savedId = await StorageService.loadSelectedId();
      ProviderConfig? active;
      if (list.isNotEmpty) {
        active = list.firstWhere(
          (p) => p.id == savedId,
          orElse: () => list.first,
        );
      }
      if (mounted) {
        setState(() {
          _providers = list;
          _activeProvider = active;
        });
      }
      _updateTrayTitle();
    } catch (e) {
      debugPrint('Load providers error: $e');
    }
  }

  Future<void> _fetchBalance() async {
    if (_activeProvider == null || _isFetching) return;
    _isFetching = true;
    final future = ApiService.fetchBalance(_activeProvider!);
    try {
      if (mounted) {
        setState(() {
          _balanceFuture = future;
        });
      }
      final result = await future;
      _lastBalance = result;
      await _onBalanceUpdated(result);
    } catch (_) {
      _lastBalance = null;
      await _onBalanceUpdated(null);
    } finally {
      _isFetching = false;
      if (mounted) setState(() {});
    }
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
    await _loadLocale();
    await _loadTheme();
    await _loadProviders();
    _scheduleTimer();
    await _fetchBalance();
  }

  Future<void> _onBalanceUpdated(BalanceResult? result) async {
    _balanceColor = _calcBalanceColor(result, _activeProvider);
    _updateTrayTitle();
    await _checkLowBalanceNotification(result);
    if (mounted) setState(() {});
  }

  Future<void> _checkLowBalanceNotification(BalanceResult? result) async {
    if (result == null || _activeProvider == null) return;
    final provider = _activeProvider!;
    if (provider.minBalance != null &&
        result.remaining < provider.minBalance!) {
      final lastTime = await StorageService.loadLastNotifyTime(provider.id);
      final now = DateTime.now().millisecondsSinceEpoch;
      const twelveHours = 12 * 60 * 60 * 1000;
      if (now - lastTime >= twelveHours) {
        await StorageService.saveLastNotifyTime(provider.id);
        await _showNotification(
          AppLocalizations.of('low_balance_title', {'name': provider.name}),
          AppLocalizations.of('low_balance_body', {
            'symbol': result.currencySymbol,
            'remaining': result.remaining.toStringAsFixed(2),
          }),
        );
      }
    }
  }

  Future<void> _showNotification(String title, String body) async {
    try {
      const details = NotificationDetails(
        macOS: DarwinNotificationDetails(),
      );
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Notification error: $e');
    }
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
      debugPrint('Tray title update error: $e');
    }
  }

  Future<void> _openSettings() async {
    await _showFullWindow();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsView()),
    );
    await _onRefreshRequested();
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
      debugPrint('Tray toggle error: $e');
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
    if (!Platform.isMacOS) return;
    await windowManager.hide();
    if (mounted) {
      setState(() {
        _isFullView = false;
      });
    }
  }

  @override
  void onWindowClose() async {
    _refreshTimer?.cancel();
    await windowManager.hide();
    if (mounted) {
      setState(() {
        _isFullView = false;
      });
    }
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey('$_localeCode$_themeMode'),
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      home: _activeProvider == null || _providers.isEmpty
          ? _buildEmptyState()
          : _isFullView
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

  Widget _buildEmptyState() {
    return Scaffold(
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
              AppLocalizations.of('no_providers'),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of('add_first'),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.faintText,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _openSettings,
              icon: Icon(
                Icons.settings_outlined,
                size: 16,
                color: AppColors.secondaryText,
              ),
              label: Text(
                AppLocalizations.of('settings'),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.hoverBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
