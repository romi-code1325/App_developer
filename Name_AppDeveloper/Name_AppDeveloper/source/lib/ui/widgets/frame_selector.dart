import 'package:flutter/material.dart';

import '../../models/frame_model.dart';
import 'spectacle_painter.dart';

class FrameSelector extends StatelessWidget {
  const FrameSelector({
    super.key,
    required this.frames,
    required this.selected,
    required this.onSelected,
  });

  final List<FrameModel> frames;
  final FrameModel selected;
  final ValueChanged<FrameModel> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: frames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final f = frames[i];
          final isSelected = f == selected;
          return Semantics(
            button: true,
            selected: isSelected,
            label: f.name,
            child: GestureDetector(
              onTap: () => onSelected(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 104,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isSelected ? 0.96 : 0.82),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? primary : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 40,
                      child: FittedBox(
                        child: CustomPaint(
                          size: SpectaclePainter.designSize,
                          painter: SpectaclePainter(f),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      f.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
