import 'package:flutter/material.dart';

class StepStartingPointView extends StatelessWidget {
  final String selectedChoice;
  final ValueChanged<String> onChoiceSelected;
  final VoidCallback onContinue;

  const StepStartingPointView({
    super.key,
    required this.selectedChoice,
    required this.onChoiceSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  const Color(0xFF10B981).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 16, color: Color(0xFF3B82F6)),
                SizedBox(width: 8),
                Text(
                  'CHOOSE YOUR ONBOARDING MODE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'How would you like to start OrbitLife?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select how deep you want your initial financial operating system configuration to be.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          _buildOptionCard(
            context,
            choiceKey: 'full',
            title: 'Existing Financial Life',
            subtitle: 'I already have bank accounts, credit cards, investments, & loans to set up.',
            icon: Icons.account_balance_rounded,
            badge: 'Recommended',
            gradientColors: [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
            features: [
              'Complete Net Worth & Liquid Cash snapshot today',
              'FD-backed Secured Credit Card & limit utilization',
              'Active EMI loan tracking & due date reminders',
              'AI Financial Health Score & Smart Budget',
            ],
            isRecommended: true,
          ),
          const SizedBox(height: 18),

          _buildOptionCard(
            context,
            choiceKey: 'fresh',
            title: 'Start Fresh',
            subtitle: 'I have little or no financial history to enter right now. Launch immediately with zero setup.',
            icon: Icons.bolt_rounded,
            badge: 'Fast Setup (30s)',
            gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
            features: [
              'Zero manual entries required',
              'Default categories & budget pre-created',
              'Add accounts & cards whenever you are ready later',
            ],
            isRecommended: false,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String choiceKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required List<Color> gradientColors,
    required List<String> features,
    required bool isRecommended,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedChoice == choiceKey;

    return InkWell(
      onTap: () => onChoiceSelected(choiceKey),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? gradientColors[0].withValues(alpha: 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? gradientColors[0]
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isRecommended ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isRecommended ? const Color(0xFF10B981) : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: isSelected ? gradientColors[0] : Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
