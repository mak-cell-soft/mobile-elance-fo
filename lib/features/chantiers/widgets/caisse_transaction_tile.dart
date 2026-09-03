import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chantier_caisse_transaction.dart';

/// Single transaction tile in the Caisse operations ledger.
class CaisseTransactionTile extends StatelessWidget {
  final ChantierCaisseTransaction transaction;

  const CaisseTransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final isEntree = transaction.isEntree;
    final sign = isEntree ? '+' : '-';
    final amountColor = isEntree ? const Color(0xFF10B981) : const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Operation Type Icon Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEntree
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEntree ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 20,
              color: amountColor,
            ),
          ),

          const SizedBox(width: 12),

          // Core Info: Reason, Beneficiary, Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        transaction.reason,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Amount
                    Text(
                      '$sign${transaction.amount.toStringAsFixed(3)} TND',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sub info: Beneficiary or Date
                    Expanded(
                      child: Text(
                        transaction.beneficiaryPersonName != null
                            ? 'Bénéficiaire : ${transaction.beneficiaryPersonName}'
                            : dateFormat.format(transaction.transactionDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Status Badge (Pending / Completed / Rejected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: transaction.statusBadgeBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        transaction.statusDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: transaction.statusBadgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),

                if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.notes!,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
