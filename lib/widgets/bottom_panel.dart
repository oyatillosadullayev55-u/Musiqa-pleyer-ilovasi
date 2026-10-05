import 'package:flutter/material.dart' hide RepeatMode;
import '../core/colors.dart';
import '../models/repeat_mode.dart';

class BottomPanel extends StatelessWidget {
  final double position;
  final double duration;
  final bool isPlaying;
  final RepeatMode repeatMode;
  final bool isShuffle;
  final ValueChanged<double> onSeek;
  final VoidCallback onTogglePlay;
  final VoidCallback onRepeat;
  final VoidCallback onShuffle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const BottomPanel({
    super.key,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.repeatMode,
    required this.isShuffle,
    required this.onSeek,
    required this.onTogglePlay,
    required this.onRepeat,
    required this.onShuffle,
    required this.onPrevious,
    required this.onNext,
  });

  String _fmt(double s) {
    final t = s.floor();
    return '${t ~/ 60}:${(t % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Qo'shiq tanlanmaganda duration 0 bo'ladi, slider xato bermasligi uchun
    final double max = duration > 0 ? duration : 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1.5,
              activeTrackColor: kRed,
              inactiveTrackColor: Colors.white30,
              thumbColor: kRed,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: position.clamp(0, max).toDouble(),
              min: 0,
              max: max,
              onChanged: onSeek,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(position),
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
                Text(_fmt(duration),
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                  size: 20,
                  color: repeatMode == RepeatMode.off ? Colors.white : kRed,
                ),
                onPressed: onRepeat,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 24),
                onPressed: onPrevious,
              ),
              GestureDetector(
                onTap: onTogglePlay,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: kPanel,
                    size: 30,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 24),
                onPressed: onNext,
              ),
              IconButton(
                icon: Icon(Icons.shuffle,
                    size: 20, color: isShuffle ? kRed : Colors.white),
                onPressed: onShuffle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}