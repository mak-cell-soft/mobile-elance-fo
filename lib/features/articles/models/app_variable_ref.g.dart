// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_variable_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppVariableRef _$AppVariableRefFromJson(Map<String, dynamic> json) =>
    AppVariableRef(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      value: json['value'] as String?,
      valuetext: json['valuetext'] as String?,
    );

Map<String, dynamic> _$AppVariableRefToJson(AppVariableRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'value': instance.value,
      'valuetext': instance.valuetext,
    };
