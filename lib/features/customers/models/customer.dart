import 'package:json_annotation/json_annotation.dart';

part 'customer.g.dart';

@JsonSerializable()
class Customer {
  final int? id;
  final String? type;
  final String? name;
  final String? description;
  final String? firstname;
  final String? lastname;
  @JsonKey(name: 'phonenumberone')
  final String? phoneNumberOne;
  @JsonKey(name: 'openingbalance')
  final double? openingBalance;
  @JsonKey(name: 'currentbalance')
  final double? currentBalance;
  @JsonKey(name: 'isactive')
  final bool? isActive;
  @JsonKey(name: 'isdeleted')
  final bool? isDeleted;

  Customer({
    this.id,
    this.type,
    this.name,
    this.description,
    this.firstname,
    this.lastname,
    this.phoneNumberOne,
    this.openingBalance,
    this.currentBalance,
    this.isActive,
    this.isDeleted,
  });

  /// Priority to Company Name (`name`), fallback to Firstname + Lastname.
  String get displayName {
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    final full = '${firstname ?? ''} ${lastname ?? ''}'.trim();
    return full.isNotEmpty ? full : 'Client #${id ?? ''}';
  }

  /// Subtitle description or activity
  String get displaySubtitle {
    if (description != null && description!.trim().isNotEmpty) {
      return description!.trim();
    }
    final full = '${firstname ?? ''} ${lastname ?? ''}'.trim();
    if (name != null && name!.trim().isNotEmpty && full.isNotEmpty) {
      return full;
    }
    return '';
  }

  /// Compute two uppercase initials for the client logo avatar.
  String get initials {
    final str = displayName.trim();
    if (str.isEmpty) return 'CL';
    final parts = str.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return str.substring(0, str.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Effective balance: prefers currentBalance, fallback to openingBalance.
  double get balance => currentBalance ?? openingBalance ?? 0.0;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerToJson(this);
}
