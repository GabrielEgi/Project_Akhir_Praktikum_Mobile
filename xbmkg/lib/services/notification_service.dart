import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class WeatherNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ---------------------------------------------------
  // INITIALIZE NOTIFICATION
  // ---------------------------------------------------
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await _plugin.initialize(settings);
  }

  // ---------------------------------------------------
  // PERMISSION (ANDROID 13++)
  // ---------------------------------------------------
  static Future<bool> requestPermission() async {
    final bool granted = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;

    return granted;
  }

  // ---------------------------------------------------
  // SHOW NORMAL WEATHER NOTIFICATION
  // ---------------------------------------------------
  static Future<void> showWeatherAlert({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'weather_channel',
      'Weather Alert',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      1,
      title,
      body,
      platformDetails,
    );
  }
}
