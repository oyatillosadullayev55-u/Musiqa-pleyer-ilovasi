import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../services/music_library.dart';
import '../widgets/phone_songs_tab.dart';
import '../widgets/youtube_tab.dart';

/// Kutubxona: "Telefon" (hamma musiqalar ro'yxati) va "YouTube" bo'limlari.
/// Telefondan qo'shiq tanlansa, shu qo'shiq (Song) bilan yopiladi.
class LibraryPage extends StatelessWidget {
  final MusicLibrary library;
  final String? currentPath;
  final int initialTab;
  final VoidCallback onYoutubeStart;

  const LibraryPage({
    super.key,
    required this.library,
    required this.currentPath,
    required this.onYoutubeStart,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          title: const Text('Kutubxona'),
          bottom: const TabBar(
            indicatorColor: kRed,
            tabs: [
              Tab(text: 'Telefon'),
              Tab(text: 'YouTube'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PhoneSongsTab(library: library, currentPath: currentPath),
            YoutubeTab(onStart: onYoutubeStart),
          ],
        ),
      ),
    );
  }
}