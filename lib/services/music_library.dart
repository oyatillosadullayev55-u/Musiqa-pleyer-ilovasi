import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

/// Telefon xotirasidagi barcha musiqalarni topib beradi.
class MusicLibrary extends ChangeNotifier {
  List<Song> songs = [];
  bool loading = false;
  bool permissionDenied = false;

  static const _extensions = {'.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg', '.wma'};

  // Bu papkalar skanerlanmaydi (rington, bildirishnoma, tizim fayllari)
  static const _skipDirs = {
    'android',
    'ringtones',
    'ringtone',
    'notifications',
    'alarms',
    'whatsapp voice notes',
  };

  Future<void> load() async {
    if (loading) return;
    loading = true;
    permissionDenied = false;
    notifyListeners();

    final granted = await _requestPermission();
    if (!granted) {
      permissionDenied = true;
      loading = false;
      notifyListeners();
      return;
    }

    final found = <Song>[];
    await _walk(Directory('/storage/emulated/0'), found);
    found.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    songs = found;
    loading = false;
    notifyListeners();
  }

  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return false;

    // Android 13 va undan yangi
    final audio = await Permission.audio.request();
    if (audio.isGranted) return true;

    // Android 12 va undan eski
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<void> _walk(Directory dir, List<Song> out) async {
    try {
      await for (final entity in dir.list(followLinks: false)) {
        final name = entity.path.split('/').last;

        if (entity is Directory) {
          if (name.startsWith('.') || _skipDirs.contains(name.toLowerCase())) {
            continue;
          }
          await _walk(entity, out);
        } else if (entity is File) {
          final dot = name.lastIndexOf('.');
          if (dot <= 0) continue;
          if (!_extensions.contains(name.substring(dot).toLowerCase())) continue;

          // Juda qisqa fayllarni (tovush effektlari) o'tkazib yuboramiz
          try {
            if (await entity.length() < 300 * 1024) continue;
          } catch (_) {
            continue;
          }

          out.add(Song(
            path: entity.path,
            title: name.substring(0, dot),
            folder: dir.path.split('/').last,
          ));
        }
      }
    } catch (_) {
      // Ruxsat berilmagan papkalarni o'tkazib yuboramiz
    }
  }
}