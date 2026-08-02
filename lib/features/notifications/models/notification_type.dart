/// Represents the severity / category of a system notification.
/// Matches backend `NotificationType` enum:
/// Info = 1, Success = 2, Warning = 3, Error = 4.
enum NotificationType {
  info(1),
  success(2),
  warning(3),
  error(4);

  final int value;
  const NotificationType(this.value);

  /// Safely parses an integer or string into a [NotificationType].
  static NotificationType fromValue(dynamic val) {
    if (val == null) return NotificationType.info;
    final intVal = val is int ? val : int.tryParse(val.toString()) ?? 1;
    switch (intVal) {
      case 2:
        return NotificationType.success;
      case 3:
        return NotificationType.warning;
      case 4:
        return NotificationType.error;
      case 1:
      default:
        return NotificationType.info;
    }
  }
}
