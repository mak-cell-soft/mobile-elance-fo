/// Monthly aggregate remuneration and labor hours summary for production workers.
/// Directly mirrors backend DTO `MonthlyEmployeePayableSummaryDto` (GET /production/payables/monthly).
class MonthlyEmployeePayableSummary {
  final int year;
  final int month;
  final double totalManufacturingHours;
  final double totalManufacturingAmount;
  final double totalOtherHours;
  final double totalOtherAmount;
  final double totalPayableHours;
  final double totalPayableAmount;
  final List<EmployeePayableSummaryItem> employees;

  const MonthlyEmployeePayableSummary({
    required this.year,
    required this.month,
    required this.totalManufacturingHours,
    required this.totalManufacturingAmount,
    required this.totalOtherHours,
    required this.totalOtherAmount,
    required this.totalPayableHours,
    required this.totalPayableAmount,
    required this.employees,
  });

  factory MonthlyEmployeePayableSummary.fromJson(Map<String, dynamic> json) {
    final rawEmployees = json['employees'] ?? json['Employees'];
    final List<EmployeePayableSummaryItem> parsedEmployees = [];
    if (rawEmployees is List) {
      for (final e in rawEmployees) {
        if (e is Map<String, dynamic>) {
          parsedEmployees.add(EmployeePayableSummaryItem.fromJson(e));
        }
      }
    }

    return MonthlyEmployeePayableSummary(
      year: json['year'] ?? json['Year'] ?? DateTime.now().year,
      month: json['month'] ?? json['Month'] ?? DateTime.now().month,
      totalManufacturingHours: _toDouble(json['totalManufacturingHours'] ?? json['TotalManufacturingHours']),
      totalManufacturingAmount: _toDouble(json['totalManufacturingAmount'] ?? json['TotalManufacturingAmount']),
      totalOtherHours: _toDouble(json['totalOtherHours'] ?? json['TotalOtherHours']),
      totalOtherAmount: _toDouble(json['totalOtherAmount'] ?? json['TotalOtherAmount']),
      totalPayableHours: _toDouble(json['totalPayableHours'] ?? json['TotalPayableHours']),
      totalPayableAmount: _toDouble(json['totalPayableAmount'] ?? json['TotalPayableAmount']),
      employees: parsedEmployees,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

/// Individual employee monthly breakdown for manufacturing and outside-order activities.
class EmployeePayableSummaryItem {
  final int personId;
  final String employeeFullName;
  final double manufacturingHours;
  final double manufacturingAmount;
  final double otherHours;
  final double otherAmount;
  final double totalPayableHours;
  final double totalPayableAmount;

  const EmployeePayableSummaryItem({
    required this.personId,
    required this.employeeFullName,
    required this.manufacturingHours,
    required this.manufacturingAmount,
    required this.otherHours,
    required this.otherAmount,
    required this.totalPayableHours,
    required this.totalPayableAmount,
  });

  factory EmployeePayableSummaryItem.fromJson(Map<String, dynamic> json) {
    return EmployeePayableSummaryItem(
      personId: json['personId'] ?? json['PersonId'] ?? 0,
      employeeFullName: json['employeeFullName']?.toString() ??
          json['EmployeeFullName']?.toString() ??
          'Ouvrier',
      manufacturingHours: MonthlyEmployeePayableSummary._toDouble(
        json['manufacturingHours'] ?? json['ManufacturingHours'],
      ),
      manufacturingAmount: MonthlyEmployeePayableSummary._toDouble(
        json['manufacturingAmount'] ?? json['ManufacturingAmount'],
      ),
      otherHours: MonthlyEmployeePayableSummary._toDouble(
        json['otherHours'] ?? json['OtherHours'],
      ),
      otherAmount: MonthlyEmployeePayableSummary._toDouble(
        json['otherAmount'] ?? json['OtherAmount'],
      ),
      totalPayableHours: MonthlyEmployeePayableSummary._toDouble(
        json['totalPayableHours'] ?? json['TotalPayableHours'],
      ),
      totalPayableAmount: MonthlyEmployeePayableSummary._toDouble(
        json['totalPayableAmount'] ?? json['TotalPayableAmount'],
      ),
    );
  }
}

/// Standalone prestation / labor entry performed outside specific fabrication orders.
class ProductionOtherWorkEntry {
  final int id;
  final String? guid;
  final int personId;
  final String employeeFullName;
  final DateTime workDate;
  final double hours;
  final double hourlyRate;
  final double calculatedAmount;
  final String description;
  final int createdById;
  final DateTime? creationDate;

  const ProductionOtherWorkEntry({
    required this.id,
    this.guid,
    required this.personId,
    required this.employeeFullName,
    required this.workDate,
    required this.hours,
    required this.hourlyRate,
    required this.calculatedAmount,
    required this.description,
    this.createdById = 0,
    this.creationDate,
  });

  factory ProductionOtherWorkEntry.fromJson(Map<String, dynamic> json) {
    final rawDate = json['workDate'] ?? json['WorkDate'];
    DateTime parsedDate;
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawCreation = json['creationDate'] ?? json['CreationDate'];
    DateTime? parsedCreation;
    if (rawCreation != null) {
      parsedCreation = DateTime.tryParse(rawCreation.toString());
    }

    return ProductionOtherWorkEntry(
      id: json['id'] ?? json['Id'] ?? 0,
      guid: json['guid']?.toString() ?? json['Guid']?.toString(),
      personId: json['personId'] ?? json['PersonId'] ?? 0,
      employeeFullName: json['employeeFullName']?.toString() ??
          json['EmployeeFullName']?.toString() ??
          'Ouvrier',
      workDate: parsedDate,
      hours: MonthlyEmployeePayableSummary._toDouble(json['hours'] ?? json['Hours']),
      hourlyRate: MonthlyEmployeePayableSummary._toDouble(json['hourlyRate'] ?? json['HourlyRate']),
      calculatedAmount: MonthlyEmployeePayableSummary._toDouble(json['calculatedAmount'] ?? json['CalculatedAmount']),
      description: json['description']?.toString() ?? json['Description']?.toString() ?? '',
      createdById: json['createdById'] ?? json['CreatedById'] ?? 0,
      creationDate: parsedCreation,
    );
  }
}
