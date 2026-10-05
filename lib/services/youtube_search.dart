import 'dart:convert';
import 'package:http/http.dart' as http;

/// YouTube'da nom bo'yicha qidirish uchun o'zingizning API kalitingizni
/// shu yerga yozing (YouTube Data API v3). Bo'sh qoldirsangiz, faqat
/// havola (link) orqali ishlaydi.
const String kYoutubeApiKey = '';

class YoutubeVideo {
  final String id;
  final String title;
  final String channel;
  final String thumbnail;

  const YoutubeVideo({
    required this.id,
    required this.title,
    required this.channel,
    required this.thumbnail,
  });
}

class YoutubeSearch {
  static Future<List<YoutubeVideo>> search(String query) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'type': 'video',
      'videoEmbeddable': 'true',
      'maxResults': '20',
      'q': query,
      'key': kYoutubeApiKey,
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('YouTube xatosi: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();

    return items.map((item) {
      final snippet = item['snippet'] as Map<String, dynamic>;
      final thumbs = snippet['thumbnails'] as Map<String, dynamic>;
      final thumb = (thumbs['medium'] ?? thumbs['default']) as Map<String, dynamic>;
      return YoutubeVideo(
        id: (item['id'] as Map<String, dynamic>)['videoId'] as String,
        title: _decode(snippet['title'] as String),
        channel: snippet['channelTitle'] as String,
        thumbnail: thumb['url'] as String,
      );
    }).toList();
  }

  static String _decode(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}