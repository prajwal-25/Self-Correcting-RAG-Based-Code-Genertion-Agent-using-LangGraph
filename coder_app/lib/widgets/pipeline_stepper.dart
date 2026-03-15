import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated pipeline indicator: Retrieve → Generate → Check
class PipelineStepper extends StatefulWidget {
  final int currentStep; // 0=retrieve, 1=generate, 2=check, -1=done

  const PipelineStepper({super.key, required this.currentStep});

  @override
  State<PipelineStepper> createState() => _PipelineStepperState();
}

class _PipelineStepperState extends State<PipelineStepper>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const _steps = ['Retrieve', 'Generate', 'Check'];
  static const _icons = [Icons.search_rounded, Icons.auto_awesome_rounded, Icons.verified_rounded];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceVariant, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connector line
                final stepIndex = i ~/ 2;
                final isActive = stepIndex <= widget.currentStep;
                return _ConnectorLine(isActive: isActive);
              }
              final stepIndex = i ~/ 2;
              return _StepDot(
                label: _steps[stepIndex],
                icon: _icons[stepIndex],
                state: stepIndex < widget.currentStep
                    ? _StepState.done
                    : stepIndex == widget.currentStep
                        ? _StepState.active
                        : _StepState.pending,
                pulseAnim: _pulseAnim,
              );
            }),
          ),
        ],
      ),
    );
  }
}

enum _StepState { pending, active, done }

class _StepDot extends StatelessWidget {
  final String label;
  final IconData icon;
  final _StepState state;
  final Animation<double> pulseAnim;

  const _StepDot({
    required this.label,
    required this.icon,
    required this.state,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final color = state == _StepState.done
        ? AppTheme.success
        : state == _StepState.active
            ? AppTheme.primary
            : AppTheme.subtle;

    Widget dot = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: state == _StepState.pending ? 0.1 : 0.2),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(
        state == _StepState.done ? Icons.check_rounded : icon,
        color: color,
        size: 20,
      ),
    );

    if (state == _StepState.active) {
      dot = AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, child) => Transform.scale(scale: pulseAnim.value, child: child),
        child: dot,
      );
    }

    return Column(
      children: [
        dot,
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ConnectorLine extends StatelessWidget {
  final bool isActive;
  const _ConnectorLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 2,
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        gradient: isActive
            ? AppTheme.brandGradient
            : null,
        color: isActive ? null : AppTheme.surfaceVariant,
      ),
    );
  }
}
