'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'viewmodels/detection_viewmodel.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. İzinleri iste
  await requestPermissions();

  // 2. Servisleri başlat
  await NotificationService.initialize();
  await initializeBackgroundService();

  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  await Permission.camera.request();
  await Permission.notification.request();
  // Android 13 (API 33) ve sonrası için kesin alarm izni
  // Bu, uygulamanın arka planda kritik uyarılar gönderebilmesi için önemlidir.
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. ChangeNotifierProvider ile ViewModel'ı sağla
    return ChangeNotifierProvider(
      create: (context) => DetectionViewModel(),
      child: MaterialApp(
        title: 'Güvenlik Kamerası',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
''