import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/agent_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pipeline_stepper.dart';
import '../widgets/response_card.dart';
import '../widgets/typing_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  void _submit() {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    context.read<AgentProvider>().generate(question);
    _controller.clear();
    // Scroll down to show results
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 600,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPad = width > 700 ? (width - 700) / 2 : 16.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Scrollable Content ──────────────────────────────────────────────
          Positioned.fill(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                // ── Glass App Bar ─────────────────────────────────────────────
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        color: AppTheme.background.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                  title: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (b) => AppTheme.brandGradient.createShader(b),
                    child: const Icon(Icons.code_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) => AppTheme.brandGradient.createShader(b),
                    child: Text(
                      'Coder',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Consumer<AgentProvider>(
                  builder: (_, prov, __) => IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppTheme.subtle,
                    tooltip: 'New conversation',
                    onPressed: prov.status == GenerationStatus.loading
                        ? null
                        : prov.newThread,
                  ),
                ),
              ],
            ),

            // ── Hero Header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<AgentProvider>(
                builder: (_, prov, __) {
                  if (prov.status != GenerationStatus.idle) {
                    return const SizedBox.shrink();
                  }
                  return FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            horizontalPad, 40, horizontalPad, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (b) =>
                                  AppTheme.brandGradient.createShader(b),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 52),
                            ),
                            const SizedBox(height: 20),
                            ShaderMask(
                              shaderCallback: (b) =>
                                  AppTheme.brandGradient.createShader(b),
                              child: Text(
                                'What can I code\nfor you today?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Powered by Mistral AI · Self-correcting RAG pipeline',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppTheme.subtle,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 36),
                            _SuggestionChips(onTap: (q) {
                              _controller.text = q;
                              _submit();
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Pipeline / Loading ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<AgentProvider>(
                builder: (_, prov, __) {
                  if (prov.status != GenerationStatus.loading) {
                    return const SizedBox.shrink();
                  }
                  final step = prov.currentStep?.index ?? 0;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPad, vertical: 24),
                    child: Column(
                      children: [
                        PipelineStepper(currentStep: step),
                        const SizedBox(height: 20),
                        const TypingIndicator(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Response Card ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<AgentProvider>(
                builder: (_, prov, __) {
                  return PageTransitionSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, primary, secondary) =>
                        FadeThroughTransition(
                      animation: primary,
                      secondaryAnimation: secondary,
                      child: child,
                    ),
                    child: prov.status == GenerationStatus.success &&
                            prov.response != null
                        ? Padding(
                            key: const ValueKey('response'),
                            padding: EdgeInsets.fromLTRB(
                                horizontalPad, 0, horizontalPad, 16),
                            child: ResponseCard(response: prov.response!),
                          )
                        : prov.status == GenerationStatus.error
                            ? Padding(
                                key: const ValueKey('error'),
                                padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPad, vertical: 8),
                                child: _ErrorBanner(message: prov.errorMessage ?? ''),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                  );
                },
              ),
            ),

            // Bottom spacing so input bar doesn't overlap content
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
            ),
          ),

          // ── Floating Glass Input Bar ──────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background.withValues(alpha: 0.75),
                    border: const Border(
                      top: BorderSide(color: AppTheme.surfaceVariant, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 12),
                      child: _PromptInput(
                        controller: _controller,
                        onSubmit: _submit,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Suggestion Chips ──────────────────────────────────────────────────────────
class _SuggestionChips extends StatelessWidget {
  final void Function(String) onTap;
  const _SuggestionChips({required this.onTap});

  static const _suggestions = [
    'Factorial of a number',
    'Binary search algorithm',
    'Merge two sorted lists',
    'Fibonacci sequence',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _suggestions
          .map(
            (s) => ActionChip(
              label: Text(s, style: const TextStyle(color: AppTheme.onSurface, fontSize: 13)),
              backgroundColor: AppTheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.surfaceVariant),
              ),
              onPressed: () => onTap(s),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          )
          .toList(),
    );
  }
}

// ── Prompt Input ──────────────────────────────────────────────────────────────
class _PromptInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _PromptInput({required this.controller, required this.onSubmit});

  @override
  State<_PromptInput> createState() => _PromptInputState();
}

class _PromptInputState extends State<_PromptInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _btnAnim;

  @override
  void initState() {
    super.initState();
    _btnAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (widget.controller.text.isNotEmpty) {
      _btnAnim.forward();
    } else {
      _btnAnim.reverse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _btnAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AgentProvider>().isLoading;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            enabled: !isLoading,
            maxLines: 5,
            minLines: 1,
            textInputAction: TextInputAction.send,
            cursorColor: AppTheme.primary,
            onSubmitted: (_) => widget.onSubmit(),
            decoration: const InputDecoration(
              hintText: 'Ask me to write code…',
              prefixIcon: Icon(Icons.terminal_rounded, size: 18),
            ),
            style: GoogleFonts.inter(color: AppTheme.onSurface, fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedBuilder(
          animation: _btnAnim,
          builder: (_, __) {
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: _btnAnim,
                curve: Curves.elasticOut,
              ),
              child: _SendButton(
                onPressed: isLoading ? null : widget.onSubmit,
                isLoading: isLoading,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _SendButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppTheme.brandGradient : null,
        color: onPressed == null ? AppTheme.surfaceVariant : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Something went wrong',
                    style: GoogleFonts.outfit(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(message,
                    style: GoogleFonts.inter(
                        color: AppTheme.error.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
