import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_budget_pro/core/utils/app_routes.dart';
import 'package:my_budget_pro/data/models/account_model.dart';
import 'package:my_budget_pro/data/models/expense_model.dart';
import 'package:my_budget_pro/data/models/transaction_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;

      try {
        final settingsBox = await Hive.openBox('settingsBox');
        bool isCompleted = settingsBox.get('isOnboardingCompleted', defaultValue: false) as bool;

        if (!isCompleted) {
          // Migration Guard for existing users: check if database already has user data
          final accountsBox = await Hive.openBox<AccountModel>('accounts');
          final expensesBox = await Hive.openBox<ExpenseModel>('expenses');
          final transactionBox = await Hive.openBox<TransactionModel>('transactions_box');

          if (accountsBox.isNotEmpty || expensesBox.isNotEmpty || transactionBox.isNotEmpty) {
            isCompleted = true;
            await settingsBox.put('isOnboardingCompleted', true);
          }
        }

        if (mounted) {
          if (isCompleted) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
          }
        }
      } catch (_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF090D16), Color(0xFF131B2E), Color(0xFF0B101D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              /// Center: 3D Icon + App Branding
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// 3D Glassmorphic Icon Container
                        Container(
                          width: 124,
                          height: 124,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.45),
                                blurRadius: 40,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/icons/orbitlife_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        /// Brand Name with Cyan Accent
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Orbit',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              TextSpan(
                                text: 'Life',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF38BDF8),
                                  letterSpacing: -1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// Tagline pill badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: const Text(
                            'SMART PERSONAL LIFE MANAGER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// Bottom: Subtly animated powered by credit
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            minHeight: 2.5,
                            backgroundColor: Color(0xFF1E293B),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Powered by Nadeer EP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
