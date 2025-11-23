import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'models/user_model.dart';
import 'models/earthquake_model.dart';
import 'models/weather_model.dart';
import 'models/weather_warning_model.dart';
import 'services/preferences_service.dart';
import 'services/local_storage_service.dart';
import 'providers/weather_provider.dart';
import 'providers/earthquake_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register all Hive adapters
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(EarthquakeModelAdapter());
  Hive.registerAdapter(WeatherWarningModelAdapter());
  Hive.registerAdapter(WeatherModelAdapter());
  Hive.registerAdapter(WeatherDataAdapter());

  // Open all Hive boxes
  await Hive.openBox<UserModel>('users');
  await Hive.openBox<EarthquakeModel>(LocalStorageService.earthquakeBox);
  await Hive.openBox<WeatherModel>(LocalStorageService.weatherBox);
  await Hive.openBox<WeatherWarningModel>(LocalStorageService.warningBox);
  await Hive.openBox<String>(LocalStorageService.favoritesBox);

  // Initialize Preferences
  await PreferencesService.init();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  runApp(const WeatherNewsApp());
}

class WeatherNewsApp extends StatelessWidget {
  const WeatherNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => EarthquakeProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WeatherNews',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const SplashPage(),
      ),
    );
  }
}
