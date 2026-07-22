import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/onboarding_draft.dart';

abstract class OnboardingLocalDataSource {
  Future<void> init();
  Future<OnboardingDraft?> getDraft();
  Future<void> saveDraft(OnboardingDraft draft);
  Future<void> clearDraft();
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  static const String _draftBoxName = 'onboarding_draft_box';
  static const String _draftKey = 'current_draft';

  @override
  Future<void> init() async {
    await Hive.openBox(_draftBoxName);
  }

  @override
  Future<OnboardingDraft?> getDraft() async {
    final box = await Hive.openBox(_draftBoxName);
    final jsonStr = box.get(_draftKey) as String?;
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return OnboardingDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDraft(OnboardingDraft draft) async {
    final box = await Hive.openBox(_draftBoxName);
    final jsonStr = jsonEncode(draft.toJson());
    await box.put(_draftKey, jsonStr);
  }

  @override
  Future<void> clearDraft() async {
    final box = await Hive.openBox(_draftBoxName);
    await box.delete(_draftKey);
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final settingsBox = await Hive.openBox('settingsBox');
    return settingsBox.get('isOnboardingCompleted', defaultValue: false) as bool;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    final settingsBox = await Hive.openBox('settingsBox');
    await settingsBox.put('isOnboardingCompleted', completed);
  }
}
