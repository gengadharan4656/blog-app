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
        Uri.parse('https://blog-app-k878.onrender.com/like_blog'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': int.parse(widget.userId),
          'blog_id': blog['id'],
        }),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        setState(() {
          liked = res['action'] == 'liked';
          likes = res['likes'] ?? likes;
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
    final String thumbnailUrl = (blog['thumbnail'] ?? '').toString().trim().isNotEmpty
        ? blog['thumbnail']
        : 'https://via.placeholder.com/600x300.png?text=No+Image';

    return Scaffold(
      appBar: AppBar(
        title: Text(blog['title'] ?? 'Blog'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              thumbnailUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.network(
                'https://via.placeholder.com/600x300.png?text=Image+Unavailable',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            blog['content'] ?? '',
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: toggleLike,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: liked ? Colors.red.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$likes Like${likes == 1 ? '' : 's'}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "By ${blog['username'] ?? 'Anonymous'}",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
