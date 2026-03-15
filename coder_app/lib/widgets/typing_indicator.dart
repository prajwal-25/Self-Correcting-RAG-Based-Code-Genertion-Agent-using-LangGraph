import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Animated three-dot style "thinking" indicator with status label.
class TypingIndicator extends StatelessWidget {
  final String label;
  const TypingIndicator({super.key, this.label = 'Agent is thinking…'});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SpinKitThreeBounce(
          color: AppTheme.primary,
          size: 16,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(color: AppTheme.subtle, fontSize: 13),
        ),
      ],
    );
  }
}
