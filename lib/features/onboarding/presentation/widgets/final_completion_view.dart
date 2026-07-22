import 'package:flutter/material.dart';
import '../../domain/entities/financial_analysis_result.dart';
import '../../domain/entities/onboarding_draft.dart';

class FinalCompletionView extends StatelessWidget {
  final OnboardingDraft draft;
  final FinancialAnalysisResult? analysis;
  final bool isSubmitting;
  final VoidCallback onLaunch;

  const FinalCompletionView({
    super.key,
    required this.draft,
    required this.analysis,
    required this.isSubmitting,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final health = analysis;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Glowing Rocket Launch Header
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withValues(alpha: 0.2),
                  const Color(0xFF3B82F6).withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF10B981), size: 48),
          ),
          const SizedBox(height: 20),

          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF34D399), Color(0xFF60A5FA)],
            ).createShader(bounds),
            child: Text(
              'OrbitLife is Ready!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your personalized financial operating system is completely initialized.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 28),

          // Overview Executive Dashboard Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('ESTIMATED NET WORTH TODAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(
                  '₹${(health?.netWorth ?? 0.0).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const Divider(color: Colors.white24, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat('Liquid Cash', '₹${(health?.totalLiquidCash ?? 0.0).toStringAsFixed(0)}'),
                    _buildSummaryStat('Monthly Income', '₹${(health?.monthlyIncome ?? 0.0).toStringAsFixed(0)}'),
                    _buildSummaryStat('Health Score', '${health?.healthScore ?? 50}/100'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat('Accounts', '${draft.accounts.length} Added'),
                    _buildSummaryStat('EMIs / Loans', '${draft.emis.length} Active'),
                    _buildSummaryStat('Emergency', '${(health?.emergencyFundCoverageMonths ?? 0.0).toStringAsFixed(1)} Mos'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onLaunch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Launch OrbitLife Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 10),
                        Icon(Icons.rocket_launch_rounded, size: 22),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
      ],
    );
  }
}
