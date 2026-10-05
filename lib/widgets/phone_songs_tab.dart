import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/colors.dart';
import '../services/music_library.dart';

class PhoneSongsTab extends StatefulWidget {
  final MusicLibrary library;
  final String? currentPath;

  const PhoneSongsTab({super.key, required this.library, this.currentPath});

  @override
  State<PhoneSongsTab> createState() => _PhoneSongsTabState();
}

class _PhoneSongsTabState extends State<PhoneSongsTab> {
  String _query = '';

  Widget _message(String text, List<Widget> actions) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ...actions,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.library,
      builder: (context, _) {
        final lib = widget.library;

        if (lib.loading) {
          return const Center(child: CircularProgressIndicator(color: kRed));
        }

        if (lib.permissionDenied) {
          return _message("Musiqalarni o'qish uchun ruxsat kerak", [
            FilledButton(
              onPressed: lib.load,
              child: const Text('Ruxsat berish'),
            ),
            TextButton(
              onPressed: openAppSettings,
              child: const Text('Sozlamalarni ochish'),
            ),
          ]);
        }

        if (lib.songs.isEmpty) {
          return _message('Telefonda musiqa topilmadi', [
            FilledButton(
              onPressed: lib.load,
              child: const Text('Qayta qidirish'),
            ),
          ]);
        }

        final q = _query.toLowerCase();
        final list = q.isEmpty
            ? lib.songs
            : lib.songs.where((s) => s.title.toLowerCase().contains(q)).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Qidirish...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: kPanel,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: lib.load,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${list.length} ta qo'shiq",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final song = list[i];
                  final playing = song.path == widget.currentPath;
                  return ListTile(
                    leading: Icon(
                      playing ? Icons.graphic_eq : Icons.music_note,
                      color: playing ? kRed : Colors.white70,
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: playing ? kRed : Colors.white),
                    ),
                    subtitle: Text(
                      song.folder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(context, song),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}