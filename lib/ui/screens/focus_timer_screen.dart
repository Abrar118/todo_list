import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../state/focus_timer_controller.dart';

/// The running Pomodoro session: countdown ring, pause/resume, stop, and
/// break handling. Opened from the editor or the Focus app-bar chip.
class FocusTimerScreen extends StatelessWidget {
  const FocusTimerScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const FocusTimerScreen()));

  static String format(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<FocusTimerController>();
    final colors = context.colors;

    if (!timer.isActive) {
      // Session ended (or was stopped) while this screen was open.
      return Scaffold(
        appBar: AppBar(title: const Text('Focus timer')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 40, color: colors.textMuted),
              const SizedBox(height: 14),
              Text(
                timer.completedSessions > 0
                    ? 'Session done — '
                          '${timer.completedSessions} completed. Nice work.'
                    : 'No session running.',
                style: TextStyle(fontSize: 15, color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final work = timer.phase == TimerPhase.work;
    return Scaffold(
      appBar: AppBar(title: const Text('Focus timer')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                work ? 'FOCUS' : 'BREAK',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: work ? colors.accent : colors.done,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  timer.taskTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: timer.progress.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      color: work ? colors.accent : colors.done,
                      backgroundColor: colors.pressed,
                    ),
                    Center(
                      child: Text(
                        format(timer.remaining),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (timer.completedSessions > 0)
                Text(
                  '${timer.completedSessions} session'
                  '${timer.completedSessions == 1 ? '' : 's'} completed',
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (work)
                    FilledButton.icon(
                      onPressed: timer.isPaused ? timer.resume : timer.pause,
                      icon: Icon(
                        timer.isPaused ? Icons.play_arrow : Icons.pause,
                        size: 20,
                      ),
                      label: Text(timer.isPaused ? 'Resume' : 'Pause'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: timer.skipBreak,
                      icon: const Icon(Icons.skip_next, size: 20),
                      label: const Text('Skip break'),
                    ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => timer.stop(),
                    icon: const Icon(Icons.stop, size: 20),
                    label: const Text('Stop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
