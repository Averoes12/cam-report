import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:camreport/services/nine_router_service.dart';

class OCRPage extends StatefulWidget {
  const OCRPage({super.key});

  @override
  State<OCRPage> createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  File? _image;
  String _extractedText = '';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // No need for API key anymore as we use Firebase Vertex AI

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (kIsWeb && source == ImageSource.gallery) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _image = File(
              'dummy',
            ); // Dummy file to satisfy null check, we use bytes for web
            _extractedText = '';
          });
          _processImageWeb(result.files.single.bytes!);
        }
      } else {
        final XFile? pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          setState(() {
            _image = File(pickedFile.path);
            _extractedText = ''; // Clear previous text
          });
          if (kIsWeb) {
            final bytes = await pickedFile.readAsBytes();
            _processImageWeb(bytes);
          } else {
            _processImage();
          }
        }
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _processImageWeb(Uint8List imageBytes) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final text = await NineRouterService.instance.extractTextFromImage(
        imageBytes: imageBytes,
      );

      setState(() {
        _extractedText = text.isNotEmpty ? text : 'No text recognized.';
      });
    } catch (e) {
      _showError('Error during OCR: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final imageBytes = await _image!.readAsBytes();
      final text = await NineRouterService.instance.extractTextFromImage(
        imageBytes: imageBytes,
      );

      setState(() {
        _extractedText = text.isNotEmpty ? text : 'No text recognized.';
      });
    } catch (e) {
      _showError('Error during OCR: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handwriting OCR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image != null) ...[
              if (kIsWeb && _image?.path == 'dummy')
                const Text(
                  'Image selected (preview unavailable on web file picker)',
                ),
              if (kIsWeb && _image?.path != 'dummy')
                Image.network(_image!.path, height: 300, fit: BoxFit.contain),
              if (!kIsWeb)
                Image.file(_image!, height: 300, fit: BoxFit.contain),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_extractedText.isNotEmpty) ...[
              const Text(
                'Extracted Text:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(_extractedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
