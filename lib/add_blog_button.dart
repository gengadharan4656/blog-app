import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class AddBlogButton extends StatefulWidget {
  const AddBlogButton({super.key});

  @override
  State<AddBlogButton> createState() => _AddBlogButtonState();
}

class _AddBlogButtonState extends State<AddBlogButton> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imageName;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = path.basename(picked.name);
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

    if (title.isEmpty || content.isEmpty || (_imageFile == null && _imageBytes == null)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and add a thumbnail")),
      );
      return;
    }

    final uri = Uri.parse('http://192.168.15.171:5000/submit_blog');
    var request = http.MultipartRequest('POST', uri)
      ..fields['title'] = title
      ..fields['content'] = content;

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'thumbnail',
        _imageFile!.path,
        filename: _imageName,
      ));
    } else if (_imageBytes != null && _imageName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'thumbnail',
        _imageBytes!,
        filename: _imageName,
      ));
    }

    final response = await request.send();
    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Blog submitted successfully")),
      );
      titleController.clear();
      contentController.clear();
      setState(() {
        _imageFile = null;
        _imageBytes = null;
        _imageName = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit blog")),
      );
    }
  }

  Widget imagePreview() {
    if (_imageFile != null) {
      return Image.file(_imageFile!, height: 150);
    } else if (_imageBytes != null) {
      return Image.memory(_imageBytes!, height: 150);
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Blog")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                maxLines: 6,
                decoration: const InputDecoration(labelText: "Content"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Pick Image"),
                onPressed: pickImage,
              ),
              const SizedBox(height: 10),
              imagePreview(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("Submit Blog"),
                onPressed: submitBlog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
