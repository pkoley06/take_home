import 'dart:async';

import 'package:flutter/material.dart';

import '../dashboard_card_shell.dart';

class FocusTimerCard extends StatefulWidget {
  const FocusTimerCard({super.key});

  @override
  State<FocusTimerCard> createState() => _FocusTimerCardState();
}

class _FocusTimerCardState extends State<FocusTimerCard> {
  static const _defaultDuration = Duration(minutes: 25);

  Duration _remaining = _defaultDuration;
  Timer? _timer;

  bool get _isRunning => _timer != null;

  void _start() {
    if (_isRunning) return;
    if (_remaining == Duration.zero) _remaining = _defaultDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remaining.inSeconds <= 1) {
          _remaining = Duration.zero;
          _pause();
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
    setState(() {});
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
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
          Text(_format(_remaining), style: theme.textTheme.displaySmall),
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
