// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_variable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppVariable _$AppVariableFromJson(Map<String, dynamic> json) => AppVariable(
  id: (json['id'] as num?)?.toInt(),
  nature: json['nature'] as String?,
  name: json['name'] as String?,
  value: json['value'] as String?,
  isActive: json['isactive'] as bool?,
  isDefault: json['isdefault'] as bool?,
  isEditable: json['iseditable'] as bool?,
  isDeleted: json['isdeleted'] as bool?,
);

Map<String, dynamic> _$AppVariableToJson(AppVariable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nature': instance.nature,
      'name': instance.name,
      'value': instance.value,
      'isactive': instance.isActive,
      'isdefault': instance.isDefault,
      'iseditable': instance.isEditable,
      'isdeleted': instance.isDeleted,
    };
