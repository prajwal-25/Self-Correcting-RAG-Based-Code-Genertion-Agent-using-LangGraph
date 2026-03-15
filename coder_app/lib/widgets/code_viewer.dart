import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Syntax-highlighted code block with a copy button and language label.
class CodeViewer extends StatefulWidget {
  final String code;
  final String language;

  const CodeViewer({
    super.key,
    required this.code,
    this.language = 'python',
  });

  @override
  State<CodeViewer> createState() => _CodeViewerState();
}

class _CodeViewerState extends State<CodeViewer> {
  bool _copied = false;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.codeBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.surfaceVariant,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    widget.language,
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _copied
                      ? const Row(
                          key: ValueKey('copied'),
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppTheme.success, size: 14),
                            SizedBox(width: 4),
                            Text('Copied!',
                                style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        )
                      : GestureDetector(
                          key: const ValueKey('copy'),
                          onTap: _copy,
                          child: const Row(
                            children: [
                              Icon(Icons.copy_rounded,
                                  color: AppTheme.subtle, size: 14),
                              SizedBox(width: 4),
                              Text('Copy',
                                  style: TextStyle(
                                      color: AppTheme.subtle, fontSize: 12)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Code
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: HighlightView(
                        widget.code,
                        language: widget.language,
                        theme: {
                          ...atomOneDarkTheme,
                          'root': TextStyle(
                            color: atomOneDarkTheme['root']?.color ?? const Color(0xffabb2bf),
                            backgroundColor: Colors.transparent,
                          ),
                        },
                        padding: const EdgeInsets.all(16),
                        textStyle: GoogleFonts.jetBrainsMono(fontSize: 13, height: 1.6),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
