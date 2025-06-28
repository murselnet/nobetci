'''
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern: Bu sınıftan sadece bir tane örnek oluşturulmasını sağlar.
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'nobetci_channel';
  static const String channelName = 'Güvenlik Uyarıları';
  static const String channelDescription = 'İnsan tespiti ve diğer güvenlik uyarıları için kanal.';

  // Bildirim servisini başlatan statik metod.
  static Future<void> initialize() async {
    // Android için başlatma ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Uygulama ikonu

    // iOS için başlatma ayarları (şimdilik temel düzeyde)
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _instance._notificationsPlugin.initialize(initializationSettings);

    // Android bildirim kanalını oluştur
    await _createNotificationChannel();
  }

  // Android 8.0 ve üzeri için bildirim kanalı oluşturan özel metod.
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max, // Bildirimin görünürlüğü ve önceliği
      playSound: true,
      enableVibration: true,
    );

    await _instance._notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Bildirim gösteren ana metod.
  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _instance._notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
'''