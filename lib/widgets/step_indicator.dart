import 'package:flutter/material.dart';

/// A horizontal step indicator for the 3-step registration flow.
/// Steps:
/// 1. Account (RegisterPage)
/// 2. ID Upload (IDValidationScreen)
/// 3. Confirm (ConfirmIDDetailsScreen)
class StepIndicator extends StatelessWidget {
  final int currentStep; // 1-based index
  final double spacing;
  final List<String> labels;
  final Color activeColor;
  final Color completeColor;
  final Color inactiveColor;
  final Color lineColor;

  StepIndicator({
    Key? key,
    required this.currentStep,
    this.spacing = 10,
    List<String>? labels,
    this.activeColor = const Color(0xFF53C0FF),
    this.completeColor = const Color(0xFF53C0FF),
    this.inactiveColor = const Color(0xFFBFC8D6),
    this.lineColor = const Color(0xFFE0E6EE),
  })  : labels = labels ?? const ['Account', 'ID Upload', 'Confirm'],
        assert(currentStep >= 1 && currentStep <= 3),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(labels.length * 2 - 1, (index) {
            if (index.isOdd) {
              // connector line
              final leftStep = (index + 1) ~/ 2; // step number on left
              final isCompleted = currentStep > leftStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? completeColor : lineColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }
            final stepIndex = index ~/ 2; // 0-based
            final stepNumber = stepIndex + 1;
            final bool isActive = currentStep == stepNumber;
            final bool isCompleted = currentStep > stepNumber;
            final Color circleColor = isActive
                ? activeColor
                : isCompleted
                    ? completeColor
                    : inactiveColor;
            final Color textColor = isActive || isCompleted
                ? Colors.white
                : Colors.white; // white inside circle for contrast
            return Column(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isActive)
                        BoxShadow(
                          color: activeColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, size: 22, color: textColor)
                        : Text(
                            '$stepNumber',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 6),
                SizedBox(
                  width: 80,
                  child: Text(
                    labels[stepIndex],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? activeColor
                          : (isCompleted
                              ? completeColor
                              : const Color(0xFF424242)),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Wrapper adding padding & background (optional) - can be used if needed later.
class StepIndicatorContainer extends StatelessWidget {
  final Widget child;
  const StepIndicatorContainer({Key? key, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
