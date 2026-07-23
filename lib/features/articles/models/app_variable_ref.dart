import 'package:json_annotation/json_annotation.dart';

part 'app_variable_ref.g.dart';

/// Mirrors AppVariableDto — used for tva/thickness/width on an article.
@JsonSerializable()
class AppVariableRef {
  final int? id;
  final String? name;
  final String? value;
  final String? valuetext;

  AppVariableRef({this.id, this.name, this.value, this.valuetext});

  String get label => valuetext ?? name ?? value ?? '';

  factory AppVariableRef.fromJson(Map<String, dynamic> json) =>
      _$AppVariableRefFromJson(json);

  Map<String, dynamic> toJson() => _$AppVariableRefToJson(this);
}
