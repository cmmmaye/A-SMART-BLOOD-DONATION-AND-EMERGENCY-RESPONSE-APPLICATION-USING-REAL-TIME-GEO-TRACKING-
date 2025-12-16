import 'package:flutter/material.dart';

import '../common/colors.dart';
import '../database/database_helper.dart';
import '../utils/tools.dart';
import '../widgets/news_tile.dart';

class NewsScreen extends StatefulWidget {
  static const route = 'news';
  const NewsScreen({Key? key}) : super(key: key);

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Map<String, dynamic>>> _news;

  @override
  void initState() {
    super.initState();
    _news = DatabaseHelper.instance.getNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News and Tips')),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _news,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(MainColors.primary),
                ),
              );
            }

            if (snapshot.data == null || snapshot.data!.isEmpty) {
              return const Center(child: Text('No news items yet'));
            }

            return ListView(
              children: snapshot.data!.map((doc) {
                return NewsTile(
                  title: doc['title'] as String,
                  body: doc['content'] as String,
                  date: Tools.formatDate(
                    DateTime.parse(doc['created_at'] as String),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
