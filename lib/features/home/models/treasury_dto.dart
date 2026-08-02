/// DTO representing cash balance for an individual sales site / boutique caisse.
class SiteCaisseBalanceDto {
  final int salesSiteId;
  final String salesSiteName;
  final double currentBalance;

  const SiteCaisseBalanceDto({
    required this.salesSiteId,
    required this.salesSiteName,
    required this.currentBalance,
  });

  factory SiteCaisseBalanceDto.fromJson(Map<String, dynamic> json) {
    final siteId = (json['salesSiteId'] ?? json['salesSiteid'] ?? json['siteId'] ?? 0) as num;
    String siteName = (json['salesSiteName'] ?? json['siteName'] ?? json['designation'] ?? '').toString();
    if (siteName.isEmpty) {
      siteName = 'Site #$siteId';
    }

    final balance = (json['currentBalance'] ?? json['balance'] ?? 0) as num;

    return SiteCaisseBalanceDto(
      salesSiteId: siteId.toInt(),
      salesSiteName: siteName,
      currentBalance: balance.toDouble(),
    );
  }
}
