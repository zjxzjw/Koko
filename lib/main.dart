import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'i18n/app_localizations.dart';
import 'models/provider_model.dart';
import 'providers/providers.dart';
import 'providers/settings_provider.dart';
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
    center: false,
    backgroundColor: Colors.white,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setResizable(false);
    await _restoreWindowPosition();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: BalanceMonitorApp()));
}

Future<void> _restoreWindowPosition() async {
  final x = await StorageService.loadWindowX();
  final y = await StorageService.loadWindowY();
  if (x != null && y != null) {
    try {
      await windowManager.setPosition(Offset(x, y));
    } catch (_) {}
  }
}

Future<void> _saveWindowPosition() async {
  try {
    final pos = await windowManager.getPosition();
    final size = await windowManager.getSize();
    await StorageService.saveWindowPosition(
      pos.dx, pos.dy, size.width, size.height,
    );
  } catch (_) {}
}

class BalanceMonitorApp extends ConsumerStatefulWidget {
  const BalanceMonitorApp({super.key});

  @override
  ConsumerState<BalanceMonitorApp> createState() => _BalanceMonitorAppState();
}

class _BalanceMonitorAppState extends ConsumerState<BalanceMonitorApp>
    with TrayListener, WindowListener {
  bool _isFullView = true;

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initTray();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initTray() async {
    final iconPath = Platform.isWindows
        ? 'assets/app_icon.ico'
        : 'assets/tray_icon.png';
    try {
      await trayManager.setIcon(iconPath);
    } catch (e) {
      debugPrint('Tray setIcon error: $e');
    }
    try {
      await trayManager.setToolTip(AppLocalizations.of('balance_monitor'));
    } catch (e) {
      debugPrint('Tray setToolTip error: $e');
    }
  }

  void _updateTrayTitle(BalanceResult? result) {
    final provider = ref.read(activeProviderProvider);
    if (provider == null) return;

    if (result != null) {
      final sym = result.currencySymbol;
      try {
        trayManager.setTitle(
          '${provider.name} $sym ${result.remaining.toStringAsFixed(2)}',
        );
      } catch (e) {
        debugPrint('Tray title error: $e');
      }
      try {
        trayManager.setToolTip(
          AppLocalizations.of('balance_monitor_long', {
            'name': provider.name,
            'symbol': sym,
            'remaining': result.remaining.toStringAsFixed(2),
            'used': result.used.toStringAsFixed(2),
          }),
        );
      } catch (e) {
        debugPrint('Tray tooltip error: $e');
      }
    }
  }

  Future<void> _checkLowBalanceNotification(BalanceResult? result) async {
    final provider = ref.read(activeProviderProvider);
    if (result == null || provider == null) return;
    if (provider.minBalance != null &&
        result.remaining < provider.minBalance!) {
      final lastTime = await StorageService.loadLastNotifyTime(provider.id);
      final now = DateTime.now().millisecondsSinceEpoch;
      const twelveHours = 12 * 60 * 60 * 1000;
      if (now - lastTime >= twelveHours) {
        await StorageService.saveLastNotifyTime(provider.id);
        try {
          const details = NotificationDetails(
            macOS: DarwinNotificationDetails(),
          );
          await _notifications.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            AppLocalizations.of('low_balance_title', {'name': provider.name}),
            AppLocalizations.of('low_balance_body', {
              'symbol': result.currencySymbol,
              'remaining': result.remaining.toStringAsFixed(2),
            }),
            details,
          );
        } catch (e) {
          debugPrint('Notification error: $e');
        }
      }
    }
  }

  Future<void> _openSettings() async {
    await _showFullWindow();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsView()),
    );
  }

  Future<void> _showTrayPopup() async {
    await windowManager.setSize(_kPopupSize);
    if (mounted) {
      setState(() => _isFullView = false);
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
      setState(() => _isFullView = true);
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
    _saveWindowPosition();
    await windowManager.hide();
    if (mounted) {
      setState(() => _isFullView = false);
    }
  }

  @override
  void onWindowClose() async {
    _saveWindowPosition();
    await windowManager.hide();
    if (mounted) {
      setState(() => _isFullView = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = ref.watch(localeSettingProvider).asData?.value ?? 'en';
    final themeModeStr =
        ref.watch(themeModeSettingProvider).asData?.value ?? 'system';
    final themeMode = _parseThemeMode(themeModeStr);
    final activeProvider = ref.watch(activeProviderProvider);
    ref.watch(balanceProvider);

    ref.listen(balanceProvider, (_, next) {
      next.whenOrNull(data: (data) {
        _updateTrayTitle(data);
        _checkLowBalanceNotification(data);
      });
    });

    return MaterialApp(
      key: ValueKey('$localeCode$themeModeStr'),
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light, AppColors.light),
      darkTheme: _buildTheme(Brightness.dark, AppColors.dark),
      themeMode: themeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: activeProvider == null
            ? _buildEmptyState()
            : _isFullView
                ? DashboardView(key: const ValueKey('full'))
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .scale(
                      begin: const Offset(0.97, 0.97),
                      end: const Offset(1, 1),
                      duration: 200.ms,
                      curve: Curves.easeOut,
                    )
                : TrayPopupView(
                    key: const ValueKey('popup'),
                    onOpenFullWindow: _showFullWindow,
                  ).animate().fadeIn(duration: 200.ms),
      ),
    );
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

  ThemeData _buildTheme(Brightness brightness, AppColors colors) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) {
        final colors = AppColors.of(context);
        return Scaffold(
          backgroundColor: colors.background,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.dns_outlined,
                  size: 48,
                  color: colors.subtleText,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of('no_providers'),
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of('add_first'),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.faintText,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: _openSettings,
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 16,
                    color: colors.secondaryText,
                  ),
                  label: Text(
                    AppLocalizations.of('settings'),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.secondaryText,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: colors.hoverBg,
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
      },
    );
  }
}
