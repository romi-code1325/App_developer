import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/face_pose.dart';
import '../models/frame_model.dart';
import '../state/try_on_controller.dart';
import 'widgets/frame_selector.dart';
import 'widgets/glasses_overlay.dart';

class TryOnScreen extends StatelessWidget {
  const TryOnScreen({super.key});

  /// Scopes a fresh controller to this route so the camera is released when
  /// the user navigates back.
  static Route<void> route() => MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => TryOnController()..init(),
          child: const TryOnScreen(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TryOnController>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _CameraLayer(controller: c)),
          SafeArea(
            child: Column(
              children: [
                _TopBar(controller: c),
                const Spacer(),
                if (c.status == TryOnStatus.ready)
                  FrameSelector(
                    frames: kFrames,
                    selected: c.selected,
                    onSelected: c.selectFrame,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraLayer extends StatelessWidget {
  const _CameraLayer({required this.controller});
  final TryOnController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.status) {
      case TryOnStatus.initializing:
        return const Center(child: CircularProgressIndicator());
      case TryOnStatus.permissionDenied:
        return _Message(
          icon: Icons.no_photography_outlined,
          text: 'Camera permission is needed to try frames on.\n'
              'Allow it in system settings, then try again.',
          onRetry: controller.retry,
        );
      case TryOnStatus.error:
        return _Message(
          icon: Icons.error_outline,
          text: controller.errorMessage ?? 'Something went wrong.',
          onRetry: controller.retry,
        );
      case TryOnStatus.ready:
        final cam = controller.camera;
        if (cam == null || !cam.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        // previewSize is reported in landscape; the app is portrait-locked.
        final ps = cam.value.previewSize!;
        final w = ps.height, h = ps.width;
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  CameraPreview(cam),
                  const Positioned.fill(child: GlassesOverlay()),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});
  final TryOnController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          if (controller.status == TryOnStatus.ready)
            ValueListenableBuilder<FacePose?>(
              valueListenable: controller.pose,
              builder: (_, pose, __) => _StatusChip(tracking: pose != null),
            ),
          const Spacer(),
          IconButton.filledTonal(
            tooltip: 'Toggle tracking debug overlay',
            isSelected: controller.showDebug,
            icon: const Icon(Icons.bug_report_outlined),
            selectedIcon: const Icon(Icons.bug_report),
            onPressed: controller.toggleDebug,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.tracking});
  final bool tracking;

  @override
  Widget build(BuildContext context) {
    final color = tracking ? Colors.greenAccent : Colors.amberAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(tracking ? 'Tracking face' : 'Looking for a face…'),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, required this.onRetry});
  final IconData icon;
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
