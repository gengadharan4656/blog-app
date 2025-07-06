import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class SubmitBlogPage extends StatefulWidget {
  final String userId;
  const SubmitBlogPage({super.key, required this.userId});

  @override
  State<SubmitBlogPage> createState() => _SubmitBlogPageState();
}

class _SubmitBlogPageState extends State<SubmitBlogPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final categoryController = TextEditingController();

  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imageName;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = picked.name;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(picked.path);
          _imageName = path.basename(picked.path);
          _imageBytes = null;
        });
      }
    }
  }

  Future<void> submitBlog() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    final category = categoryController.text.trim();

    if (title.isEmpty || content.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final uri = Uri.parse('https://blog-app-k878.onrender.com/submit_blog');   

    final request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = widget.userId;
    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['category'] = category;

    if (_imageBytes != null && _imageName != null) {
      request.files.add(http.MultipartFile.fromBytes('thumbnail', _imageBytes!, filename: _imageName));
    } else if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('thumbnail', _imageFile!.path));
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Blog uploaded successfully")),
        );
        titleController.clear();
        contentController.clear();
        categoryController.clear();
        setState(() {
          _imageFile = null;
          _imageBytes = null;
          _imageName = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Upload failed (${response.statusCode})")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget imagePreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_imageFile!, height: 150),
      );
    } else if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_imageBytes!, height: 150),
      );
    } else {
      return const Text(
        "No image selected",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Blog")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                maxLines: 6,
                decoration: const InputDecoration(labelText: "Content"),
              ),
              const SizedBox(height: 10),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: "Category")),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Pick Thumbnail (Optional)"),
                onPressed: pickImage,
              ),
              const SizedBox(height: 12),
              imagePreview(),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("Submit Blog"),
                onPressed: submitBlog,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
