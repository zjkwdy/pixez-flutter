import 'package:bot_toast/bot_toast.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show ColorScheme;
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pixez/constants.dart';
import 'package:pixez/fluent/page/splash/splash_page.dart';
import 'package:pixez/fluent/platform/platform.dart';
import 'package:pixez/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

late WindowEffect _effect;

initFluent(List<String> args) async {
  if (!Constants.isFluent) return;

  final dbPath = await getDBPath();
  if (dbPath != null) databaseFactory.setDatabasesPath(dbPath);

  // Must add this line.
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      center: true,
      skipTaskbar: false,
      minimumSize: const Size(350, 600),
    ),
    () async {
      await Window.initialize();

      _effect = await getEffect();
      await windowManager.show();
      await windowManager.focus();
    },
  );
}

Widget buildFluentUI(BuildContext context) {
  if (!Constants.isFluent) return Container();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));
  final botToastBuilder = BotToastInit();

  return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
    return Observer(builder: (context) {
      ColorScheme lightColorScheme;
      ColorScheme darkColorScheme;
      if (userSetting.useDynamicColor &&
          lightDynamic != null &&
          darkDynamic != null) {
        lightColorScheme = lightDynamic.harmonized();
        darkColorScheme = darkDynamic.harmonized();
      } else {
        Color primary = userSetting.seedColor;
        lightColorScheme = ColorScheme.fromSeed(
          seedColor: primary,
        );
        darkColorScheme = ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        );
      }

      final isDark = switch (userSetting.themeMode) {
        ThemeMode.dark => true,
        ThemeMode.system =>
          MediaQuery.platformBrightnessOf(context) == Brightness.dark,
        ThemeMode.light => false,
      };

      debugPrint("背景特效: $_effect; 暗色主题: $isDark;");
      Window.setEffect(effect: _effect, dark: isDark);
      final focusTheme = FocusThemeData(
        glowFactor: is10footScreen(context) ? 2.0 : 0.0,
      );

      if (userSetting.themeInitState != 1) {
        return FluentTheme(
          data: isDark ? FluentThemeData.dark() : FluentThemeData.light(),
          child: Container(
            child: Center(child: ProgressRing()),
          ),
        );
      }

      return FluentApp(
        navigatorObservers: [
          BotToastNavigatorObserver(),
          routeObserver,
        ],
        locale: userSetting.locale,
        home: Builder(builder: (context) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              statusBarColor: Colors.transparent,
            ),
            child: SplashPage(),
          );
        }),
        title: 'PixEz',
        builder: (context, child) {
          child = botToastBuilder(context, child);
          return Directionality(
            textDirection: TextDirection.ltr,
            child: child,
          );
        },
        themeMode: userSetting.themeMode,
        theme: FluentThemeData.light().copyWith(
          visualDensity: VisualDensity.standard,
          accentColor: lightColorScheme.primary.toAccentColor(),
          scaffoldBackgroundColor: lightColorScheme.surface,
          cardColor: lightColorScheme.surfaceContainer,
          focusTheme: focusTheme,
          navigationPaneTheme: _effect != WindowEffect.disabled
              ? NavigationPaneThemeData(
                  highlightColor: lightColorScheme.primary,
                  backgroundColor: Colors.transparent,
                )
              : null,
        ),
        darkTheme: FluentThemeData.dark().copyWith(
          visualDensity: VisualDensity.standard,
          accentColor: darkColorScheme.primary.toAccentColor(),
          scaffoldBackgroundColor: userSetting.isAMOLED ? Colors.black : null,
          cardColor: darkColorScheme.surfaceContainer,
          focusTheme: focusTheme,
          navigationPaneTheme: _effect != WindowEffect.disabled
              ? NavigationPaneThemeData(
                  highlightColor: darkColorScheme.primary,
                  backgroundColor: Colors.transparent,
                )
              : null,
        ),
        localizationsDelegates: [
          _FluentLocalizationsDelegate(),
          ...AppLocalizations.localizationsDelegates
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      );
    });
  });
}

class _FluentLocalizationsDelegate
    extends LocalizationsDelegate<FluentLocalizations> {
  const _FluentLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<FluentLocalizations> load(Locale locale) {
    return FluentLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<FluentLocalizations> old) {
    return false;
  }
}
