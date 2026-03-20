import 'package:flutter/material.dart';

class UserLocationMarker extends StatefulWidget {
  final Color color;

  const UserLocationMarker({
    super.key,
    required this.color,
  });

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final pulseOpacity = t < 0.5 ? t * 0.6 : (1 - t) * 0.6;
        final pulseScale = 1 + (t * 1.4);

        return SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: pulseScale,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withOpacity(pulseOpacity.clamp(0, 0.3)),
                    ),
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
