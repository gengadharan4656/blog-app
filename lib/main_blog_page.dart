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
  String? imageName;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchBlogs(reset: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !isLoading && hasMore) {
        fetchBlogs();
      }
    });
  }

  Future<void> fetchCategories() async {
    final url = Uri.parse("https://blog-app-k878.onrender.com/categories");
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final List<String> data = List<String>.from(json.decode(resp.body));
        setState(() => categories = data);
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> fetchBlogs({bool reset = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    if (reset) {
      currentPage = 1;
      hasMore = true;
      blogs.clear();
    }

    final url = Uri.parse(
      "https://blog-app-k878.onrender.com/search"
      "?q=${Uri.encodeComponent(searchQuery)}"
      "&category=${Uri.encodeComponent(selectedCategory)}"
      "&page=$currentPage"
      "&user_id=${widget.userId}"
    );

    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final List<dynamic> newBlogs = [
          ...(data['predefined'] ?? []),
          ...(data['user'] ?? [])
        ];

        if (newBlogs.isEmpty) {
          hasMore = false;
        } else {
          setState(() {
            blogs.addAll(newBlogs);
            currentPage++;
          });
        }
      } else {
        hasMore = false;
      }
    } catch (e) {
      debugPrint('Error fetching blogs: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteBlog(String blogId) async {
    final url = Uri.parse("https://blog-app-k878.onrender.com/delete_blog");
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'blog_id': blogId, 'user_id': widget.userId}),
    );
    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Blog deleted")));
      fetchBlogs(reset: true);
    }
  }

  Future<void> toggleLike(String blogId, int idx) async {
    final url = Uri.parse("https://blog-app-k878.onrender.com/like_blog");
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'blog_id': blogId, 'user_id': widget.userId}),
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      setState(() {
        blogs[idx]['liked'] = data['liked'];
        blogs[idx]['likes'] = data['like_count'];
      });
    }
  }

  Future<void> _pullToRefresh() async {
    await fetchBlogs(reset: true);
  }

  Future<void> pickImageForUpload(StateSetter st) async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) {
      st(() {
        imageFile = File(p.path);
        imageName = p.name;
      });
    }
  }

  void showUploadDialog() {
    final tC = TextEditingController();
    final cC = TextEditingController();
    final catC = TextEditingController();

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, st) {
        return AlertDialog(
          title: const Text('Upload Blog'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tC, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 10),
                TextField(controller: cC, decoration: const InputDecoration(labelText: 'Content'), minLines: 4, maxLines: 8),
                const SizedBox(height: 10),
                TextField(controller: catC, decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Thumbnail'),
                  onPressed: () => pickImageForUpload(st),
                ),
                const SizedBox(height: 8),
                if (imageName != null)
                  Text('Selected: $imageName', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () async {
              final title = tC.text.trim();
              final cont = cC.text.trim();
              final cat = catC.text.trim();
              if (title.isEmpty || cont.isEmpty || cat.isEmpty || imageFile == null) return;

              final uri = Uri.parse("https://blog-app-k878.onrender.com/submit_blog");
              final req = http.MultipartRequest('POST', uri)
                ..fields['user_id'] = widget.userId
                ..fields['title'] = title
                ..fields['content'] = cont
                ..fields['category'] = cat
                ..files.add(await http.MultipartFile.fromPath('thumbnail', imageFile!.path));

              final resp = await req.send();
              if (resp.statusCode == 200) {
                Navigator.pop(ctx);
                setState(() {
                  imageFile = null;
                  imageName = null;
                });
                fetchBlogs(reset: true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploaded")));
              }
            }, child: const Text('Submit')),
          ],
        );
      });
    });
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facts and Blogs'),
        actions: [ Padding(padding: const EdgeInsets.all(8), child: Center(child: Text('User: ${widget.userId}'))) ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: showUploadDialog, child: const Icon(Icons.add)),
      body: Column(
        children: [
          if (categories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (_) => setState(() {
                        selectedCategory = cat;
                        searchController.clear();
                        fetchBlogs(reset: true);
                      }),
                    ),
                  );
                }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search blogs...'),
              onSubmitted: (val) {
                setState(() {
                  searchQuery = val;
                  selectedCategory = '';
                });
                fetchBlogs(reset: true);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _pullToRefresh,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: blogs.length + 1,
                itemBuilder: (c,i){
                  if (i == blogs.length) {
                    return hasMore
                        ? const Center(child: Padding(p: EdgeInsets.all(16), child: CircularProgressIndicator()))
                        : const SizedBox();
                  }

                  final b = blogs[i];
                  final img = (b['thumbnail'] ?? '').toString().isNotEmpty
                      ? 'https://blog-app-k878.onrender.com/uploads/${b['thumbnail']}'
                      : 'https://via.placeholder.com/300x200.png?text=No+Image';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(img, height: 180, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['title'] ?? '', style: const TextStyle(fontSize:18, fontWeight: FontWeight.bold)),
                              const SizedBox(height:6),
                              Text(b['content']?.toString().substring(0,100) ?? ''),
                              const SizedBox(height:8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('By ${b['username'] ?? 'Anon'}', style: const TextStyle(color: Colors.black54)),
                                  Row(
                                    children: [
                                      const Icon(Icons.visibility, size:16, color:Colors.grey),
                                      const SizedBox(width:4),
                                      Text('${b['views'] ?? 0}'),
                                      const SizedBox(width:12),
                                      GestureDetector(
                                        onTap: () => toggleLike(b['id'].toString(), i),
                                        child: Icon(
                                          b['liked']==true ? Icons.favorite : Icons.favorite_border,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width:4),
                                      Text('${b['likes'] ?? 0}'),
                                      if (b['user_id'].toString()==widget.userId)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => deleteBlog(b['id'].toString()),
                                        ),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }
              ),
            ),
          )
        ],
      ),
    );
  }
}
