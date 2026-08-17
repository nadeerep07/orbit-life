import 'package:hive/hive.dart';
import '../../domain/entities/account_entity.dart';

part 'account_model.g.dart';

@HiveType(typeId: 2)
class AccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  double openingBalance;

  AccountModel({
    required this.id,
    required this.name,
    required this.openingBalance,
  });

  factory AccountModel.fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      name: entity.name,
      openingBalance: entity.openingBalance,
    );
  }

  AccountEntity toEntity() {
    return AccountEntity(id: id, name: name, openingBalance: openingBalance);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'openingBalance': openingBalance};
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Account',
      openingBalance: ((json['openingBalance'] ?? json['balance'] ?? json['initialBalance'] ?? 0) as num).toDouble(),
    );
  }
}
