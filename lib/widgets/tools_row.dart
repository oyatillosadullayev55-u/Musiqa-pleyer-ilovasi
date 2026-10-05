import 'package:flutter/material.dart';
import '../core/colors.dart';

class ToolsRow extends StatelessWidget {
  final bool sleepActive;
  final bool speedActive;
  final VoidCallback onSleep;
  final VoidCallback onVolume;
  final VoidCallback onSpeed;
  final VoidCallback onQueue;

  const ToolsRow({
    super.key,
    required this.sleepActive,
    required this.speedActive,
    required this.onSleep,
    required this.onVolume,
    required this.onSpeed,
    required this.onQueue,
  });

  Widget _button(IconData icon, VoidCallback onTap, {bool active = false}) {
    return IconButton(
      icon: Icon(icon, size: 22, color: active ? kRed : Colors.white),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _button(Icons.alarm, onSleep, active: sleepActive),
          _button(Icons.volume_up, onVolume),
          _button(Icons.tune, onSpeed, active: speedActive),
          _button(Icons.queue_music, onQueue),
        ],
      ),
    );
  }
}