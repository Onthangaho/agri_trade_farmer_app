// lib/main.dart
/// App bootstrap for AgriTrade with providers, theme, localization, routing, and background sync.

import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:workmanager/workmanager.dart';

import 'core/theme/app_theme.dart';
import 'core/services/sync_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/crops/presentation/providers/crop_provider.dart';
import 'features/farms/presentation/providers/farm_provider.dart';
import 'features/marketplace/presentation/providers/marketplace_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'firebase_options.dart';
import 'injection.dart' as di;
import 'routes/app_router.dart';
import 'routes/route_names.dart';
import 'shared/providers/connectivity_provider.dart';
import 'shared/providers/sync_provider.dart';
import 'shared/providers/theme_provider.dart';

const String _backgroundSyncTaskName = 'agritrade_background_sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await di.setupServiceLocator();
    final SyncService syncService = di.getIt<SyncService>();
    await syncService.syncAllPending();
    return Future<bool>.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.setupServiceLocator();
  if (!kIsWeb) {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    await Workmanager().registerPeriodicTask(
      _backgroundSyncTaskName,
      _backgroundSyncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const AgriTradeApp());
}

class AgriTradeApp extends StatelessWidget {
  const AgriTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<SyncProvider>(
          create: (_) => di.getIt<SyncProvider>(),
        ),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(
            connectivityService: di.getIt(),
            syncService: di.getIt(),
            syncProvider: di.getIt(),
          ),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => di.getIt<ThemeProvider>(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<CropProvider>(
          create: (_) => di.getIt<CropProvider>(),
        ),
        ChangeNotifierProvider<MarketplaceProvider>(
          create: (_) => di.getIt<MarketplaceProvider>(),
        ),
        ChangeNotifierProvider<FarmProvider>(
          create: (_) => di.getIt<FarmProvider>(),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => di.getIt<ProfileProvider>(),
        ),
      ],
      child: Builder(
        builder: (BuildContext context) {
          final ThemeProvider themeProvider = context.watch<ThemeProvider>();
          return MaterialApp(
            title: 'AgriTrade',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: RouteNames.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
            supportedLocales: const <Locale>[
              Locale('en'),
              Locale('zu', 'ZA'),
            ],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
