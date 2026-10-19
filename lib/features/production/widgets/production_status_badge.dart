import 'package:flutter/material.dart';
import '../models/production_order.dart';

/// Semantic status badge for production orders.
/// Aligns with the Arbor Industrial theme and mirrors web app status conventions:
/// - Planned: Slate / Precision Grey
/// - InProgress: Cobalt Blue (Active pulse accent)
/// - Completed: Warm Amber
/// - Validated: Deep Emerald
/// - Cancelled: Muted Crimson Rose
class ProductionStatusBadge extends StatelessWidget {
  final ProductionStatus status;
  final bool isCompact;

  const ProductionStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, text, dot) = _resolveColors();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 6 : 7,
            height: isCompact ? 6 : 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: text,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color, Color) _resolveColors() {
    switch (status) {
      case ProductionStatus.planned:
        return (
          const Color(0xFFF1F5F9),
          const Color(0xFFCBD5E1),
          const Color(0xFF334155),
          const Color(0xFF64748B),
        );
      case ProductionStatus.inProgress:
        return (
          const Color(0xFFEFF6FF),
          const Color(0xFFBFDBFE),
          const Color(0xFF1D4ED8),
          const Color(0xFF2563EB),
        );
      case ProductionStatus.completed:
        return (
          const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
          const Color(0xFFB45309),
          const Color(0xFFD97706),
        );
      case ProductionStatus.validated:
        return (
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          const Color(0xFF047857),
          const Color(0xFF059669),
        );
      case ProductionStatus.cancelled:
        return (
          const Color(0xFFFFF1F2),
          const Color(0xFFFECDD3),
          const Color(0xFFBE123C),
          const Color(0xFFE11D48),
        );
    }
  }
}

/// Semantic status badge for individual production fabrication steps.
class StepStatusBadge extends StatelessWidget {
  final ProductionStepStatus status;

  const StepStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, border, text) = _resolveColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  (Color, Color, Color) _resolveColors() {
    switch (status) {
      case ProductionStepStatus.planned:
        return (
          const Color(0xFFF8FAFC),
          const Color(0xFFE2E8F0),
          const Color(0xFF475569),
        );
      case ProductionStepStatus.inProgress:
        return (
          const Color(0xFFEFF6FF),
          const Color(0xFFBFDBFE),
          const Color(0xFF1D4ED8),
        );
      case ProductionStepStatus.completed:
        return (
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          const Color(0xFF047857),
        );
      case ProductionStepStatus.cancelled:
        return (
          const Color(0xFFFFF1F2),
          const Color(0xFFFECDD3),
          const Color(0xFFBE123C),
        );
    }
  }
}
