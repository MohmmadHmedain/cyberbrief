import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CyberNewsScreen extends StatefulWidget {
  const CyberNewsScreen({super.key});

  @override
  State<CyberNewsScreen> createState() => _CyberNewsScreenState();
}

class _CyberNewsScreenState extends State<CyberNewsScreen> {
  List<dynamic> cyberNews = [];
  bool isLoading = true;

  String? _currentLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final languageCode = Localizations.localeOf(context).languageCode;

    if (_currentLanguageCode != languageCode) {
      _currentLanguageCode = languageCode;
      _fetchCyberNews(languageCode);
    }
  }

  Future<void> _fetchCyberNews(String languageCode) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      cyberNews = [];
    });

    try {
      final isArabic = languageCode == "ar";

      final response = await http
          .get(
            Uri.parse(
              'http://10.0.2.2:8000/news?language=${isArabic ? 'ar' : 'en'}',
            ),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Failed to load news');
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        cyberNews = (data['articles'] as List?) ?? [];
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        cyberNews = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode == "ar";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          isArabic ? "الأخبار السيبرانية" : "Cyber Brief",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic
                        ? "📰 آخر الأخبار السيبرانية"
                        : "📰 Latest Cyber News",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (cyberNews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white24,
                        ),
                      ),
                      child: Text(
                        isArabic
                            ? "لا توجد أخبار متاحة الآن."
                            : "No news available right now.",
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),

                  ...cyberNews.take(20).map((news) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                NewsDetailPage(article: news),
                          ),
                        );
                      },
                      child: Container(
                        margin:
                            const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white24,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (news["urlToImage"] != null &&
                                news["urlToImage"]
                                    .toString()
                                    .isNotEmpty)
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: Image.network(
                                  news["urlToImage"],
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) =>
                                          const SizedBox.shrink(),
                                ),
                              ),

                            const SizedBox(height: 10),

                            Text(
                              news["title"] ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              news["description"] ?? "",
                              style: TextStyle(
                                color: Colors.grey[400],
                              ),
                              maxLines: 3,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}


// ============================================================
// News Details Page
// ============================================================

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> article;

  const NewsDetailPage({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {
    final title = (article["title"] ?? "").toString();

    final imageUrl =
        article["urlToImage"]?.toString();

    final author =
        (article["author"] ?? "").toString();

    final sourceName =
        article["source"] != null
            ? (article["source"]["name"] ?? "").toString()
            : "";

    final publishedAt =
        (article["publishedAt"] ?? "").toString();

    final content =
        (article["content"] ?? "").toString().trim();

    final description =
        (article["description"] ?? "").toString().trim();

    final fullText = content.isNotEmpty
        ? content
        : (description.isNotEmpty
            ? description
            : title);

    final isArabic =
        Localizations.localeOf(context).languageCode == "ar";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          title.isEmpty
              ? (isArabic ? "التفاصيل" : "Details")
              : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          28,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (imageUrl != null &&
                imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(14),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          const SizedBox.shrink(),
                ),
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                if (sourceName.isNotEmpty)
                  Flexible(
                    child: Text(
                      sourceName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),

                if (sourceName.isNotEmpty &&
                    publishedAt.isNotEmpty)
                  const SizedBox(width: 8),

                if (publishedAt.isNotEmpty)
                  Flexible(
                    child: Text(
                      publishedAt
                          .replaceAll('T', ' ')
                          .replaceAll('Z', ''),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),

            if (author.isNotEmpty) ...[
              const SizedBox(height: 6),

              Text(
                isArabic
                    ? "بواسطة $author"
                    : "By $author",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              fullText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}