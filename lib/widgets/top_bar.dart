import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onYoutube;
  final VoidCallback onShare;

  const TopBar({
    super.key,
    required this.onClose,
    required this.onYoutube,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            onPressed: onClose,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.smart_display_outlined, size: 22),
            onPressed: onYoutube,
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}