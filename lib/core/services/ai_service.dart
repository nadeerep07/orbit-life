import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _openAiEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  Future<String> getGoalRecommendations({
    required double totalIncome,
    required double totalExpenses,
    required double currentSavings,
    required List<Map<String, dynamic>> financialGoals,
  }) async {
    // Validate bounds
    final income = totalIncome < 0 ? 0.0 : totalIncome;
    final expenses = totalExpenses < 0 ? 0.0 : totalExpenses;
    // final now = DateTime.now();

    final prompt = _buildPrompt(
      income,
      expenses,
      currentSavings,
      financialGoals,
    );

    if (_apiKey.isEmpty) {
      return _getFallbackRecommendations(
        totalIncome: income,
        totalExpenses: expenses,
        currentSavings: currentSavings,
        goals: financialGoals,
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_openAiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a strict, direct financial advisor. Provide EXACTLY 3 short actionable bullet points. Do NOT invent numbers. ONLY use the provided user data. Do not add introductory or concluding sentences.",
            },
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.3,
          "max_tokens": 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['choices']?[0]?['message']?['content'] ?? "";
        if (text.isEmpty) {
          return "AI could not generate recommendations.";
        }
        return text.trim();
      } else {
        return 'Groq API error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      return 'Error connecting to AI service. Please check your network ($e).';
    }
  }

  String _buildPrompt(
    double income,
    double expenses,
    double savings,
    List<Map<String, dynamic>> goals,
  ) {
    final savingsRate = income > 0
        ? ((income - expenses) / income * 100)
              .clamp(0.0, 100.0)
              .toStringAsFixed(1)
        : '0.0';

    String goalsText = '';

    for (var g in goals) {
      final dueDate = g["dueDate"] as DateTime?;
      int monthsRemaining = 0;

      if (dueDate != null) {
        final now = DateTime.now();
        monthsRemaining =
            ((dueDate.year - now.year) * 12) + (dueDate.month - now.month);

        if (monthsRemaining < 1) monthsRemaining = 1;
      }
      final name = g["name"] ?? "Unnamed Goal";
      final target = (g["targetAmount"] as num?)?.toDouble() ?? 0.0;
      final saved = (g["currentSavings"] as num?)?.toDouble() ?? 0.0;
      final remaining = (target - saved) < 0 ? 0.0 : (target - saved);

      String optionalCalculations = "";

      if (monthsRemaining > 0 && remaining > 0) {
        final monthlyRequired = remaining / monthsRemaining;

        optionalCalculations =
            ", months left: $monthsRemaining, required monthly: ₹${monthlyRequired.toStringAsFixed(0)}";
      }

      goalsText +=
          "- $name: Target: ₹${target.toStringAsFixed(0)}, Saved: ₹${saved.toStringAsFixed(0)}, Remaining: ₹${remaining.toStringAsFixed(0)}$optionalCalculations\n";
    }

    return """
User financial data:
Monthly income: ₹${income.toStringAsFixed(0)}
Monthly expenses: ₹${expenses.toStringAsFixed(0)}
Overall Savings balance: ₹${savings.toStringAsFixed(0)}
Calculated Savings Rate: $savingsRate %

Active Goals:
${goalsText.isEmpty ? "None" : goalsText}

Instructions:
1. Provide exactly 3 bullet points.
2. If expenses exceed income, strongly suggest budgeting.
3. If savings rate is < 20%, suggest reducing expenses.
4. If a goal has a required monthly amount, suggest allocating that exact amount.
5. Do NOT invent new suggestions with random monetary numbers. Use ONLY the data above.
""";
  }

  String _getFallbackRecommendations({
    required double totalIncome,
    required double totalExpenses,
    required double currentSavings,
    required List<Map<String, dynamic>> goals,
  }) {
    final savingsRate = totalIncome > 0
        ? ((totalIncome - totalExpenses) / totalIncome)
        : 0.0;

    final buffer = StringBuffer();

    if (totalExpenses > totalIncome && totalIncome > 0) {
      buffer.writeln(
        "• Warning: Your expenses currently exceed your income. Urgent budgeting required.",
      );
    } else if (savingsRate < 0.20) {
      buffer.writeln(
        "• Try to reduce non-essential expenses to increase your savings rate above 20%.",
      );
    } else {
      buffer.writeln(
        "• Great job maintaining a healthy savings rate. Consider investing your surplus.",
      );
    }

    if (currentSavings < (totalExpenses * 3)) {
      buffer.writeln(
        "• Prioritize building an emergency fund of at least ₹${(totalExpenses * 3).toStringAsFixed(0)} (3 months of expenses).",
      );
    }

    if (goals.isNotEmpty) {
      final activeGoals = goals.where((g) {
        final target = (g["targetAmount"] as num?)?.toDouble() ?? 0.0;
        final saved = (g["currentSavings"] as num?)?.toDouble() ?? 0.0;
        return saved < target;
      }).toList();

      if (activeGoals.isNotEmpty) {
        final topGoal = activeGoals.first;
        final remaining =
            ((topGoal["targetAmount"] as num) -
                    (topGoal["currentSavings"] as num))
                .toDouble();
        buffer.writeln(
          "• Focus on completing your '${topGoal['name']}' goal. You only need ₹${remaining.toStringAsFixed(0)} more.",
        );
      }
    }

    return buffer.toString().trim();
  }

  Future<Map<String, dynamic>> estimateFoodNutrition(String foodName) async {
    final response = await http.post(
      Uri.parse(_openAiEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {
            "role": "system",
            "content":
                "Return ONLY valid JSON with calories, protein, carbs, fat.",
          },
          {
            "role": "user",
            "content":
                "Estimate nutrition for $foodName. Example response: {\"calories\":500,\"protein\":25,\"carbs\":40,\"fat\":20}",
          },
        ],
        "max_tokens": 120,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("AI error ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    String text = data['choices'][0]['message']['content'];

    // 🔧 Remove markdown wrappers if present
    text = text.replaceAll("```json", "").replaceAll("```", "").trim();

    return jsonDecode(text);
  }
}
