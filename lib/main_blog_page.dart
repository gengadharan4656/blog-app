// ✅ Final MainBlogPage with Infinite Scroll, Pull to Refresh, Category Filter & Search

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
  String selectedCategory = '';
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  File? imageFile;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchBlogs(reset: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300 && !isLoading && hasMore) {
        fetchBlogs();
      }
    });
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

  Future<void> fetchBlogs({bool reset = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    if (reset) {
      blogs.clear();
      currentPage = 1;
      hasMore = true;
    }

    final url = Uri.parse(
        "https://blog-app-k878.onrender.com/search?q=${Uri.encodeComponent(searchQuery)}&category=${Uri.encodeComponent(selectedCategory)}&page=$currentPage&user_id=${widget.userId}"
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> combinedBlogs = [...(data['predefined'] ?? []), ...(data['user'] ?? [])];

        if (combinedBlogs.isEmpty) {
          hasMore = false;
        } else {
          setState(() {
            blogs.addAll(combinedBlogs);
            currentPage++;
          });
        }
      } else {
        hasMore = false;
      }
    } catch (e) {
      print('Error fetching blogs: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void onSearch(String query) {
    setState(() {
      searchQuery = query;
      selectedCategory = '';
    });
    fetchBlogs(reset: true);
  }

  void onSelectCategory(String cat) {
    setState(() {
      selectedCategory = cat;
      searchController.clear();
      searchQuery = '';
    });
    fetchBlogs(reset: true);
  }

  Future<void> deleteBlog(String blogId) async {
    final url = Uri.parse("https://blog-app-k878.onrender.com/delete_blog");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'blog_id': blogId, 'user_id': widget.userId}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Blog deleted")));
      fetchBlogs(reset: true);
    }
  }

  Future<void> toggleLike(String blogId, int index) async {
    final url = Uri.parse("https://blog-app-k878.onrender.com/like_blog");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'blog_id': blogId, 'user_id': widget.userId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        blogs[index]['liked'] = data['liked'];
        blogs[index]['likes'] = data['like_count'];
      });
    }
  }

  Future<void> handlePullToRefresh() async {
    await fetchBlogs(reset: true);
  }

  void showUploadDialog() {
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
                if (title.isEmpty || content.isEmpty || category.isEmpty) return;

                final uri = Uri.parse("https://blog-app-k878.onrender.com/submit_blog");
                final request = http.MultipartRequest('POST', uri);
                request.fields['user_id'] = widget.userId;
                request.fields['title'] = title;
                request.fields['content'] = content;
                request.fields['category'] = category;
                if (imageFile != null) {
                  request.files.add(await http.MultipartFile.fromPath('thumbnail', imageFile!.path));
                }
                final response = await request.send();
                if (response.statusCode == 200) {
                  Navigator.pop(ctx);
                  fetchBlogs(reset: true);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploaded")));
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
      appBar: AppBar(title: const Text("Facts and Blogs"), actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(child: Text("User ID: ${widget.userId}")),
        )
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: showUploadDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(cat),
                    onPressed: () => onSelectCategory(cat),
                    backgroundColor: selectedCategory == cat ? Colors.blue.shade100 : null,
                  ),
                )).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search blogs...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: onSearch,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: handlePullToRefresh,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: blogs.length + 1,
                itemBuilder: (context, index) {
                  if (index == blogs.length) {
                    return isLoading ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())) : const SizedBox();
                  }

                  final blog = blogs[index];
                  final blogImage = (blog['thumbnail'] ?? '').toString().trim().isNotEmpty
                      ? 'https://blog-app-k878.onrender.com/uploads/${blog['thumbnail']}'
                      : 'https://via.placeholder.com/300x200.png?text=No+Image';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(blogImage, height: 180, width: double.infinity, fit: BoxFit.cover),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(blog['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 6),
                              Text(
                                (blog['content']?.toString().length ?? 0) > 100
                                    ? blog['content'].toString().substring(0, 100) + '...'
                                    : blog['content'],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("By ${blog['username'] ?? 'Anonymous'}", style: const TextStyle(color: Colors.black54)),
                                  Row(children: [
                                    const Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
                                    Text(" ${blog['views'] ?? 0}"),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => toggleLike(blog['id'].toString(), index),
                                      child: Icon(
                                        blog['liked'] == true ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.red,
                                      ),
                                    ),
                                    Text(" ${blog['likes'] ?? 0}"),
                                    if ('${blog['user_id']}' == widget.userId)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => deleteBlog(blog['id'].toString()),
                                      ),
                                  ])
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
