// NOTE: Production models matching ASP.NET Core WoodApp backend DTOs:
// ms.webapp.api.acya.core.Entities.DTOs.Production.ProductionOrderDto
// ms.webapp.api.acya.core.Entities.DTOs.Production.ProductionStepDto
// Enums match ms.webapp.api.acya.core.Entities.Production.ProductionEnums.cs

/// Lifecycle status of a production order.
/// Mirrors C# backend enum [ms.webapp.api.acya.core.Entities.Production.ProductionStatus].
enum ProductionStatus {
  planned,
  inProgress,
  completed,
  validated,
  cancelled;

  /// Robust parser accepting both string representation ('Planned', 'InProgress', 'Completed',
  /// 'Validated', 'Cancelled') and integer ordinal indices (0, 1, 2, 3, 4).
  /// Safe fallback to [ProductionStatus.planned] on unknown or null inputs to prevent app crash.
  static ProductionStatus fromDynamic(dynamic val) {
    if (val == null) return ProductionStatus.planned;
    if (val is int) {
      switch (val) {
        case 0:
          return ProductionStatus.planned;
        case 1:
          return ProductionStatus.inProgress;
        case 2:
          return ProductionStatus.completed;
        case 3:
          return ProductionStatus.validated;
        case 4:
          return ProductionStatus.cancelled;
        default:
          return ProductionStatus.planned;
      }
    }
    final s = val.toString().trim().toLowerCase();
    switch (s) {
      case '0':
      case 'planned':
      case 'planifié':
      case 'planifie':
        return ProductionStatus.planned;
      case '1':
      case 'inprogress':
      case 'in_progress':
      case 'encours':
      case 'en cours':
        return ProductionStatus.inProgress;
      case '2':
      case 'completed':
      case 'terminé':
      case 'termine':
        return ProductionStatus.completed;
      case '3':
      case 'validated':
      case 'validé':
      case 'valide':
        return ProductionStatus.validated;
      case '4':
      case 'cancelled':
      case 'canceled':
      case 'annulé':
      case 'annule':
        return ProductionStatus.cancelled;
      default:
        return ProductionStatus.planned;
    }
  }

  /// Maps the enum back to the backend integer value for query parameters.
  int get toInt {
    switch (this) {
      case ProductionStatus.planned:
        return 0;
      case ProductionStatus.inProgress:
        return 1;
      case ProductionStatus.completed:
        return 2;
      case ProductionStatus.validated:
        return 3;
      case ProductionStatus.cancelled:
        return 4;
    }
  }

  /// French display label matching web app conventions in fo-acya-app/elance-app.ui.
  String get label {
    switch (this) {
      case ProductionStatus.planned:
        return 'Planifié';
      case ProductionStatus.inProgress:
        return 'En cours';
      case ProductionStatus.completed:
        return 'Terminé';
      case ProductionStatus.validated:
        return 'Validé';
      case ProductionStatus.cancelled:
        return 'Annulé';
    }
  }
}

/// Execution status of an individual production fabrication step.
/// Mirrors C# backend enum [ms.webapp.api.acya.core.Entities.Production.ProductionStepStatus].
enum ProductionStepStatus {
  planned,
  inProgress,
  completed,
  cancelled;

  /// Robust parser accepting both string representation and integer ordinal indices.
  static ProductionStepStatus fromDynamic(dynamic val) {
    if (val == null) return ProductionStepStatus.planned;
    if (val is int) {
      switch (val) {
        case 0:
          return ProductionStepStatus.planned;
        case 1:
          return ProductionStepStatus.inProgress;
        case 2:
          return ProductionStepStatus.completed;
        case 3:
          return ProductionStepStatus.cancelled;
        default:
          return ProductionStepStatus.planned;
      }
    }
    final s = val.toString().trim().toLowerCase();
    switch (s) {
      case '0':
      case 'planned':
      case 'enattente':
      case 'en attente':
        return ProductionStepStatus.planned;
      case '1':
      case 'inprogress':
      case 'in_progress':
      case 'encours':
      case 'en cours':
        return ProductionStepStatus.inProgress;
      case '2':
      case 'completed':
      case 'achevé':
      case 'acheve':
      case 'terminé':
        return ProductionStepStatus.completed;
      case '3':
      case 'cancelled':
      case 'canceled':
      case 'annulé':
        return ProductionStepStatus.cancelled;
      default:
        return ProductionStepStatus.planned;
    }
  }

  /// French display label matching step badge design.
  String get label {
    switch (this) {
      case ProductionStepStatus.planned:
        return 'En attente';
      case ProductionStepStatus.inProgress:
        return 'En cours';
      case ProductionStepStatus.completed:
        return 'Achevé';
      case ProductionStepStatus.cancelled:
        return 'Annulé';
    }
  }
}

/// Represents an individual fabrication step within a production order.
/// Sourced from backend [ProductionStepDto].
class ProductionStep {
  final int id;
  final String guid;
  final int productionOrderId;
  final int stepNumber;
  final String name;
  final String? description;
  final ProductionStepStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? laborCost;
  final double? employeeLaborCost;
  final double? otherCost;
  final double? materialCost;
  final double? totalStepCost;
  final int? outputMerchandiseId;
  final String? outputMerchandiseRef;
  final String? outputMerchandiseDesignation;
  final double plannedOutputQuantity;
  final double? actualOutputQuantity;

  ProductionStep({
    required this.id,
    this.guid = '',
    this.productionOrderId = 0,
    required this.stepNumber,
    required this.name,
    this.description,
    this.status = ProductionStepStatus.planned,
    this.startDate,
    this.endDate,
    this.laborCost,
    this.employeeLaborCost,
    this.otherCost,
    this.materialCost,
    this.totalStepCost,
    this.outputMerchandiseId,
    this.outputMerchandiseRef,
    this.outputMerchandiseDesignation,
    this.plannedOutputQuantity = 1.0,
    this.actualOutputQuantity,
  });

  /// Factory deserializer safely handling nulls and numeric type conversions.
  factory ProductionStep.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return ProductionStep(
      id: json['id'] as int? ?? json['Id'] as int? ?? 0,
      guid: json['guid']?.toString() ?? json['Guid']?.toString() ?? '',
      productionOrderId:
          json['productionOrderId'] as int? ??
          json['ProductionOrderId'] as int? ??
          0,
      stepNumber: json['stepNumber'] as int? ?? json['StepNumber'] as int? ?? 1,
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      description:
          json['description']?.toString() ?? json['Description']?.toString(),
      status: ProductionStepStatus.fromDynamic(
        json['status'] ?? json['Status'],
      ),
      startDate: parseDate(json['startDate'] ?? json['StartDate']),
      endDate: parseDate(json['endDate'] ?? json['EndDate']),
      laborCost: parseDouble(json['laborCost'] ?? json['LaborCost']),
      employeeLaborCost: parseDouble(
        json['employeeLaborCost'] ?? json['EmployeeLaborCost'],
      ),
      otherCost: parseDouble(json['otherCost'] ?? json['OtherCost']),
      materialCost: parseDouble(json['materialCost'] ?? json['MaterialCost']),
      totalStepCost: parseDouble(
        json['totalStepCost'] ?? json['TotalStepCost'],
      ),
      outputMerchandiseId:
          json['outputMerchandiseId'] as int? ??
          json['OutputMerchandiseId'] as int?,
      outputMerchandiseRef:
          json['outputMerchandiseRef']?.toString() ??
          json['OutputMerchandiseRef']?.toString(),
      outputMerchandiseDesignation:
          json['outputMerchandiseDesignation']?.toString() ??
          json['OutputMerchandiseDesignation']?.toString(),
      plannedOutputQuantity:
          parseDouble(
            json['plannedOutputQuantity'] ?? json['PlannedOutputQuantity'],
          ) ??
          1.0,
      actualOutputQuantity: parseDouble(
        json['actualOutputQuantity'] ?? json['ActualOutputQuantity'],
      ),
    );
  }
}

/// Represents a production manufacturing order (Ordre de Fabrication).
/// Sourced from backend [ProductionOrderDto].
class ProductionOrder {
  final int id;
  final String guid;
  final String reference;
  final String? description;
  final String? notes;
  final int salesSiteId;
  final String? salesSiteName;
  final ProductionStatus status;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final double? totalMaterialCost;
  final double? totalLaborCost;
  final double? totalOtherCost;
  final double? totalProductionCost;
  final double? unitProductionCost;
  final double plannedOutputQuantity;
  final double? actualOutputQuantity;
  final int createdById;
  final String? createdByName;
  final DateTime? creationDate;
  final DateTime? updateDate;
  final List<ProductionStep> steps;

  ProductionOrder({
    required this.id,
    this.guid = '',
    required this.reference,
    this.description,
    this.notes,
    this.salesSiteId = 0,
    this.salesSiteName,
    this.status = ProductionStatus.planned,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    this.totalMaterialCost,
    this.totalLaborCost,
    this.totalOtherCost,
    this.totalProductionCost,
    this.unitProductionCost,
    this.plannedOutputQuantity = 1.0,
    this.actualOutputQuantity,
    this.createdById = 0,
    this.createdByName,
    this.creationDate,
    this.updateDate,
    this.steps = const [],
  });

  /// Factory deserializer safely handling nullable dates, costs, steps, and case differences.
  factory ProductionOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    // Handle nested steps array
    final rawSteps = json['steps'] ?? json['Steps'];
    final stepsList = (rawSteps is List)
        ? rawSteps
              .whereType<Map<String, dynamic>>()
              .map((s) => ProductionStep.fromJson(s))
              .toList()
        : <ProductionStep>[];

    return ProductionOrder(
      id: json['id'] as int? ?? json['Id'] as int? ?? 0,
      guid: json['guid']?.toString() ?? json['Guid']?.toString() ?? '',
      reference:
          json['reference']?.toString() ?? json['Reference']?.toString() ?? '',
      description:
          json['description']?.toString() ?? json['Description']?.toString(),
      notes: json['notes']?.toString() ?? json['Notes']?.toString(),
      salesSiteId:
          json['salesSiteId'] as int? ?? json['SalesSiteId'] as int? ?? 0,
      salesSiteName:
          json['salesSiteName']?.toString() ??
          json['SalesSiteName']?.toString(),
      status: ProductionStatus.fromDynamic(json['status'] ?? json['Status']),
      plannedStartDate: parseDate(
        json['plannedStartDate'] ?? json['PlannedStartDate'],
      ),
      plannedEndDate: parseDate(
        json['plannedEndDate'] ?? json['PlannedEndDate'],
      ),
      actualStartDate: parseDate(
        json['actualStartDate'] ?? json['ActualStartDate'],
      ),
      actualEndDate: parseDate(json['actualEndDate'] ?? json['ActualEndDate']),
      totalMaterialCost: parseDouble(
        json['totalMaterialCost'] ?? json['TotalMaterialCost'],
      ),
      totalLaborCost: parseDouble(
        json['totalLaborCost'] ?? json['TotalLaborCost'],
      ),
      totalOtherCost: parseDouble(
        json['totalOtherCost'] ?? json['TotalOtherCost'],
      ),
      totalProductionCost: parseDouble(
        json['totalProductionCost'] ?? json['TotalProductionCost'],
      ),
      unitProductionCost: parseDouble(
        json['unitProductionCost'] ?? json['UnitProductionCost'],
      ),
      plannedOutputQuantity:
          parseDouble(
            json['plannedOutputQuantity'] ?? json['PlannedOutputQuantity'],
          ) ??
          1.0,
      actualOutputQuantity: parseDouble(
        json['actualOutputQuantity'] ?? json['ActualOutputQuantity'],
      ),
      createdById:
          json['createdById'] as int? ?? json['CreatedById'] as int? ?? 0,
      createdByName:
          json['createdByName']?.toString() ??
          json['CreatedByName']?.toString(),
      creationDate: parseDate(json['creationDate'] ?? json['CreationDate']),
      updateDate: parseDate(json['updateDate'] ?? json['UpdateDate']),
      steps: stepsList,
    );
  }
}
