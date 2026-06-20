import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'dart:typed_data';

class OCRResult {
  final String text;
  OCRResult(this.text);
}

class OCRBottomSheet extends StatefulWidget {
  final String promptContext;

  const OCRBottomSheet({
    super.key,
    this.promptContext =
        "Extract the handwriting text from this image. Return only the extracted text, no other comments.",
  });

  @override
  State<OCRBottomSheet> createState() => _OCRBottomSheetState();
}

class _OCRBottomSheetState extends State<OCRBottomSheet> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (kIsWeb && source == ImageSource.gallery) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.bytes != null) {
          _processImageWeb(result.files.single.bytes!);
        }
      } else {
        final XFile? pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          if (kIsWeb) {
            final bytes = await pickedFile.readAsBytes();
            _processImageWeb(bytes);
          } else {
            _processImage(File(pickedFile.path));
          }
        }
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _processImageWeb(Uint8List imageBytes) async {
    setState(() => _isLoading = true);
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.1-flash-lite',
      );
      final prompt = TextPart(widget.promptContext);
      final imagePart = InlineDataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      if (mounted) {
        Navigator.pop(context, OCRResult(response.text ?? ''));
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('429') ||
          errorStr.contains('quota') ||
          errorStr.contains('limit') ||
          errorStr.contains('exhausted')) {
        _showError(
          'Limit AI / Kuota API tercapai. Silakan coba beberapa saat lagi.',
        );
      } else {
        _showError('Error OCR: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() => _isLoading = true);
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.1-flash-lite',
      );

      final imageBytes = await imageFile.readAsBytes();
      final prompt = TextPart(widget.promptContext);
      final imagePart = InlineDataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      if (mounted) {
        Navigator.pop(context, OCRResult(response.text ?? ''));
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('429') ||
          errorStr.contains('quota') ||
          errorStr.contains('limit') ||
          errorStr.contains('exhausted')) {
        _showError(
          'Limit AI / Kuota API tercapai. Silakan coba beberapa saat lagi.',
        );
      } else {
        _showError('Error OCR: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Scan Handwriting via AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _OptionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _OptionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
