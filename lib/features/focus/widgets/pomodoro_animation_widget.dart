import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PomodoroAnimationWidget extends StatefulWidget {
  final bool isSessionActive;

  const PomodoroAnimationWidget({super.key, required this.isSessionActive});

  @override
  State<PomodoroAnimationWidget> createState() =>
      _PomodoroAnimationWidgetState();
}

class _PomodoroAnimationWidgetState extends State<PomodoroAnimationWidget>
    with SingleTickerProviderStateMixin {
  Timer? _movementTimer;
  late AnimationController _flipController;

  // times per cycle (randomized)
  final _minTimePerCycle = 8.0;
  final _maxTimePerCycle = 15.0;

  double _startPosition = 0.5; // start halfway
  double _currentPosition = 0.5;
  double _targetPosition = 1;
  double _cycleDuration = 0;
  double _cycleStartTime = 0; // tracks when cycle started (initialize 0)

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _startMovement();

    // Only set initial target if session is active
    if (widget.isSessionActive) {
      setTarget(0);
    }
  }

  void _startMovement() {
    _movementTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void flipAnimation() {
    _flipController.forward(from: 0);
  }

  void setTarget(double currentTime) {
    final random = Random();

    _cycleStartTime = currentTime;

    _cycleDuration =
        _minTimePerCycle +
        random.nextDouble() * (_maxTimePerCycle - _minTimePerCycle + 1);

    // Pick random target in opposite direction
    if (_startPosition > _targetPosition) {
      _targetPosition =
          _targetPosition + random.nextDouble() * (1.0 - _targetPosition);
    } else {
      _targetPosition = random.nextDouble() * _targetPosition;
    }
    _startPosition = _currentPosition;

    // Start flip animation
    flipAnimation();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final bobbySize = 80.0.w;
    final scaleConstant = 1.sw - bobbySize - 25;

    final y = (180.h + bobbySize) / 2.5;

    final distance = (_targetPosition - _startPosition).abs();
    final walkTime = distance / (1 / _minTimePerCycle);

    if (widget.isSessionActive) {
      // base case: Bobby has reached his location already
      _currentPosition = _targetPosition;
      if (time >= _cycleStartTime + _cycleDuration) {
        // cycle time reset, new destination
        setTarget(time);
      } else if (time < _cycleStartTime + walkTime) {
        // if the elapsed time is less than walking time, must mean that Bobby
        // still has not reached destination, so we move it accordingly
        double progress = (time - _cycleStartTime) / walkTime;
        _currentPosition =
            (_startPosition + (_targetPosition - _startPosition) * progress);
      }
    } else {
      // set targetPosition to currentPosition to reset after pause
      _targetPosition = _currentPosition;
    }

    // Rotation animation always plays
    final rotation = ((time.toInt() % 2 == 0) ? 12.0 : -12.0) * (pi / 360);

    // Flip animation: compress to 0, flip, expand back to 1
    final flipProgress = _flipController.value;
    double horizontalScale;
    double scaleX;

    if (flipProgress < 0.5) {
      // First half: compress from 1.0 to 0
      horizontalScale = 1.0 - (flipProgress * 2);
      scaleX = _startPosition < _targetPosition ? -1.0 : 1.0; // Old direction
    } else {
      // Second half: expand from 0 to 1.0
      horizontalScale = (flipProgress - 0.5) * 2;
      scaleX =
          _startPosition < _targetPosition
              ? 1.0
              : -1.0; // New direction (flipped)
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/misc/campusBackground.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: _currentPosition * scaleConstant,
              top: y,
              child: Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.identity()
                      ..rotateZ(rotation)
                      ..scale(scaleX * horizontalScale, 1.0),
                child: Image.asset(
                  'assets/bobbys/Bobby.png',
                  width: bobbySize,
                  height: bobbySize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
