import 'package:flutter/material.dart';

import '../../theme/app_gradients.dart';
import '../../theme/app_typography.dart';

/// Display-style title with an animated aurora ShaderMask.
/// Used for hero headlines (Login, Game Over).
class AuroraTitle extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final TextStyle? style;

  const AuroraTitle(
    this.text, {
    super.key,
    this.textAlign = TextAlign.center,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          AppGradients.aurora.createShader(Rect.fromLTWH(
        0,
        0,
        bounds.width,
        bounds.height,
      )),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: textAlign,
        style: style ?? AppTypography.display(),
      ),
    );
  }
}
