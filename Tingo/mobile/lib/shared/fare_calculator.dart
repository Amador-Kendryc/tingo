/// CALCULADORA LOCAL DE TARIFAS (Tingo $0/Mes)
/// Ejecuta el cálculo en el teléfono del usuario para no sobrecargar el servidor backend.

class FareCalculator {
  static const double defaultBaseFare = 2.50;
  static const double defaultCostPerKm = 0.85;
  static const double defaultCostPerMin = 0.20;
  static const double defaultMinFare = 3.50;

  /// Calcula la tarifa estimada para el viaje
  static double calculateEstimatedFare({
    required double distanceKm,
    required double durationMinutes,
    double baseFare = defaultBaseFare,
    double costPerKm = defaultCostPerKm,
    double costPerMin = defaultCostPerMin,
    double minFare = defaultMinFare,
  }) {
    double fare = baseFare + (distanceKm * costPerKm) + (durationMinutes * costPerMin);
    if (fare < minFare) {
      fare = minFare;
    }
    return double.parse(fare.toStringAsFixed(2));
  }

  /// Calcula el desglose entre Ganancia del Conductor y Comisión de Tingo (15%)
  static Map<String, double> calculateBreakdown(double totalFare, {double commissionPercent = 15.0}) {
    double commission = double.parse((totalFare * (commissionPercent / 100.0)).toStringAsFixed(2));
    double driverEarnings = double.parse((totalFare - commission).toStringAsFixed(2));

    return {
      'total': totalFare,
      'commission': commission,
      'driver_earnings': driverEarnings,
    };
  }
}
