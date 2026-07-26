// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubCategoryRef _$SubCategoryRefFromJson(Map<String, dynamic> json) =>
    SubCategoryRef(
      id: (json['id'] as num?)?.toInt(),
      reference: json['reference'] as String?,
      description: json['description'] as String?,
      idParent: (json['idparent'] as num?)?.toInt(),
      isDeleted: json['isdeleted'] as bool?,
    );

Map<String, dynamic> _$SubCategoryRefToJson(SubCategoryRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'description': instance.description,
      'idparent': instance.idParent,
      'isdeleted': instance.isDeleted,
    };

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: (json['id'] as num?)?.toInt(),
  reference: json['reference'] as String?,
  description: json['description'] as String?,
  isDeleted: json['isdeleted'] as bool?,
  firstChildren: (json['firstchildren'] as List<dynamic>?)
      ?.map((e) => SubCategoryRef.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'reference': instance.reference,
  'description': instance.description,
  'isdeleted': instance.isDeleted,
  'firstchildren': instance.firstChildren,
};
