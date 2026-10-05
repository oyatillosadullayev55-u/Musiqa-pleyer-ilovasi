import 'package:flutter/material.dart';
import '../core/colors.dart';

class VinylDisc extends StatelessWidget {
  final Animation<double> turns;

  const VinylDisc({super.key, required this.turns});

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: turns,
      child: SizedBox(
        width: 270,
        height: 270,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _circle(270, kRing.withAlpha(110)),
            _circle(240, kRing.withAlpha(150)),
            _circle(210, kRing.withAlpha(200)),
            Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7C4DFF),
                    Color(0xFF00B0FF),
                    Color(0xFFE040FB),
                  ],
                ),
              ),
              // Albom rasmi kerak bo'lsa shu yerga:
              // child: ClipOval(child: Image.asset('assets/cover.png', fit: BoxFit.cover)),
              child: const Icon(Icons.music_note, size: 64, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}