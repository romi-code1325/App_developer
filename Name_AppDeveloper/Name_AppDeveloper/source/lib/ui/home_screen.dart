import 'package:flutter/material.dart';

import '../models/frame_model.dart';
import 'try_on_screen.dart';
import 'widgets/spectacle_painter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B1B3A), Color(0xFF0E0F1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        theme.colorScheme.primary.withOpacity(0.35),
                        Colors.transparent,
                      ]),
                    ),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 220,
                      child: FittedBox(
                        child: CustomPaint(
                          size: SpectaclePainter.designSize,
                          painter: SpectaclePainter(
                            // A light variant of the first frame reads well on dark.
                            kFrames.first,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text('Try before you buy',
                    style: theme.textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(
                  'Point the front camera at your face and see how '
                  'each spectacle frame looks on you, live.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Chip(label: Text('Real-time face tracking')),
                    Chip(label: Text('${kFrames.length} frames')),
                    const Chip(label: Text('Follows head tilt & turn')),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Start virtual try-on'),
                    onPressed: () =>
                        Navigator.of(context).push(TryOnScreen.route()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
