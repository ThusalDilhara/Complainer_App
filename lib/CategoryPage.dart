import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final List<String> _categories = const [
    'Electrical',
    'Plumbing',
    'Cleaning',
    'Security',
    'Other',
  ];

  String? _selected;
  File? _imageFile;
  String? _fileName;
  bool _isUploading = false;

  String _todayDateStamp() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _takePhoto() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked == null) return;

    // Generate file name: [YYYY-MM-DD]_[SelectedOption]_0.jpg
    final timestamp = _todayDateStamp();
    final option = (_selected ?? 'Other').trim().replaceAll(' ', '');
    final fileName = '${timestamp}_${option}_0.jpg';

    // Compress image
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/$fileName';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      targetPath,
      quality: 60,
    );

    if (compressed != null) {
      setState(() {
        _imageFile = File(compressed.path);
        _fileName = fileName;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image compression failed')),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_imageFile == null || _fileName == null || _selected == null) {
      return;
    }

    try {
      setState(() => _isUploading = true);

      // Convert file to Base64 string
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Firestore document
      await FirebaseFirestore.instance.collection('complaints').add({
        'fileName': _fileName,
        'category': _selected,
        'imageData': base64Image,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complaint submitted successfully!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset UI
      setState(() {
        _imageFile = null;
        _fileName = null;
        _selected = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageFile != null;
    final canAct = _selected != null && !_isUploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Submit Complaint',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white, // keep text white for contrast
          ),
        ),
        centerTitle: true,
        elevation: 4, // subtle shadow for depth
        backgroundColor: Color(0xFF1565C0), // a nice deep blue
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Please Select a category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),

              // Category list
              Expanded(
                child: ListView.separated(
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selected == category;
                    return InkWell(
                      onTap: () => setState(() => _selected = category),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Preview + filename + actions
              if (_imageFile != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'File: ${_fileName ?? ''}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Action row for cancel / retake
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                          _fileName = null;
                          _selected = null;
                        });
                      },
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text("Cancel"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Retake"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Upload progress
              if (_isUploading) const LinearProgressIndicator(),

              // Action button (Take Photo / Upload Photo)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: Icon(
                    hasImage
                        ? Icons.cloud_upload_outlined
                        : Icons.camera_alt_outlined,
                  ),
                  label: Text(hasImage ? 'Upload Photo' : 'Take Photo'),
                  onPressed: !canAct
                      ? null
                      : (hasImage ? _uploadPhoto : _takePhoto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
