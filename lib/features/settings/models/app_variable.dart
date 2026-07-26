import 'package:json_annotation/json_annotation.dart';

part 'app_variable.g.dart';

@JsonSerializable()
class AppVariable {
  final int? id;
  final String? nature;
  final String? name;
  final String? value;
  @JsonKey(name: 'isactive')
  final bool? isActive;
  @JsonKey(name: 'isdefault')
  final bool? isDefault;
  @JsonKey(name: 'iseditable')
  final bool? isEditable;
  @JsonKey(name: 'isdeleted')
  final bool? isDeleted;

  AppVariable({
    this.id,
    this.nature,
    this.name,
    this.value,
    this.isActive,
    this.isDefault,
    this.isEditable,
    this.isDeleted,
  });

  bool get active => isActive ?? false;

  factory AppVariable.fromJson(Map<String, dynamic> json) =>
      _$AppVariableFromJson(json);

  Map<String, dynamic> toJson() => _$AppVariableToJson(this);
}
