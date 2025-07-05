import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _predefinedBlogs = [];
  List<dynamic> _userBlogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  void searchBlogs() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse("http://192.168.15.171:5000/search?q=$query"); //http://192.168.15.171:5000/categories

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _predefinedBlogs = result['predefined'] ?? [];
          _userBlogs = result['user'] ?? [];
        });

        if (_predefinedBlogs.isEmpty && _userBlogs.isEmpty) {
          _errorMessage = "No blogs found for '$query'.";
        }
      } else {
        setState(() {
          _errorMessage = "Server error. Try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error. Check server or internet.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget buildBlogList(String label, List<dynamic> blogs) {
    if (blogs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...blogs.map((blog) => Card(
          child: ListTile(
            title: Text(blog['title']),
            subtitle: Text(
              blog['content'].toString().length > 60
                  ? blog['content'].toString().substring(0, 60) + "..."
                  : blog['content'].toString(),
            ),
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Blogs"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Search...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchBlogs,
                ),
              ),
              onSubmitted: (_) => searchBlogs(),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            )
                : Expanded(
              child: ListView(
                children: [
                  buildBlogList("Predefined Blogs", _predefinedBlogs),
                  const SizedBox(height: 20),
                  buildBlogList("User Blogs", _userBlogs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
