import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class SubCategoryRef {
  final int? id;
  final String? reference;
  final String? description;
  @JsonKey(name: 'idparent')
  final int? idParent;
  @JsonKey(name: 'isdeleted')
  final bool? isDeleted;

  SubCategoryRef({
    this.id,
    this.reference,
    this.description,
    this.idParent,
    this.isDeleted,
  });

  String get label => description ?? reference ?? '';

  factory SubCategoryRef.fromJson(Map<String, dynamic> json) =>
      _$SubCategoryRefFromJson(json);

  Map<String, dynamic> toJson() => _$SubCategoryRefToJson(this);
}

@JsonSerializable()
class Category {
  final int? id;
  final String? reference;
  final String? description;
  @JsonKey(name: 'isdeleted')
  final bool? isDeleted;
  @JsonKey(name: 'firstchildren')
  final List<SubCategoryRef>? firstChildren;

  Category({
    this.id,
    this.reference,
    this.description,
    this.isDeleted,
    this.firstChildren,
  });

  String get label => description ?? reference ?? '';

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
