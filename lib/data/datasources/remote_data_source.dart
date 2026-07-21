import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataSource {
  final FirebaseFirestore firestore;

  FirebaseDataSource(this.firestore);

  // Backup data
  Future<void> backupData({
    required String userId,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> accounts,
    required Map<String, dynamic>? savings,
    required List<Map<String, dynamic>> incomes,
    required List<Map<String, dynamic>> mileages,
    required List<Map<String, dynamic>> transfers,
    required List<Map<String, dynamic>> goals,
    required List<Map<String, dynamic>> services,
    required Map<String, dynamic>? dietProfile,
    required List<Map<String, dynamic>> mealEntries,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> borrowLends,
    required List<Map<String, dynamic>> emis,
    required List<Map<String, dynamic>> investments,
    required Map<String, dynamic>? creditCardAccount,
    required List<Map<String, dynamic>> fdLots,
    required List<Map<String, dynamic>> statements,
    required List<Map<String, dynamic>> cashbacks,
  }) async {
    final docRef = firestore.collection('users').doc(userId);
    await docRef.set({
      'lastBackup': FieldValue.serverTimestamp(),
      'categories': categories,
      'expenses': expenses,
      'accounts': accounts,
      'savings': savings,
      'incomes': incomes,
      'mileages': mileages,
      'transfers': transfers,
      'goals': goals,
      'services': services,
      'dietProfile': dietProfile,
      'mealEntries': mealEntries,
      'transactions': transactions,
      'borrowLends': borrowLends,
      'emis': emis,
      'investments': investments,
      'creditCardAccount': creditCardAccount,
      'fdLots': fdLots,
      'statements': statements,
      'cashbacks': cashbacks,
    });
  }

  // Restore data
  Future<Map<String, dynamic>?> restoreData(String userId) async {
    final docSnapshot = await firestore.collection('users').doc(userId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data();
    }
    return null;
  }
}
