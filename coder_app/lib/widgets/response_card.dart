import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/agent_response.dart';
import '../theme/app_theme.dart';
import 'code_viewer.dart';

/// Tabbed card showing prefix (description), imports, and generated code.
class ResponseCard extends StatefulWidget {
  final AgentResponse response;

  const ResponseCard({super.key, required this.response});

  @override
  State<ResponseCard> createState() => _ResponseCardState();
}

class _ResponseCardState extends State<ResponseCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.response;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          _StatusBanner(iterations: r.iterations, hasError: r.hasError, error: r.error),
          // Tabs
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Description'),
              Tab(text: 'Imports'),
              Tab(text: 'Code'),
            ],
          ),
          // Tab views
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabs,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DescriptionTab(text: r.prefix),
                _ImportsTab(imports: r.imports),
                _CodeTab(code: r.code),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final int iterations;
  final bool hasError;
  final String error;

  const _StatusBanner({
    required this.iterations,
    required this.hasError,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasError
              ? [AppTheme.error.withValues(alpha: 0.15), Colors.transparent]
              : [AppTheme.primary.withValues(alpha: 0.12), Colors.transparent],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            hasError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            color: hasError ? AppTheme.error : AppTheme.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            hasError ? 'Completed with warnings' : 'Generated successfully',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: hasError ? AppTheme.error : AppTheme.success,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$iterations iteration${iterations == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.subtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  final String text;
  const _DescriptionTab({required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MarkdownBody(
        data: text.isEmpty ? '_No description provided._' : text,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: GoogleFonts.inter(
            color: AppTheme.onSurface,
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}

class _ImportsTab extends StatelessWidget {
  final String imports;
  const _ImportsTab({required this.imports});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: imports.trim().isEmpty
          ? const Center(
              child: Text('No imports needed.',
                  style: TextStyle(color: AppTheme.subtle, fontSize: 13)))
          : CodeViewer(code: imports, language: 'python'),
    );
  }
}

class _CodeTab extends StatelessWidget {
  final String code;
  const _CodeTab({required this.code});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: code.trim().isEmpty
          ? const Center(
              child: Text('No code generated.',
                  style: TextStyle(color: AppTheme.subtle, fontSize: 13)))
          : CodeViewer(code: code, language: 'python'),
    );
  }
}
