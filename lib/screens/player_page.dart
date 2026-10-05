import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../core/colors.dart';
import '../models/repeat_mode.dart';
import '../models/song.dart';
import '../services/music_library.dart';
import '../widgets/bottom_panel.dart';
import '../widgets/tools_row.dart';
import '../widgets/top_bar.dart';
import '../widgets/vinyl_disc.dart';
import 'library_page.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation;
  final AudioPlayer _player = AudioPlayer();
  final MusicLibrary _library = MusicLibrary();
  final List<StreamSubscription> _subs = [];
  final Random _random = Random();
  Timer? _sleepTimer;

  List<Song> _queue = [];
  int _index = -1;

  bool isPlaying = false;
  bool isShuffle = false;
  RepeatMode repeatMode = RepeatMode.off;
  double position = 0; // soniya
  double duration = 0; // soniya
  double volume = 1.0;
  double speed = 1.0;
  int? _sleepMinutes;

  Song? get _current =>
      (_index >= 0 && _index < _queue.length) ? _queue[_index] : null;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _subs.add(_player.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => position = p.inMilliseconds / 1000);
    }));

    _subs.add(_player.durationStream.listen((d) {
      if (!mounted) return;
      setState(() => duration = (d?.inMilliseconds ?? 0) / 1000);
    }));

    _subs.add(_player.playerStateStream.listen((state) {
      if (!mounted) return;
      final completed = state.processingState == ProcessingState.completed;
      final playing = state.playing && !completed;
      setState(() => isPlaying = playing);
      if (playing) {
        if (!_rotation.isAnimating) _rotation.repeat();
      } else {
        _rotation.stop();
      }
      if (completed && state.playing) _onCompleted();
    }));

    // Telefondagi hamma musiqalarni topamiz
    _library.load();
  }

  // ---------- Pleyer boshqaruvi ----------

  Future<void> _playSong(int index) async {
    if (index < 0 || index >= _queue.length) return;
    setState(() {
      _index = index;
      position = 0;
      duration = 0;
    });
    try {
      await _player.setFilePath(_queue[index].path);
      unawaited(_player.play());
    } catch (e) {
      _snack("Faylni ochib bo'lmadi");
    }
  }

  void _onCompleted() {
    if (_queue.isEmpty) return;

    if (repeatMode == RepeatMode.one) {
      _player.seek(Duration.zero);
      unawaited(_player.play());
      return;
    }

    final isLast = _index == _queue.length - 1;
    if (!isShuffle && isLast && repeatMode == RepeatMode.off) {
      _player.pause();
      _player.seek(Duration.zero);
      return;
    }
    _next();
  }

  void _togglePlay() {
    if (_queue.isEmpty) {
      _openLibrary();
      return;
    }
    if (_player.playing) {
      _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
      }
      unawaited(_player.play());
    }
  }

  void _next() {
    if (_queue.isEmpty) return;
    int i;
    if (isShuffle && _queue.length > 1) {
      do {
        i = _random.nextInt(_queue.length);
      } while (i == _index);
    } else {
      i = (_index + 1) % _queue.length;
    }
    _playSong(i);
  }

  void _previous() {
    if (_queue.isEmpty) return;
    if (position > 3) {
      _player.seek(Duration.zero);
      return;
    }
    _playSong((_index - 1 + _queue.length) % _queue.length);
  }

  void _seek(double seconds) {
    if (_queue.isEmpty) return;
    _player.seek(Duration(milliseconds: (seconds * 1000).round()));
  }

  void _cycleRepeat() {
    setState(() {
      repeatMode = RepeatMode.values[(repeatMode.index + 1) % RepeatMode.values.length];
    });
    switch (repeatMode) {
      case RepeatMode.off:
        _snack("Takrorlash o'chiq");
      case RepeatMode.all:
        _snack("Hamma qo'shiqlarni takrorlash");
      case RepeatMode.one:
        _snack("Bitta qo'shiqni takrorlash");
    }
  }

  // ---------- Kutubxona, ulashish, yopish ----------

  Future<void> _openLibrary({int tab = 0}) async {
    final song = await Navigator.push<Song>(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryPage(
          library: _library,
          currentPath: _current?.path,
          initialTab: tab,
          onYoutubeStart: _player.pause,
        ),
      ),
    );
    if (song == null) return;

    _queue = List.of(_library.songs);
    final i = _queue.indexWhere((s) => s.path == song.path);
    await _playSong(i);
  }

  Future<void> _share() async {
    final song = _current;
    if (song == null) {
      _snack('Avval musiqa tanlang');
      return;
    }
    await SharePlus.instance.share(
      ShareParams(text: song.title, files: [XFile(song.path)]),
    );
  }

  Future<void> _close() async {
    await _player.stop();
    SystemNavigator.pop();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 1)));
  }

  // ---------- Pastki oynalar (alarm, ovoz, tezlik) ----------

  void _setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    setState(() => _sleepMinutes = minutes);
    if (minutes == null) return;
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      _player.pause();
      if (mounted) setState(() => _sleepMinutes = null);
    });
    _snack("Musiqa $minutes daqiqadan keyin to'xtaydi");
  }

  void _showSleepSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kPanel,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Uyqu taymeri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ),
            for (final m in [15, 30, 45, 60])
              ListTile(
                title: Text("$m daqiqadan keyin to'xtatish"),
                trailing: _sleepMinutes == m
                    ? const Icon(Icons.check, color: kRed)
                    : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _setSleepTimer(m);
                },
              ),
            ListTile(
              title: const Text("Taymerni o'chirish"),
              onTap: () {
                Navigator.pop(sheetContext);
                _setSleepTimer(null);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVolumeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kPanel,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ovoz',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    const Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: volume,
                        activeColor: kRed,
                        onChanged: (v) {
                          setSheet(() => volume = v);
                          _player.setVolume(v);
                        },
                      ),
                    ),
                    Text('${(volume * 100).round()}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSpeedSheet() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: kPanel,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tezlik',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final s in speeds)
                      ChoiceChip(
                        label: Text('${s}x'),
                        selected: speed == s,
                        selectedColor: kRed,
                        onSelected: (_) {
                          _player.setSpeed(s);
                          setSheet(() => speed = s);
                          setState(() => speed = s);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _library.dispose();
    _player.dispose();
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = _current;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              onClose: _close,
              onYoutube: () => _openLibrary(tab: 1),
              onShare: _share,
            ),
            const Spacer(flex: 2),
            VinylDisc(turns: _rotation),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                song?.title ?? 'Musiqa tanlang',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            if (song != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_index + 1} / ${_queue.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
            const Spacer(flex: 2),
            ToolsRow(
              sleepActive: _sleepMinutes != null,
              speedActive: speed != 1.0,
              onSleep: _showSleepSheet,
              onVolume: _showVolumeSheet,
              onSpeed: _showSpeedSheet,
              onQueue: () => _openLibrary(tab: 0),
            ),
            const SizedBox(height: 12),
            BottomPanel(
              position: position,
              duration: duration,
              isPlaying: isPlaying,
              repeatMode: repeatMode,
              isShuffle: isShuffle,
              onSeek: _seek,
              onTogglePlay: _togglePlay,
              onRepeat: _cycleRepeat,
              onShuffle: () {
                setState(() => isShuffle = !isShuffle);
                _snack(isShuffle ? 'Aralash yoqildi' : "Aralash o'chirildi");
              },
              onPrevious: _previous,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}