import 'dart:convert';
import 'package:http/http.dart' as http;

/// SERVICIO CLIENTE DE PAGOS ($0 CUOTA FIJA MENSUAL)
/// Conecta la App de Flutter con la Edge Function de Supabase para Stripe.
class PaymentService {
  final String supabaseFunctionUrl;

  PaymentService({required this.supabaseFunctionUrl});

  /// 1. Solicita la Pre-Autorización de Fondos (Retención) al pedir el viaje
  Future<Map<String, dynamic>> preAuthorizeTripPayment({
    required String tripId,
    required double amountUsd,
    required String paymentMethodId,
  }) async {
    final response = await http.post(
      Uri.parse('$supabaseFunctionUrl/stripe_payments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'PRE_AUTHORIZE',
        'trip_id': tripId,
        'amount_cents': (amountUsd * 100).round(),
        'payment_method_id': paymentMethodId,
      }),
    );

    return jsonDecode(response.body);
  }

  /// 2. Captura Definitiva del Pago al completar el viaje
  Future<Map<String, dynamic>> captureTripPayment({
    required String tripId,
    required double finalAmountUsd,
  }) async {
    final response = await http.post(
      Uri.parse('$supabaseFunctionUrl/stripe_payments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'CAPTURE',
        'trip_id': tripId,
        'amount_cents': (finalAmountUsd * 100).round(),
      }),
    );

    return jsonDecode(response.body);
  }

  /// 3. Liberar la retención si el viaje se cancela antes de iniciar
  Future<Map<String, dynamic>> releaseHoldPayment({
    required String tripId,
  }) async {
    final response = await http.post(
      Uri.parse('$supabaseFunctionUrl/stripe_payments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'RELEASE_HOLD',
        'trip_id': tripId,
      }),
    );

    return jsonDecode(response.body);
  }
}
