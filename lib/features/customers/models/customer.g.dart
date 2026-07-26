// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
  id: (json['id'] as num?)?.toInt(),
  type: json['type'] as String?,
  name: json['name'] as String?,
  description: json['description'] as String?,
  firstname: json['firstname'] as String?,
  lastname: json['lastname'] as String?,
  phoneNumberOne: json['phonenumberone'] as String?,
  openingBalance: (json['openingbalance'] as num?)?.toDouble(),
  currentBalance: (json['currentbalance'] as num?)?.toDouble(),
  isActive: json['isactive'] as bool?,
  isDeleted: json['isdeleted'] as bool?,
);

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'name': instance.name,
  'description': instance.description,
  'firstname': instance.firstname,
  'lastname': instance.lastname,
  'phonenumberone': instance.phoneNumberOne,
  'openingbalance': instance.openingBalance,
  'currentbalance': instance.currentBalance,
  'isactive': instance.isActive,
  'isdeleted': instance.isDeleted,
};
