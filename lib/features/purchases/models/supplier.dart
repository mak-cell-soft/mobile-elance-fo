/// NOTE: Model representing a Counterpart Supplier returned by `GET /api/Counterpart/getall/Supplier`.
/// Used for the client-side supplier filtering dropdown on the BR receipts list.
class SupplierItem {
  final int id;
  final String? name;
  final String? firstname;
  final String? lastname;
  final String? phone;
  final String? email;

  const SupplierItem({
    required this.id,
    this.name,
    this.firstname,
    this.lastname,
    this.phone,
    this.email,
  });

  /// Resolves the human-readable supplier name (company name or individual contact)
  String get displayName {
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    final full = '${firstname ?? ''} ${lastname ?? ''}'.trim();
    return full.isNotEmpty ? full : 'Fournisseur #$id';
  }

  factory SupplierItem.fromJson(Map<String, dynamic> json) {
    return SupplierItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }
}
