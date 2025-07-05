import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FullBlogPage extends StatefulWidget {
  final Map blog;
  final String userId;

  const FullBlogPage({super.key, required this.blog, required this.userId});

  @override
  State<FullBlogPage> createState() => _FullBlogPageState();
}

class _FullBlogPageState extends State<FullBlogPage> {
  late Map blog;
  late int likes;
  late bool liked;

  @override
  void initState() {
    super.initState();
    blog = widget.blog;
    likes = blog['likes'] ?? 0;
    liked = blog['liked'] == true;
  }

  void toggleLike() async {
    try {
      final response = await http.post(
        Uri.parse('https://blog-app-k878.onrender.com/like_blog'), // ✅ Updated URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': int.parse(widget.userId),
          'blog_id': blog['id'],
        }),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        setState(() {
          likes = res['likes'] ?? likes;
          liked = res['action'] == 'liked';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like status')),
        );
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(blog['title'] ?? 'Blog'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (blog['thumbnail'] != null && blog['thumbnail'].toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                blog['thumbnail'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            blog['content'] ?? '',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: toggleLike,
              ),
              Text(
                '$likes likes',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
