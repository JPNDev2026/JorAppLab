import 'package:flutter/material.dart';

import '../../../../theme/jorapp_theme.dart';

class LayerToggleCard extends StatefulWidget {
  final String label;
  final String sublabel;
  final IconData iconData;
  final Color accentColor;
  final bool initActive;
  final bool disabled;
  final ValueChanged<bool>? onToggle;

  const LayerToggleCard({
    super.key,
    required this.label,
    required this.sublabel,
    required this.iconData,
    required this.accentColor,
    required this.initActive,
    this.disabled = false,
    this.onToggle,
  });

  @override
  State<LayerToggleCard> createState() => _LayerToggleCardState();
}

class _LayerToggleCardState extends State<LayerToggleCard> {
  late bool _isActive = widget.initActive;

  void _handleToggle() {
    if (widget.disabled) return;
    setState(() {
      _isActive = !_isActive;
    });
    widget.onToggle?.call(_isActive);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isActive
        ? JorappColors.lime.withOpacity(0.10)
        : Colors.white;
    final borderColor = _isActive
        ? JorappColors.teal.withOpacity(0.26)
        : JorappColors.surfaceStrong;
    final leftBarColor = widget.disabled
        ? JorappColors.tealDark.withOpacity(0.10)
        : (_isActive
              ? JorappColors.teal
              : JorappColors.teal.withOpacity(0.18));
    final iconBackground = _isActive
        ? JorappColors.lime.withOpacity(0.24)
        : JorappColors.surfaceStrong;
    const iconColor = JorappColors.tealDark;

    return Opacity(
      opacity: widget.disabled ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.disabled ? null : _handleToggle,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: JorappColors.tealDark.withOpacity(_isActive ? 0.08 : 0.03),
                  blurRadius: _isActive ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 2.5,
                  decoration: BoxDecoration(
                    color: leftBarColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: iconBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                widget.iconData,
                                size: 15,
                                color: iconColor,
                              ),
                            ),
                            const Spacer(),
                            _MiniToggle(
                              isActive: _isActive,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: JorappColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.sublabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: JorappColors.tealDark.withOpacity(0.62),
                          ),
                        ),
                      ],
                    ),
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

class _MiniToggle extends StatelessWidget {
  final bool isActive;

  const _MiniToggle({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 26,
      height: 15,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isActive
            ? JorappColors.lime.withOpacity(0.75)
            : JorappColors.surfaceStrong,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isActive
              ? JorappColors.teal.withOpacity(0.22)
              : JorappColors.tealDark.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Align(
        alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive
                ? JorappColors.tealDark
                : JorappColors.tealDark.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
