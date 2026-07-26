// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockSite _$StockSiteFromJson(Map<String, dynamic> json) => StockSite(
  id: (json['id'] as num?)?.toInt(),
  gov: json['gov'] as String?,
  address: json['address'] as String?,
);

Map<String, dynamic> _$StockSiteToJson(StockSite instance) => <String, dynamic>{
  'id': instance.id,
  'gov': instance.gov,
  'address': instance.address,
};

StockArticleRef _$StockArticleRefFromJson(Map<String, dynamic> json) =>
    StockArticleRef(
      id: (json['id'] as num?)?.toInt(),
      reference: json['reference'] as String?,
      description: json['description'] as String?,
      unit: json['unit'] as String?,
    );

Map<String, dynamic> _$StockArticleRefToJson(StockArticleRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'description': instance.description,
      'unit': instance.unit,
    };

StockMerchandise _$StockMerchandiseFromJson(Map<String, dynamic> json) =>
    StockMerchandise(
      id: (json['id'] as num?)?.toInt(),
      packageReference: json['packagereference'] as String?,
      description: json['description'] as String?,
      article: json['article'] == null
          ? null
          : StockArticleRef.fromJson(json['article'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StockMerchandiseToJson(StockMerchandise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'packagereference': instance.packageReference,
      'description': instance.description,
      'article': instance.article,
    };

Stock _$StockFromJson(Map<String, dynamic> json) => Stock(
  id: (json['id'] as num?)?.toInt(),
  quantity: (json['quantity'] as num).toDouble(),
  minimumStock: (json['minimumstock'] as num?)?.toDouble(),
  site: json['site'] == null
      ? null
      : StockSite.fromJson(json['site'] as Map<String, dynamic>),
  merchandise: json['merchandise'] == null
      ? null
      : StockMerchandise.fromJson(json['merchandise'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StockToJson(Stock instance) => <String, dynamic>{
  'id': instance.id,
  'quantity': instance.quantity,
  'minimumstock': instance.minimumStock,
  'site': instance.site,
  'merchandise': instance.merchandise,
};
