// Updated MainBlogPage.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MainBlogPage extends StatefulWidget {
  final String userId;
  const MainBlogPage({super.key, required this.userId});

  @override
  State<MainBlogPage> createState() => _MainBlogPageState();
}

class _MainBlogPageState extends State<MainBlogPage> {
  List<dynamic> blogs = [];
  List<String> categories = [];
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  File? imageFile;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchBlogs();
  }

  Future<void> fetchBlogs() async {
    final url = Uri.parse("https://blog-app-k878.onrender.com/search?q=${Uri.encodeComponent(searchQuery)}&user_id=${widget.userId}");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predefined = List<Map<String, dynamic>>.from(data['predefined'] ?? []);
        final userBlogs = List<Map<String, dynamic>>.from(data['user'] ?? []);
        final combinedBlogs = [...predefined, ...userBlogs];

        combinedBlogs.sort((a, b) {
          final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          return bDate.compareTo(aDate);
        });

        setState(() => blogs = combinedBlogs);
      } else {
        setState(() => blogs = []);
      }
    } catch (e) {
      print('Error fetching blogs: $e');
      setState(() => blogs = []);
    }
  }

  Future<void> fetchCategories() async {
    final url = Uri.parse("https://blog-app-k878.onrender.com/categories");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<String> data = List<String>.from(json.decode(response.body));
        setState(() => categories = data);
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void onSearch(String query) {
    setState(() => searchQuery = query);
    fetchBlogs();
  }

  void deleteBlog(String blogId) async {
    final response = await http.delete(
      Uri.parse('https://blog-app-k878.onrender.com/delete_blog/$blogId'),
    );
    if (response.statusCode == 200) {
      fetchBlogs();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Blog deleted")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete blog")));
    }
  }

  void showUploadDialog(BuildContext context, VoidCallback onUploadComplete) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Upload Blog"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  keyboardType: TextInputType.multiline,
                  minLines: 5,
                  maxLines: 8,
                ),
                const SizedBox(height: 10),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() => imageFile = File(picked.path));
                    }
                  },
                  child: const Text("Pick Thumbnail (Optional)"),
                ),
                if (imageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(imageFile!.path.split('/').last, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final content = contentController.text.trim();
                final category = categoryController.text.trim();

                if (title.isEmpty || content.isEmpty || category.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                  return;
                }

                final uri = Uri.parse("https://blog-app-k878.onrender.com/submit_blog");
                final request = http.MultipartRequest('POST', uri);

                request.fields['user_id'] = widget.userId;
                request.fields['title'] = title;
                request.fields['content'] = content;
                request.fields['category'] = category;

                if (imageFile != null) {
                  request.files.add(await http.MultipartFile.fromPath('thumbnail', imageFile!.path));
                }

                try {
                  final response = await request.send();
                  if (response.statusCode == 200) {
                    Navigator.pop(ctx);
                    onUploadComplete();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Blog uploaded successfully")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed (\${response.statusCode})")));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: \$e")));
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facts and Blogs'),
        backgroundColor: Colors.blue,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(child: Text("User ID: ${widget.userId}", style: const TextStyle(fontSize: 14))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showUploadDialog(context, fetchBlogs),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(label: Text(cat), onPressed: () => onSearch(cat)),
                )).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search blogs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onSubmitted: onSearch,
            ),
          ),
          Expanded(
            child: blogs.isEmpty
                ? const Center(child: Text("No blogs found. Try exploring suggestions above!"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: blogs.length,
                    itemBuilder: (context, index) {
                      final blog = blogs[index];
                      final blogImage = blog['thumbnail'] != null && blog['thumbnail'].toString().isNotEmpty
                          ? 'https://blog-app-k878.onrender.com/uploads/${blog['thumbnail']}'
                          : 'https://via.placeholder.com/300x200.png?text=Default+Thumbnail';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(blogImage, height: 180, width: double.infinity, fit: BoxFit.cover),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(blog['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text(
                                    (blog['content']?.toString().length ?? 0) > 100
                                        ? blog['content']!.toString().substring(0, 100) + '...'
                                        : blog['content'],
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Chip(label: Text(blog['category'] ?? 'Other'), backgroundColor: Colors.blue.shade50),
                                    Row(children: [
                                      Text("By ${blog['username'] ?? 'Anonymous'}", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${blog['views'] ?? 0}', style: const TextStyle(color: Colors.grey)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.favorite_border, size: 18, color: Colors.red),
                                      const SizedBox(width: 4),
                                      Text('${blog['likes'] ?? 0}', style: const TextStyle(color: Colors.grey)),
                                      if ('${blog['user_id']}' == widget.userId)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => deleteBlog(blog['id'].toString()),
                                        ),
                                    ])
                                  ])
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Founded by Genga Dharan', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
