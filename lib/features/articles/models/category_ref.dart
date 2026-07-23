import 'package:json_annotation/json_annotation.dart';

part 'category_ref.g.dart';

/// Minimal subset of CategoryDto / FirstChildDto needed for display and
/// filtering — the mobile app doesn't need the full nested tree.
@JsonSerializable()
class CategoryRef {
  final int? id;
  final String? reference;
  final String? description;

  CategoryRef({this.id, this.reference, this.description});

  String get label => description ?? reference ?? '';

  factory CategoryRef.fromJson(Map<String, dynamic> json) =>
      _$CategoryRefFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryRefToJson(this);
}
