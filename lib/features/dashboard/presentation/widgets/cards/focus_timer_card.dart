import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/di/injection.dart';
import '../../../../../core/notifications/notification_service.dart';
import '../dashboard_card_shell.dart';

class FocusTimerCard extends StatefulWidget {
  const FocusTimerCard({super.key});

  @override
  State<FocusTimerCard> createState() => _FocusTimerCardState();
}

class _FocusTimerCardState extends State<FocusTimerCard>
    with SingleTickerProviderStateMixin {
  static const _defaultDuration = Duration(minutes: 25);

  Duration _remaining = _defaultDuration;
  Timer? _timer;

  // Drives the progress ring independently of the once-a-second countdown
  // timer, so the ring sweeps smoothly instead of jumping in 1-second
  // increments — its value always tracks the elapsed fraction of the session.
  late final AnimationController _ringController = AnimationController(
    vsync: this,
    duration: _defaultDuration,
  );

  bool get _isRunning => _timer != null;

  void _start() {
    if (_isRunning) return;
    if (_remaining == Duration.zero) _remaining = _defaultDuration;
    _ringController.duration = _remaining;
    _ringController.forward(from: _ringController.value);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remaining.inSeconds <= 1) {
          _remaining = Duration.zero;
          _pause();
          getIt<NotificationService>().showProgress(
            title: 'Focus session complete',
            body: 'Nice work — take a short break.',
          );
        } else {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    _ringController.stop();
    setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    _ringController.value = 0;
    setState(() => _remaining = _defaultDuration);
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardCardShell(
      icon: Icons.timer_outlined,
      title: 'Focus Timer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, _) => CustomPaint(
                    painter: _RingPainter(
                      progress: _ringController.value,
                      trackColor: theme.colorScheme.surfaceContainerHighest,
                      progressColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(_format(_remaining), style: theme.textTheme.displaySmall),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _isRunning ? _pause : _start,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Pause' : 'Start'),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 3;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
