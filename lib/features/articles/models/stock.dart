import 'package:json_annotation/json_annotation.dart';

part 'stock.g.dart';

@JsonSerializable()
class StockSite {
  final int? id;
  final String? gov;
  final String? address;

  StockSite({this.id, this.gov, this.address});

  factory StockSite.fromJson(Map<String, dynamic> json) =>
      _$StockSiteFromJson(json);

  Map<String, dynamic> toJson() => _$StockSiteToJson(this);
}

@JsonSerializable()
class StockArticleRef {
  final int? id;
  final String? reference;
  final String? description;
  final String? unit;

  StockArticleRef({
    this.id,
    this.reference,
    this.description,
    this.unit,
  });

  factory StockArticleRef.fromJson(Map<String, dynamic> json) =>
      _$StockArticleRefFromJson(json);

  Map<String, dynamic> toJson() => _$StockArticleRefToJson(this);
}

@JsonSerializable()
class StockMerchandise {
  final int? id;
  @JsonKey(name: 'packagereference')
  final String? packageReference;
  final String? description;
  final StockArticleRef? article;

  StockMerchandise({
    this.id,
    this.packageReference,
    this.description,
    this.article,
  });

  factory StockMerchandise.fromJson(Map<String, dynamic> json) =>
      _$StockMerchandiseFromJson(json);

  Map<String, dynamic> toJson() => _$StockMerchandiseToJson(this);
}

@JsonSerializable()
class Stock {
  final int? id;
  final double quantity;
  @JsonKey(name: 'minimumstock')
  final double? minimumStock;
  final StockSite? site;
  final StockMerchandise? merchandise;

  Stock({
    this.id,
    required this.quantity,
    this.minimumStock,
    this.site,
    this.merchandise,
  });

  factory Stock.fromJson(Map<String, dynamic> json) => _$StockFromJson(json);

  Map<String, dynamic> toJson() => _$StockToJson(this);
}
