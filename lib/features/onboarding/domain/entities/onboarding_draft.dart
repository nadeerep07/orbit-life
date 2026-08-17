import 'package:equatable/equatable.dart';

class AccountDraftItem extends Equatable {
  final String id;
  final String name;
  final String accountType; // Savings, Salary, Current, Cash, Wallet, Payment Bank, Business, Travel, Custom
  final String bank;
  final double currentBalance;
  final bool includeInNetWorth;
  final String iconName;
  final int colorHex;
  final bool importLater;
  final String notes;

  const AccountDraftItem({
    required this.id,
    required this.name,
    required this.accountType,
    required this.bank,
    required this.currentBalance,
    this.includeInNetWorth = true,
    this.iconName = 'account_balance',
    this.colorHex = 0xFF3B82F6,
    this.importLater = false,
    this.notes = '',
  });

  @override
  List<Object?> get props => [
        id,
        name,
        accountType,
        bank,
        currentBalance,
        includeInNetWorth,
        iconName,
        colorHex,
        importLater,
        notes,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'accountType': accountType,
        'bank': bank,
        'currentBalance': currentBalance,
        'includeInNetWorth': includeInNetWorth,
        'iconName': iconName,
        'colorHex': colorHex,
        'importLater': importLater,
        'notes': notes,
      };

  factory AccountDraftItem.fromJson(Map<String, dynamic> json) => AccountDraftItem(
        id: json['id'] as String,
        name: json['name'] as String,
        accountType: json['accountType'] as String? ?? 'Savings Account',
        bank: json['bank'] as String? ?? '',
        currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
        includeInNetWorth: json['includeInNetWorth'] as bool? ?? true,
        iconName: json['iconName'] as String? ?? 'account_balance',
        colorHex: json['colorHex'] as int? ?? 0xFF3B82F6,
        importLater: json['importLater'] as bool? ?? false,
        notes: json['notes'] as String? ?? '',
      );
}

class CreditCardDraftItem extends Equatable {
  final String id;
  final String name;
  final double creditLimit;
  final double usedCredit;
  final double availableCredit;
  final int statementDateDay;
  final int dueDateDay;

  const CreditCardDraftItem({
    required this.id,
    required this.name,
    required this.creditLimit,
    required this.usedCredit,
    required this.availableCredit,
    this.statementDateDay = 1,
    this.dueDateDay = 15,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        creditLimit,
        usedCredit,
        availableCredit,
        statementDateDay,
        dueDateDay,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'creditLimit': creditLimit,
        'usedCredit': usedCredit,
        'availableCredit': availableCredit,
        'statementDateDay': statementDateDay,
        'dueDateDay': dueDateDay,
      };

  factory CreditCardDraftItem.fromJson(Map<String, dynamic> json) => CreditCardDraftItem(
        id: json['id'] as String,
        name: json['name'] as String,
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0.0,
        usedCredit: (json['usedCredit'] as num?)?.toDouble() ?? 0.0,
        availableCredit: (json['availableCredit'] as num?)?.toDouble() ?? 0.0,
        statementDateDay: json['statementDateDay'] as int? ?? 1,
        dueDateDay: json['dueDateDay'] as int? ?? 15,
      );
}

class FdLotDraftItem extends Equatable {
  final String id;
  final double principal;
  final DateTime depositDate;
  final double interestRate;
  final String bank;
  final String remarks;
  final double? currentValue;
  final bool isImportedHistoricalFd;
  final bool migrationLot;

  const FdLotDraftItem({
    required this.id,
    required this.principal,
    required this.depositDate,
    required this.interestRate,
    this.bank = '',
    this.remarks = 'Imported Historical FD',
    this.currentValue,
    this.isImportedHistoricalFd = true,
    this.migrationLot = true,
  });

  @override
  List<Object?> get props => [
        id,
        principal,
        depositDate,
        interestRate,
        bank,
        remarks,
        currentValue,
        isImportedHistoricalFd,
        migrationLot,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'principal': principal,
        'depositDate': depositDate.toIso8601String(),
        'interestRate': interestRate,
        'bank': bank,
        'remarks': remarks,
        'currentValue': currentValue,
        'isImportedHistoricalFd': isImportedHistoricalFd,
        'migrationLot': migrationLot,
      };

  factory FdLotDraftItem.fromJson(Map<String, dynamic> json) => FdLotDraftItem(
        id: json['id'] as String,
        principal: (json['principal'] as num?)?.toDouble() ?? 0.0,
        depositDate: DateTime.parse(json['depositDate'] as String),
        interestRate: (json['interestRate'] as num?)?.toDouble() ?? 6.0,
        bank: json['bank'] as String? ?? '',
        remarks: json['remarks'] as String? ?? 'Imported Historical FD',
        currentValue: (json['currentValue'] as num?)?.toDouble(),
        isImportedHistoricalFd: json['isImportedHistoricalFd'] as bool? ?? true,
        migrationLot: json['migrationLot'] as bool? ?? true,
      );
}

class EmiDraftItem extends Equatable {
  final String id;
  final String title;
  final String bank;
  final double monthlyAmount;
  final double outstandingAmount;
  final double interestRate;
  final int remainingMonths;
  final int nextDueDateDay;
  final bool autoReminder;

  const EmiDraftItem({
    required this.id,
    required this.title,
    required this.bank,
    required this.monthlyAmount,
    required this.outstandingAmount,
    this.interestRate = 10.0,
    this.remainingMonths = 12,
    this.nextDueDateDay = 5,
    this.autoReminder = true,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        bank,
        monthlyAmount,
        outstandingAmount,
        interestRate,
        remainingMonths,
        nextDueDateDay,
        autoReminder,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'bank': bank,
        'monthlyAmount': monthlyAmount,
        'outstandingAmount': outstandingAmount,
        'interestRate': interestRate,
        'remainingMonths': remainingMonths,
        'nextDueDateDay': nextDueDateDay,
        'autoReminder': autoReminder,
      };

  factory EmiDraftItem.fromJson(Map<String, dynamic> json) => EmiDraftItem(
        id: json['id'] as String,
        title: json['title'] as String,
        bank: json['bank'] as String? ?? '',
        monthlyAmount: (json['monthlyAmount'] as num?)?.toDouble() ?? 0.0,
        outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
        interestRate: (json['interestRate'] as num?)?.toDouble() ?? 10.0,
        remainingMonths: json['remainingMonths'] as int? ?? 12,
        nextDueDateDay: json['nextDueDateDay'] as int? ?? 5,
        autoReminder: json['autoReminder'] as bool? ?? true,
      );
}

class IncomeDraftItem extends Equatable {
  final String id;
  final String sourceName;
  final double amount;
  final String frequency; // Monthly, Weekly, Biweekly
  final String category;

  const IncomeDraftItem({
    required this.id,
    required this.sourceName,
    required this.amount,
    this.frequency = 'Monthly',
    this.category = 'Salary',
  });

  @override
  List<Object?> get props => [id, sourceName, amount, frequency, category];

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceName': sourceName,
        'amount': amount,
        'frequency': frequency,
        'category': category,
      };

  factory IncomeDraftItem.fromJson(Map<String, dynamic> json) => IncomeDraftItem(
        id: json['id'] as String,
        sourceName: json['sourceName'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        frequency: json['frequency'] as String? ?? 'Monthly',
        category: json['category'] as String? ?? 'Salary',
      );
}

class ObligationDraftItem extends Equatable {
  final String id;
  final String name; // Rent, Fuel, Food, Electricity, Internet, Insurance, Subscriptions, Phone, Medical, Education, Custom
  final double amount;
  final String category;
  final int dueDay;

  const ObligationDraftItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.dueDay = 1,
  });

  @override
  List<Object?> get props => [id, name, amount, category, dueDay];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'category': category,
        'dueDay': dueDay,
      };

  factory ObligationDraftItem.fromJson(Map<String, dynamic> json) => ObligationDraftItem(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        category: json['category'] as String? ?? 'General',
        dueDay: json['dueDay'] as int? ?? 1,
      );
}

class InvestmentDraftItem extends Equatable {
  final String id;
  final String title;
  final String type; // Mutual Funds, Stocks, Gold, Crypto, PF, NPS, FD, Recurring Deposits, Cash Reserve
  final double amount;
  final double returnsRate;

  const InvestmentDraftItem({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    this.returnsRate = 12.0,
  });

  @override
  List<Object?> get props => [id, title, type, amount, returnsRate];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'amount': amount,
        'returnsRate': returnsRate,
      };

  factory InvestmentDraftItem.fromJson(Map<String, dynamic> json) => InvestmentDraftItem(
        id: json['id'] as String,
        title: json['title'] as String,
        type: json['type'] as String? ?? 'Mutual Funds',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        returnsRate: (json['returnsRate'] as num?)?.toDouble() ?? 12.0,
      );
}

class GoalDraftItem extends Equatable {
  final String id;
  final String title;
  final double targetAmount;
  final double currentSaved;
  final DateTime targetDate;
  final String category;

  const GoalDraftItem({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentSaved = 0.0,
    required this.targetDate,
    required this.category,
  });

  @override
  List<Object?> get props => [id, title, targetAmount, currentSaved, targetDate, category];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentSaved': currentSaved,
        'targetDate': targetDate.toIso8601String(),
        'category': category,
      };

  factory GoalDraftItem.fromJson(Map<String, dynamic> json) => GoalDraftItem(
        id: json['id'] as String,
        title: json['title'] as String,
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
        currentSaved: (json['currentSaved'] as num?)?.toDouble() ?? 0.0,
        targetDate: DateTime.parse(json['targetDate'] as String),
        category: json['category'] as String? ?? 'General',
      );
}

class SavingsDraftItem extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String storageType; // Credit Card FD, Bank FD, Savings Account, Emergency Cash, Gold / SGB, Mutual Funds / SIP
  final double monthlyContribution;

  const SavingsDraftItem({
    required this.id,
    required this.title,
    required this.amount,
    this.storageType = 'Credit Card FD',
    this.monthlyContribution = 0.0,
  });

  @override
  List<Object?> get props => [id, title, amount, storageType, monthlyContribution];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'storageType': storageType,
        'monthlyContribution': monthlyContribution,
      };

  factory SavingsDraftItem.fromJson(Map<String, dynamic> json) => SavingsDraftItem(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        storageType: json['storageType'] as String? ?? 'Credit Card FD',
        monthlyContribution: (json['monthlyContribution'] as num?)?.toDouble() ?? 0.0,
      );
}

class OnboardingDraft extends Equatable {
  final String startingChoice; // 'fresh' or 'full'
  final bool hasCreditCards;
  final bool hasEmis;
  final bool hasInvestments;
  final bool hasSavings;
  final bool hasGoals;
  final List<AccountDraftItem> accounts;
  final CreditCardDraftItem? creditCard;
  final List<FdLotDraftItem> fdLots;
  final List<EmiDraftItem> emis;
  final List<IncomeDraftItem> incomes;
  final List<ObligationDraftItem> recurringExpenses;
  final List<InvestmentDraftItem> investments;
  final List<SavingsDraftItem> savingsEntries;
  final double targetMonthlySavings;
  final List<GoalDraftItem> goals;
  final int currentStep;
  final bool isCompleted;

  const OnboardingDraft({
    this.startingChoice = 'full',
    this.hasCreditCards = true,
    this.hasEmis = true,
    this.hasInvestments = true,
    this.hasSavings = true,
    this.hasGoals = true,
    this.accounts = const [],
    this.creditCard,
    this.fdLots = const [],
    this.emis = const [],
    this.incomes = const [],
    this.recurringExpenses = const [],
    this.investments = const [],
    this.savingsEntries = const [],
    this.targetMonthlySavings = 0.0,
    this.goals = const [],
    this.currentStep = 1,
    this.isCompleted = false,
  });

  OnboardingDraft copyWith({
    String? startingChoice,
    bool? hasCreditCards,
    bool? hasEmis,
    bool? hasInvestments,
    bool? hasSavings,
    bool? hasGoals,
    List<AccountDraftItem>? accounts,
    CreditCardDraftItem? creditCard,
    List<FdLotDraftItem>? fdLots,
    List<EmiDraftItem>? emis,
    List<IncomeDraftItem>? incomes,
    List<ObligationDraftItem>? recurringExpenses,
    List<InvestmentDraftItem>? investments,
    List<SavingsDraftItem>? savingsEntries,
    double? targetMonthlySavings,
    List<GoalDraftItem>? goals,
    int? currentStep,
    bool? isCompleted,
  }) {
    return OnboardingDraft(
      startingChoice: startingChoice ?? this.startingChoice,
      hasCreditCards: hasCreditCards ?? this.hasCreditCards,
      hasEmis: hasEmis ?? this.hasEmis,
      hasInvestments: hasInvestments ?? this.hasInvestments,
      hasSavings: hasSavings ?? this.hasSavings,
      hasGoals: hasGoals ?? this.hasGoals,
      accounts: accounts ?? this.accounts,
      creditCard: creditCard ?? this.creditCard,
      fdLots: fdLots ?? this.fdLots,
      emis: emis ?? this.emis,
      incomes: incomes ?? this.incomes,
      recurringExpenses: recurringExpenses ?? this.recurringExpenses,
      investments: investments ?? this.investments,
      savingsEntries: savingsEntries ?? this.savingsEntries,
      targetMonthlySavings: targetMonthlySavings ?? this.targetMonthlySavings,
      goals: goals ?? this.goals,
      currentStep: currentStep ?? this.currentStep,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        startingChoice,
        hasCreditCards,
        hasEmis,
        hasInvestments,
        hasSavings,
        hasGoals,
        accounts,
        creditCard,
        fdLots,
        emis,
        incomes,
        recurringExpenses,
        investments,
        savingsEntries,
        targetMonthlySavings,
        goals,
        currentStep,
        isCompleted,
      ];

  Map<String, dynamic> toJson() => {
        'startingChoice': startingChoice,
        'hasCreditCards': hasCreditCards,
        'hasEmis': hasEmis,
        'hasInvestments': hasInvestments,
        'hasSavings': hasSavings,
        'hasGoals': hasGoals,
        'accounts': accounts.map((e) => e.toJson()).toList(),
        'creditCard': creditCard?.toJson(),
        'fdLots': fdLots.map((e) => e.toJson()).toList(),
        'emis': emis.map((e) => e.toJson()).toList(),
        'incomes': incomes.map((e) => e.toJson()).toList(),
        'recurringExpenses': recurringExpenses.map((e) => e.toJson()).toList(),
        'investments': investments.map((e) => e.toJson()).toList(),
        'savingsEntries': savingsEntries.map((e) => e.toJson()).toList(),
        'targetMonthlySavings': targetMonthlySavings,
        'goals': goals.map((e) => e.toJson()).toList(),
        'currentStep': currentStep,
        'isCompleted': isCompleted,
      };

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) => OnboardingDraft(
        startingChoice: json['startingChoice'] as String? ?? 'full',
        hasCreditCards: json['hasCreditCards'] as bool? ?? true,
        hasEmis: json['hasEmis'] as bool? ?? true,
        hasInvestments: json['hasInvestments'] as bool? ?? true,
        hasSavings: json['hasSavings'] as bool? ?? true,
        hasGoals: json['hasGoals'] as bool? ?? true,
        accounts: (json['accounts'] as List?)?.map((e) => AccountDraftItem.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
        creditCard: json['creditCard'] != null ? CreditCardDraftItem.fromJson(Map<String, dynamic>.from(json['creditCard'] as Map)) : null,
        fdLots: (json['fdLots'] as List?)?.map((e) => FdLotDraftItem.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
        emis: (json['emis'] as List?)?.map((e) => EmiDraftItem.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
        incomes: (json['incomes'] as List?)?.map((e) => IncomeDraftItem.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
        recurringExpenses: (json['recurringExpenses'] as List?)?.map((e) => ObligationDraftItem.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
        investments: (json['investments'] as List?)?.map((e) => InvestmentDraftItem.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
        savingsEntries: (json['savingsEntries'] as List?)?.map((e) => SavingsDraftItem.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
        targetMonthlySavings: (json['targetMonthlySavings'] as num?)?.toDouble() ?? 0.0,
        goals: (json['goals'] as List?)?.map((e) => GoalDraftItem.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
        currentStep: json['currentStep'] as int? ?? 1,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}
