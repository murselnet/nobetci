'''
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:nobetci/services/notification_service.dart';
import 'package:nobetci/services/tflite_service.dart';
import 'package:camera/camera.dart';
import 'package:vibration/vibration.dart';

// Arka plan servisini başlatmak ve yapılandırmak için ana fonksiyon.
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // iOS ve Android için servis ayarlarını yapılandır.
  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false, // iOS'ta otomatik başlatma genellikle daha kısıtlıdır.
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      foregroundServiceNotificationId: 888, // Kalıcı bildirim için ID
      notificationChannelId: NotificationService.channelId, // Bildirim kanalı
      initialNotificationTitle: 'Güvenlik Servisi',
      initialNotificationContent: 'Servis başlatılıyor...',
    ),
  );
}

// iOS'ta arka plan modu için bir yer tutucu.
// Gerçek bir arka plan uygulaması için ek yapılandırma gerekir.
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// Servis başlatıldığında çalışacak olan ana fonksiyon.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // TFLite modelini yükleyecek servis
  final TFLiteService tfliteService = TFLiteService();
  await tfliteService.loadModel();

  // Kamera listesini al ve ilk kamerayı seç
  final cameras = await availableCameras();
  final camera = cameras.first;
  final imageStreamController = StreamController<CameraImage>();

  // Kamera kontrolcüsünü başlat
  final cameraController = CameraController(
    camera,
    ResolutionPreset.medium,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.yuv420,
  );

  await cameraController.initialize();
  // Kamera görüntüsünü bir stream olarak dinlemeye başla
  await cameraController.startImageStream((image) {
    if (!imageStreamController.isClosed) {
      imageStreamController.add(image);
    }
  });

  // Servis bir Android foreground servisi ise, bildirim içeriğini güncelle.
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      // Arka plana geçişte yapılacaklar (şimdilik boş)
    });
  }

  // Servisi durdurma komutunu dinle
  service.on('stopService').listen((event) {
    cameraController.stopImageStream();
    imageStreamController.close();
    service.stopSelf();
  });

  // Kamera görüntüsü stream'ini dinle ve analiz yap
  imageStreamController.stream.listen((CameraImage image) async {
    final results = await tfliteService.runModelOnFrame(image);

    // Sonuçları UI'a gönder
    service.invoke('update', {"detections": results});

    // İnsan tespit edilip edilmediğini kontrol et
    final bool personDetected = results.any((element) => element['label'] == 'person');

    if (personDetected) {
      // Cihazı titret
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }
      // Bildirim gönder
      NotificationService.showNotification(
        title: 'İnsan Tespit Edildi!',
        body: 'Kamera bir veya daha fazla insan tespit etti.',
      );
    }
  });

  // Servisin çalıştığını belirten periyodik bildirim
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Güvenlik Gözlemi Aktif",
          content: "Uygulama arka planda çalışıyor. Gözlem devam ediyor.",
        );
      }
    }
  });
}
'''
