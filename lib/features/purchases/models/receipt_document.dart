import 'package:flutter/material.dart';

/// NOTE: Maps to backend C# `Counterpart` entity / `CustomerDto`
/// Counterpart can represent either a customer or a supplier in the ERP system.
class ReceiptSupplier {
  final int id;
  final String? name;
  final String? firstname;
  final String? lastname;
  final String? phone;
  final String? email;

  const ReceiptSupplier({
    required this.id,
    this.name,
    this.firstname,
    this.lastname,
    this.phone,
    this.email,
  });

  /// Resolves the human-readable supplier name (company name or contact person)
  String get displayName {
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    final full = '${firstname ?? ''} ${lastname ?? ''}'.trim();
    return full.isNotEmpty ? full : 'Fournisseur inconnu';
  }

  /// Initial letter for the avatar chip
  String get initial {
    final n = displayName;
    return n.isNotEmpty ? n.substring(0, 1).toUpperCase() : 'F';
  }

  factory ReceiptSupplier.fromJson(Map<String, dynamic> json) {
    return ReceiptSupplier(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }
}

/// NOTE: Maps to backend C# `Merchandise` entity inside `DocumentMerchandises`.
/// Represents each physical wood package or supply line delivered on the BR.
class ReceiptLineItem {
  final int id;
  final String? packageReference;
  final String? description;
  final double quantity;
  final double unitPriceHt;
  final double costNetHt;
  final double tvaValue;
  final double costTtc;

  const ReceiptLineItem({
    required this.id,
    this.packageReference,
    this.description,
    required this.quantity,
    required this.unitPriceHt,
    required this.costNetHt,
    required this.tvaValue,
    required this.costTtc,
  });

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) {
    // Backend can nest the item data under 'merchandise' or provide it directly in the DTO
    final m = json['merchandise'] is Map<String, dynamic>
        ? json['merchandise'] as Map<String, dynamic>
        : json;

    return ReceiptLineItem(
      id: m['id'] as int? ?? 0,
      packageReference: m['packagereference'] as String? ?? m['packageReference'] as String?,
      description: m['description'] as String? ?? (m['article'] != null ? m['article']['description'] as String? : null),
      quantity: (m['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPriceHt: (m['unit_price_ht'] as num? ?? m['unitPriceHt'] as num?)?.toDouble() ?? 0.0,
      costNetHt: (m['cost_net_ht'] as num? ?? m['costNetHt'] as num?)?.toDouble() ?? 0.0,
      tvaValue: (m['tva_value'] as num? ?? m['tvaValue'] as num?)?.toDouble() ?? 0.0,
      costTtc: (m['cost_ttc'] as num? ?? m['costTtc'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// NOTE: Maps to backend C# `DocumentDto` returned by `POST /api/Document/_typefiltered`
/// Specifically for `typeDoc: 2` (DocumentTypes.supplierReceipt / Bon de Réception).
class ReceiptDocument {
  final int id;
  final int type;
  final String docnumber;
  final String? supplierReference;
  final String? description;
  final DateTime? creationDate;
  final ReceiptSupplier? counterpart;
  final double totalHtNetDoc;
  final double totalDiscountDoc;
  final double totalTvaDoc;
  final double totalNetTtc;
  final double? totalNetPayable;
  final int docstatus;
  final int billingstatus;
  final bool isInvoiced;
  final List<ReceiptLineItem> merchandises;

  const ReceiptDocument({
    required this.id,
    required this.type,
    required this.docnumber,
    this.supplierReference,
    this.description,
    this.creationDate,
    this.counterpart,
    required this.totalHtNetDoc,
    required this.totalDiscountDoc,
    required this.totalTvaDoc,
    required this.totalNetTtc,
    this.totalNetPayable,
    required this.docstatus,
    required this.billingstatus,
    required this.isInvoiced,
    this.merchandises = const [],
  });

  /// Factory deserializer converting JSON returned by `DocumentController.GetByTypeByMonth`
  factory ReceiptDocument.fromJson(Map<String, dynamic> json) {
    // Parse creation date
    DateTime? parsedDate;
    final rawDate = json['creationdate'] ?? json['creationDate'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString());
    }

    // Parse counterpart (supplier)
    ReceiptSupplier? parsedCounterpart;
    final rawCp = json['counterpart'] ?? json['counterPart'];
    if (rawCp is Map<String, dynamic>) {
      parsedCounterpart = ReceiptSupplier.fromJson(rawCp);
    }

    // Parse merchandises / line items
    final rawItems = json['merchandises'] ?? json['documentMerchandises'];
    List<ReceiptLineItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map((item) => ReceiptLineItem.fromJson(item))
          .toList();
    }

    return ReceiptDocument(
      id: json['id'] as int? ?? 0,
      type: json['type'] as int? ?? 2,
      docnumber: json['docnumber'] as String? ?? json['docNumber'] as String? ?? 'En cours',
      supplierReference: json['supplierReference'] as String? ?? json['supplierreference'] as String?,
      description: json['description'] as String?,
      creationDate: parsedDate,
      counterpart: parsedCounterpart,
      totalHtNetDoc: (json['total_ht_net_doc'] as num? ?? json['totalHtNetDoc'] as num?)?.toDouble() ?? 0.0,
      totalDiscountDoc: (json['total_discount_doc'] as num? ?? json['totalDiscountDoc'] as num?)?.toDouble() ?? 0.0,
      totalTvaDoc: (json['total_tva_doc'] as num? ?? json['totalTvaDoc'] as num?)?.toDouble() ?? 0.0,
      totalNetTtc: (json['total_net_ttc'] as num? ?? json['totalNetTtc'] as num?)?.toDouble() ?? 0.0,
      totalNetPayable: (json['total_net_payable'] as num? ?? json['totalNetPayable'] as num?)?.toDouble(),
      docstatus: json['docstatus'] as int? ?? json['docStatus'] as int? ?? 0,
      billingstatus: json['billingstatus'] as int? ?? json['billingStatus'] as int? ?? 1,
      isInvoiced: json['isinvoiced'] as bool? ?? json['isInvoiced'] as bool? ?? false,
      merchandises: parsedItems,
    );
  }

  // --- BUSINESS HELPERS & FORMATTERS ---

  /// Indicates if this receipt has been billed / converted to an invoice
  bool get isBilled => isInvoiced || billingstatus == 2;

  /// Human-readable workflow status label matching fo-acya-app/elance-app.ui
  String get statusLabel {
    switch (docstatus) {
      case 12: // Validated
      case 8:  // Completed
        return 'Validé';
      case 1:  // Delivered
        return 'Livrée';
      case 11: // PartiallyDelivered
        return 'Partielle';
      case 15: // Approved
        return 'Approuvé';
      case 14: // PendingApproval
        return 'En attente';
      case 16: // Rejected
        return 'Rejetée';
      default:
        return 'Livrée';
    }
  }

  /// Color palette for status badge chip
  Color get statusBackgroundColor {
    switch (docstatus) {
      case 12:
      case 8:
      case 1:
      case 15:
        return const Color(0xFFECFDF5); // Emerald-50
      case 14:
        return const Color(0xFFEFF6FF); // Blue-50
      case 16:
        return const Color(0xFFFFF1F2); // Rose-50
      case 11:
        return const Color(0xFFF0FDFA); // Teal-50
      default:
        return const Color(0xFFECFDF5); // Emerald-50
    }
  }

  Color get statusTextColor {
    switch (docstatus) {
      case 12:
      case 8:
      case 1:
      case 15:
        return const Color(0xFF065F46); // Emerald-800
      case 14:
        return const Color(0xFF1E40AF); // Blue-800
      case 16:
        return const Color(0xFF9F1239); // Rose-800
      case 11:
        return const Color(0xFF115E59); // Teal-800
      default:
        return const Color(0xFF065F46); // Emerald-800
    }
  }

  Color get statusBorderColor {
    switch (docstatus) {
      case 12:
      case 8:
      case 1:
      case 15:
        return const Color(0xFFA7F3D0); // Emerald-200
      case 14:
        return const Color(0xFFBFDBFE); // Blue-200
      case 16:
        return const Color(0xFFFECDD3); // Rose-200
      case 11:
        return const Color(0xFF99F6E4); // Teal-200
      default:
        return const Color(0xFFA7F3D0); // Emerald-200
    }
  }
}
