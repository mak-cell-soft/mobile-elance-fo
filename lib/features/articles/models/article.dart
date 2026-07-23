import 'package:json_annotation/json_annotation.dart';
import 'app_variable_ref.dart';
import 'category_ref.dart';

part 'article.g.dart';

/// Mirrors ArticleDto from GET /api/article.
/// The backend returns the full unfiltered list (no server-side pagination,
/// search or filtering) — those are implemented client-side.
@JsonSerializable()
class Article {
  final int? id;
  final String? reference;
  final String? description;
  @JsonKey(name: 'categoryid')
  final int categoryId;
  @JsonKey(name: 'subcategoryid')
  final int subcategoryId;
  @JsonKey(name: 'iswood')
  final bool isWood;
  @JsonKey(name: 'unit')
  final String? unit;
  @JsonKey(name: 'sellprice_ht')
  final double sellPriceHt;
  @JsonKey(name: 'sellprice_ttc')
  final double sellPriceTtc;
  @JsonKey(name: 'lastpurchaseprice_ttc')
  final double lastPurchasePriceTtc;
  @JsonKey(name: 'isdeleted')
  final bool isDeleted;
  @JsonKey(name: 'minquantity')
  final double? minQuantity;
  @JsonKey(name: 'imageurl')
  final String? imageUrl;
  final CategoryRef? category;
  final CategoryRef? subcategory;
  final AppVariableRef? tva;
  final AppVariableRef? thickness;
  final AppVariableRef? width;

  Article({
    this.id,
    this.reference,
    this.description,
    required this.categoryId,
    required this.subcategoryId,
    required this.isWood,
    this.unit,
    required this.sellPriceHt,
    required this.sellPriceTtc,
    required this.lastPurchasePriceTtc,
    required this.isDeleted,
    this.minQuantity,
    this.imageUrl,
    this.category,
    this.subcategory,
    this.tva,
    this.thickness,
    this.width,
  });

  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleToJson(this);
}
