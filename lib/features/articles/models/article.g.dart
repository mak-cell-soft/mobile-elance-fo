// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Article _$ArticleFromJson(Map<String, dynamic> json) => Article(
  id: (json['id'] as num?)?.toInt(),
  reference: json['reference'] as String?,
  description: json['description'] as String?,
  categoryId: (json['categoryid'] as num).toInt(),
  subcategoryId: (json['subcategoryid'] as num).toInt(),
  isWood: json['iswood'] as bool,
  unit: json['unit'] as String?,
  sellPriceHt: (json['sellprice_ht'] as num).toDouble(),
  sellPriceTtc: (json['sellprice_ttc'] as num).toDouble(),
  lastPurchasePriceTtc: (json['lastpurchaseprice_ttc'] as num).toDouble(),
  isDeleted: json['isdeleted'] as bool,
  minQuantity: (json['minquantity'] as num?)?.toDouble(),
  imageUrl: json['imageurl'] as String?,
  category: json['category'] == null
      ? null
      : CategoryRef.fromJson(json['category'] as Map<String, dynamic>),
  subcategory: json['subcategory'] == null
      ? null
      : CategoryRef.fromJson(json['subcategory'] as Map<String, dynamic>),
  tva: json['tva'] == null
      ? null
      : AppVariableRef.fromJson(json['tva'] as Map<String, dynamic>),
  thickness: json['thickness'] == null
      ? null
      : AppVariableRef.fromJson(json['thickness'] as Map<String, dynamic>),
  width: json['width'] == null
      ? null
      : AppVariableRef.fromJson(json['width'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ArticleToJson(Article instance) => <String, dynamic>{
  'id': instance.id,
  'reference': instance.reference,
  'description': instance.description,
  'categoryid': instance.categoryId,
  'subcategoryid': instance.subcategoryId,
  'iswood': instance.isWood,
  'unit': instance.unit,
  'sellprice_ht': instance.sellPriceHt,
  'sellprice_ttc': instance.sellPriceTtc,
  'lastpurchaseprice_ttc': instance.lastPurchasePriceTtc,
  'isdeleted': instance.isDeleted,
  'minquantity': instance.minQuantity,
  'imageurl': instance.imageUrl,
  'category': instance.category,
  'subcategory': instance.subcategory,
  'tva': instance.tva,
  'thickness': instance.thickness,
  'width': instance.width,
};
