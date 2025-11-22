import 'package:flutter/material.dart';
import 'splash_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<UserModel>('users');

  runApp(const WeatherNewsApp());
}

class WeatherNewsApp extends StatelessWidget {
  const WeatherNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeatherNews',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
