'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../viewmodels/detection_viewmodel.dart';
import '../utils/bounding_box_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      // Cihazda kamera yoksa kullanıcıyı bilgilendir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu cihazda kullanılabilir kamera bulunamadı.')),
      );
      return;
    }

    final firstCamera = cameras.first;
    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      // ViewModel'a kamera önizleme boyutunu bildir
      final size = _cameraController!.value.previewSize ?? const Size(300, 300);
      context.read<DetectionViewModel>().setImageSize(size);

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Kamera başlatılırken hata: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik Kamerası'),
      ),
      body: Consumer<DetectionViewModel>(
        builder: (context, viewModel, child) {
          if (!_isCameraInitialized || _cameraController == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Gözetleme aktif değilse sadece kamera önizlemesini göster
          if (!viewModel.isDetecting) {
            return Center(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            );
          }

          // Gözetleme aktif ise, kamera önizlemesi ve çizimi üst üste koy
          return Stack(
            fit: StackFit.expand,
            children: [
              // Kamera Önizlemesi
              Center(
                child: AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              ),
              // Tespit Kutularını Çizen Katman
              CustomPaint(
                painter: BoundingBoxPainter(
                  detections: viewModel.detections,
                  imageSize: viewModel.imageSize,
                  screenSize: MediaQuery.of(context).size, // Ekranın tam boyutunu al
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<DetectionViewModel>(
        builder: (context, viewModel, child) {
          return FloatingActionButton.extended(
            onPressed: () {
              viewModel.toggleDetection();
            },
            icon: Icon(viewModel.isDetecting ? Icons.stop : Icons.play_arrow),
            label: Text(viewModel.isDetecting ? 'Gözlemlemeyi Durdur' : 'Gözlemlemeyi Başlat'),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
'''