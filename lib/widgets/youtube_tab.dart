import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../core/colors.dart';
import '../screens/youtube_page.dart';
import '../services/youtube_search.dart';

class YoutubeTab extends StatefulWidget {
  final VoidCallback onStart;

  const YoutubeTab({super.key, required this.onStart});

  @override
  State<YoutubeTab> createState() => _YoutubeTabState();
}

class _YoutubeTabState extends State<YoutubeTab> {
  final TextEditingController _controller = TextEditingController();
  List<YoutubeVideo> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(String id, String title) {
    widget.onStart(); // telefondagi musiqa to'xtaydi
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => YoutubePage(videoId: id, title: title)),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();

    // 1) Havola qo'yilgan bo'lsa, to'g'ridan-to'g'ri ochamiz
    if (text.contains('youtu')) {
      final id = YoutubePlayerController.convertUrlToId(text);
      if (id != null) {
        setState(() => _error = null);
        _open(id, 'YouTube');
      } else {
        setState(() => _error = "Havola noto'g'ri");
      }
      return;
    }

    // 2) Aks holda nom bo'yicha qidiramiz
    if (kYoutubeApiKey.isEmpty) {
      setState(() => _error =
      "Nom bo'yicha qidirish uchun API kalit kerak (lib/services/youtube_search.dart). "
          "Hozircha YouTube havolasini qo'yib ishlating.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await YoutubeSearch.search(text);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Qidirishda xatolik. Internet va API kalitni tekshiring.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: "Havola qo'ying yoki qo'shiq nomini yozing",
              filled: true,
              fillColor: kPanel,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _submit,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: kRed),
          ),
        Expanded(
          child: _results.isEmpty && !_loading && _error == null
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "YouTube havolasini qo'ying yoki qo'shiq nomini yozib qidiring",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
              : ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, i) {
              final v = _results[i];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    v.thumbnail,
                    width: 80,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 80, height: 56),
                  ),
                ),
                title: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  v.channel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () => _open(v.id, v.title),
              );
            },
          ),
        ),
      ],
    );
  }
}