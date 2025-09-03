import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<void> _takePhoto() async {
    // Request permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera permission denied')));
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked == null) return;

    // Generate file name
    final timestamp = DateTime.now().toIso8601String().split('T').first;
    final fileName = '${timestamp}_${_selected}_0.jpg';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Complaint'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select a category',
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

              // Preview image
              if (_imageFile != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'File: $_fileName',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],

              // Action button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take Photo'),
                  onPressed: _selected == null ? null : _takePhoto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
