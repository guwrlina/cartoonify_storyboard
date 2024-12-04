import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cartoonized Storyboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _controller;
  late List<CameraDescription> cameras;
  late CameraDescription firstCamera;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.medium);
    await _controller.initialize();
    setState(() {});
  }

  // Capture image from camera
  Future<void> captureAndCartoonize() async {
    if (isProcessing) return; // Prevent multiple requests

    setState(() {
      isProcessing = true;
    });

    try {
      final image = await _controller.takePicture();
      await uploadImage(image);
    } catch (e) {
      print('Error capturing image: $e');
      setState(() {
        isProcessing = false;
      });
    }
  }

  // Upload the captured image to the backend
  Future<void> uploadImage(XFile image) async {
    final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'http://192.168.1.100:5000/cartoonize')); // Replace with your backend URL
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      var responseBytes = await response.stream.toBytes();
      setState(() {
        // Display the cartoonized image
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Image.memory(Uint8List.fromList(responseBytes)),
          ),
        );
      });
    } else {
      print('Failed to cartoonize image');
      setState(() {
        isProcessing = false;
      });
    }
  }

  // Pick an image from the gallery
  Future<void> pickImageAndCartoonize() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await uploadImage(XFile(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Livestream Cartoonization')),
      body: Stack(
        children: [
          CameraPreview(_controller),
          Positioned(
            bottom: 30,
            left: 30,
            child: ElevatedButton(
              onPressed: captureAndCartoonize,
              child: Text('Capture & Cartoonize'),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: ElevatedButton(
              onPressed: pickImageAndCartoonize,
              child: Text('Pick Image'),
            ),
          ),
        ],
      ),
    );
  }
}
