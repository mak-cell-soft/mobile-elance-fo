// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryRef _$CategoryRefFromJson(Map<String, dynamic> json) => CategoryRef(
  id: (json['id'] as num?)?.toInt(),
  reference: json['reference'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$CategoryRefToJson(CategoryRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'description': instance.description,
    };
