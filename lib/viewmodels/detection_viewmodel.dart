'''
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class DetectionViewModel extends ChangeNotifier {
  final FlutterBackgroundService _service = FlutterBackgroundService();

  bool _isDetecting = false;
  bool get isDetecting => _isDetecting;

  List<Map<String, dynamic>> _detections = [];
  List<Map<String, dynamic>> get detections => _detections;

  Size _imageSize = Size.zero;
  Size get imageSize => _imageSize;

  DetectionViewModel() {
    // Arka plan servisinden gelen 'update' mesajlarını dinle.
    _service.on('update').listen((event) {
      if (event != null && event.containsKey('detections')) {
        _detections = List<Map<String, dynamic>>.from(event['detections']);
        // Görüntü boyutu henüz ayarlanmadıysa, varsayılan bir boyut ata.
        // Gerçek boyut HomeScreen'de kamera başlatıldığında ayarlanacak.
        if (_imageSize == Size.zero) {
          _imageSize = const Size(300, 300); // Modelin giriş boyutuna göre varsayılan
        }
        notifyListeners(); // UI'ı güncellemek için dinleyicileri bilgilendir.
      }
    });
  }

  // Gözetlemeyi başlatma ve durdurma fonksiyonu
  void toggleDetection() {
    _isDetecting = !_isDetecting;
    if (_isDetecting) {
      startService();
    } else {
      stopService();
    }
    notifyListeners();
  }

  // Arka plan servisini başlatır
  void startService() {
    _service.startService();
    _service.invoke("setAsForeground");
  }

  // Arka plan servisini durdurur
  void stopService() {
    _service.invoke("stopService");
    _detections = []; // Tespitleri temizle
  }

  // Kamera önizlemesinin boyutunu ayarlamak için kullanılır.
  // Bu, tespit kutularının doğru koordinatlarda çizilmesi için gereklidir.
  void setImageSize(Size size) {
    _imageSize = size;
    notifyListeners();
  }
}
'''