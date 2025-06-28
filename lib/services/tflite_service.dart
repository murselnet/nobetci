'''
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';
import 'package:image/image.dart' as img;

class TFLiteService {
  late Interpreter _interpreter;
  late List<String> _labels;
  late ImageProcessor _imageProcessor;

  static const String modelPath = 'assets/ml/ssd_mobilenet.tflite';
  static const String labelsPath = 'assets/ml/labels.txt';

  // Modeli ve etiketleri yükleyen ana fonksiyon
  Future<void> loadModel() async {
    try {
      // Interpreter'ı oluştur ve modeli yükle
      _interpreter = await Interpreter.fromAsset(modelPath,
          options: InterpreterOptions()..threads = 4);

      // Etiket dosyasını yükle
      final labelsData = await FileUtil.loadLabels(labelsPath);
      _labels = labelsData;

      // Görüntü işlemciyi yapılandır
      _imageProcessor = ImageProcessorBuilder().build();
    } catch (e) {
      print("Model yüklenirken hata oluştu: $e");
    }
  }

  // Kamera görüntüsünü işleyip modeli çalıştıran fonksiyon
  Future<List<Map<String, dynamic>>> runModelOnFrame(CameraImage cameraImage) async {
    // Görüntüyü TFLite'ın anlayacağı formata dönüştür
    final tensorImage = await _preprocessImage(cameraImage);
    if (tensorImage == null) return [];

    // Modelin beklediği giriş ve çıkış tensör şekillerini al
    final inputTensor = _interpreter.getInputTensor(0);
    final outputBoundingBoxes = _interpreter.getOutputTensor(0);
    final outputClasses = _interpreter.getOutputTensor(1);
    final outputScores = _interpreter.getOutputTensor(2);
    final numDetections = _interpreter.getOutputTensor(3);

    // Çıkış verilerini tutacak buffer'ları oluştur
    final outputs = {
      0: List.filled(outputBoundingBoxes.shape.reduce((a, b) => a * b), 0.0)
          .reshape(outputBoundingBoxes.shape),
      1: List.filled(outputClasses.shape.reduce((a, b) => a * b), 0.0)
          .reshape(outputClasses.shape),
      2: List.filled(outputScores.shape.reduce((a, b) => a * b), 0.0)
          .reshape(outputScores.shape),
      3: List.filled(numDetections.shape.reduce((a, b) => a * b), 0.0)
          .reshape(numDetections.shape),
    };

    // Modeli çalıştır
    _interpreter.runForMultipleInputs([tensorImage.buffer.asUint8List()], outputs);

    // Sonuçları formatla
    final int count = outputs[3]![0][0].toInt();
    final List<Map<String, dynamic>> results = [];

    for (int i = 0; i < count; i++) {
      final score = outputs[2]![0][i];
      if (score > 0.5) { // Güven skoru %50'den yüksek olanları al
        final labelIndex = outputs[1]![0][i].toInt();
        final label = _labels[labelIndex];
        final boundingBox = outputs[0]![0][i];

        results.add({
          'confidence': score,
          'label': label,
          'rect': {
            'y': boundingBox[0],
            'x': boundingBox[1],
            'h': boundingBox[2] - boundingBox[0],
            'w': boundingBox[3] - boundingBox[1],
          }
        });
      }
    }
    return results;
  }

  // Kamera görüntüsünü (YUV420) RGB formatına çeviren ve boyutlandıran fonksiyon
  Future<TensorImage?> _preprocessImage(CameraImage cameraImage) async {
    try {
      final conversionStopwatch = Stopwatch()..start();
      final image = await convertYUV420ToImage(cameraImage);
      conversionStopwatch.stop();
      print('YUV->RGB dönüşüm süresi: ${conversionStopwatch.elapsedMilliseconds}ms');

      if (image == null) return null;

      final shape = _interpreter.getInputTensor(0).shape;
      final inputHeight = shape[1];
      final inputWidth = shape[2];

      // Görüntüyü modelin istediği boyuta getir
      final resizedImage = img.copyResize(image, width: inputWidth, height: inputHeight);

      // TensorImage oluştur
      final tensorImage = TensorImage.fromImage(resizedImage);
      return tensorImage;
    } catch (e) {
      print("Görüntü işlenirken hata: $e");
      return null;
    }
  }
}

// YUV_420 formatındaki bir görüntüyü Image formatına dönüştürmek için yardımcı fonksiyon.
// Bu fonksiyon, ana thread'i bloklamamak için bir Isolate üzerinde çalıştırılabilir.
Future<img.Image?> convertYUV420ToImage(CameraImage cameraImage) async {
  final width = cameraImage.width;
  final height = cameraImage.height;

  final yPlane = cameraImage.planes[0].bytes;
  final uPlane = cameraImage.planes[1].bytes;
  final vPlane = cameraImage.planes[2].bytes;

  final yuv420Data = Uint8List(width * height * 3 ~/ 2);

  // Y, U, V düzlemlerini tek bir byte dizisinde birleştir
  // Bu kısım Android'e özgüdür ve plane yapıları farklılık gösterebilir.
  int yIndex = 0;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      yuv420Data[yIndex++] = yPlane[y * cameraImage.planes[0].bytesPerRow + x];
    }
  }

  final uvWidth = width ~/ 2;
  final uvHeight = height ~/ 2;
  int uvIndex = width * height;

  for (int y = 0; y < uvHeight; y++) {
    for (int x = 0; x < uvWidth; x++) {
      final uIndex = y * cameraImage.planes[1].bytesPerRow + x * cameraImage.planes[1].bytesPerPixel!;
      final vIndex = y * cameraImage.planes[2].bytesPerRow + x * cameraImage.planes[2].bytesPerPixel!;
      yuv420Data[uvIndex++] = uPlane[uIndex];
      yuv420Data[uvIndex++] = vPlane[vIndex];
    }
  }

  // YUV'dan RGB'ye dönüştür
  return img.decodeYUV420SP(yuv420Data, width, height);
}
'''