import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// Modern Kahoot-style gradient answer button.
class AnswerButton extends StatefulWidget {
  final String label;
  final Color color;
  final IconData icon;
  final int index;
  final VoidCallback? onPressed;
  final bool isSelected;
  final bool showCorrect;
  final bool isCorrect;

  const AnswerButton({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.index,
    this.onPressed,
    this.isSelected = false,
    this.showCorrect = false,
    this.isCorrect = false,
  });

  @override
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: AppTheme.answerGradients[widget.index % 4],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final glowColor = AppTheme.answerGlow[widget.index % 4];
    final disabled = widget.onPressed == null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 145;
        final iconSize = compact ? 16.0 : 18.0;
        final textSize = compact ? 12.0 : 14.0;
        final topOffset = compact ? 8.0 : 10.0;
        final sideOffset = compact ? 9.0 : 12.0;
        final badgeSize = compact ? 20.0 : 22.0;

        return GestureDetector(
          onTapDown: (_) {
            if (!disabled) setState(() => _pressed = true);
          },
          onTapUp: (_) {
            if (!disabled) setState(() => _pressed = false);
          },
          onTapCancel: () {
            if (!disabled) setState(() => _pressed = false);
          },
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.93 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                gradient: disabled && !widget.showCorrect
                    ? LinearGradient(
                        colors: [
                          AppTheme.answerGradients[widget.index % 4][0]
                              .withOpacity(0.3),
                          AppTheme.answerGradients[widget.index % 4][1]
                              .withOpacity(0.3),
                        ],
                      )
                    : gradient,
                borderRadius: BorderRadius.circular(compact ? 16 : 20),
                border: widget.isSelected && !widget.showCorrect
                    ? Border.all(color: Colors.white, width: 3)
                    : widget.showCorrect && widget.isCorrect
                        ? Border.all(color: Colors.white, width: 3)
                        : Border.all(color: Colors.white12),
                boxShadow: disabled
                    ? []
                    : [
                        BoxShadow(
                          color: glowColor.withOpacity(_pressed ? 0.7 : 0.4),
                          blurRadius: _pressed ? 20 : 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: topOffset,
                    left: sideOffset,
                    child: Icon(
                      widget.icon,
                      color: Colors.white.withOpacity(disabled ? 0.25 : 0.55),
                      size: iconSize,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 8 : 12,
                        compact ? 24 : 28,
                        compact ? 8 : 12,
                        compact ? 6 : 8,
                      ),
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: disabled && !widget.showCorrect
                              ? Colors.white38
                              : Colors.white,
                          fontSize: textSize,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  if (widget.showCorrect && widget.isCorrect)
                    Positioned(
                      top: compact ? 6 : 8,
                      right: compact ? 8 : 10,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: badgeSize,
                      ).animate().scale(
                            begin: const Offset(0, 0),
                            duration: 350.ms,
                            curve: Curves.elasticOut,
                          ),
                    ),
                  if (widget.showCorrect &&
                      widget.isSelected &&
                      !widget.isCorrect)
                    Positioned(
                      top: compact ? 6 : 8,
                      right: compact ? 8 : 10,
                      child: Icon(
                        Icons.cancel_rounded,
                        color: Colors.white70,
                        size: badgeSize,
                      ).animate().scale(
                            begin: const Offset(0, 0),
                            duration: 350.ms,
                            curve: Curves.elasticOut,
                          ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    )
        .animate(key: ValueKey('btn_${widget.index}'))
        .scale(
          begin: const Offset(0.7, 0.7),
          delay: Duration(milliseconds: widget.index * 80),
          duration: 450.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(
          delay: Duration(milliseconds: widget.index * 80),
          duration: 300.ms,
        );
  }
}
