import 'package:flutter/material.dart';
import '../shared/fare_calculator.dart';

void main() {
  runApp(const TingoPassengerApp());
}

class TingoPassengerApp extends StatelessWidget {
  const TingoPassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tingo - Pasajero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF97316),
          secondary: Color(0xFFEA580C),
          surface: Color(0xFF111827),
        ),
        fontFamily: 'Roboto',
      ),
      home: const PassengerHomeScreen(),
    );
  }
}

enum TripStage { IDLE, SEARCHING, DRIVER_ASSIGNED, IN_TRIP, COMPLETED }

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  TripStage currentStage = TripStage.IDLE;
  String destinationAddress = '';
  double estimatedFare = 0.0;
  String selectedPayment = 'CARD'; // 'CASH' or 'CARD'
  int rating = 5;

  final Map<String, dynamic> assignedDriver = {
    'name': 'Carlos Mendoza',
    'rating': 4.9,
    'vehicle': 'Nissan Versa Negro',
    'plate': 'ABC-1234',
    'photo': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    'eta_min': 3,
  };

  void _requestTrip() {
    if (destinationAddress.isEmpty) {
      destinationAddress = 'Aeropuerto Terminal 1, CDMX';
    }
    // Calcular tarifa localmente en el teléfono
    setState(() {
      estimatedFare = FareCalculator.calculateEstimatedFare(
        distanceKm: 8.5,
        durationMinutes: 18,
      );
      currentStage = TripStage.SEARCHING;
    });

    // Simulación: Asignación automática por PostGIS en 3.5 segundos
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted && currentStage == TripStage.SEARCHING) {
        setState(() {
          currentStage = TripStage.DRIVER_ASSIGNED;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPA INTERACTIVO OPENSTREETMAP (SIMULACIÓN VISUAL CLIENTE)
          Container(
            color: const Color(0xFF151D2A),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_rounded,
                    size: 80,
                    color: Colors.orange.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Renderizado Mapas OpenStreetMap ($0/Mes)',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (currentStage == TripStage.DRIVER_ASSIGNED || currentStage == TripStage.IN_TRIP) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.directions_car, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Conductor a 3 min (GPS cada 20m)',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),

          // 2. PANEL SUPERIOR DE NAVEGACIÓN
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF111827),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.shield, color: Colors.emeraldAccent, size: 16),
                      SizedBox(width: 6),
                      Text('Viaje Seguro Tingo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 3. HOJA INFERIOR MODULAR SEGÚN EL ESTADO DEL VIAJE
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)
                ]
              ),
              child: _buildStageContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageContent() {
    // ESTADO 1: INICIO Y SOLICITUD DE VIAJE (PEDIDO EN 3 TOQUES)
    if (currentStage == TripStage.IDLE) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿A dónde vamos hoy?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            onChanged: (val) => destinationAddress = val,
            decoration: InputDecoration(
              hintText: 'Buscar destino (ej: Aeropuerto Terminal 1)',
              prefixIcon: const Icon(Icons.search, color: Colors.orange),
              filled: true,
              fillColor: const Color(0xFF1F293D),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedPayment = 'CARD'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedPayment == 'CARD' ? Colors.orange.withOpacity(0.2) : const Color(0xFF1F293D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedPayment == 'CARD' ? Colors.orange : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.credit_card, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Tarjeta Stripe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedPayment = 'CASH'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedPayment == 'CASH' ? Colors.emerald.withOpacity(0.2) : const Color(0xFF1F293D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedPayment == 'CASH' ? Colors.emerald : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.money, size: 18, color: Colors.emerald),
                        SizedBox(width: 8),
                        Text('Efectivo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _requestTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Pedir Tingo Ahora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      );
    }

    // ESTADO 2: BUSCANDO CONDUCTOR CERCANO CON POSTGIS
    if (currentStage == TripStage.SEARCHING) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.orange),
          const SizedBox(height: 20),
          const Text('Buscando conductor cercano...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Cotización estimada: \$${estimatedFare.toStringAsFixed(2)} | Retención Pre-Autorizada en Stripe',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => setState(() => currentStage = TripStage.IDLE),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
            child: const Text('Cancelar Búsqueda', style: TextStyle(color: Colors.redAccent)),
          )
        ],
      );
    }

    // ESTADO 3: CONDUCTOR ASIGNADO
    if (currentStage == TripStage.DRIVER_ASSIGNED) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.orange,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignedDriver['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${assignedDriver['vehicle']} • ${assignedDriver['plate']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text('${assignedDriver['rating']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('${assignedDriver['eta_min']} MIN', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Llamar'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F293D)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => currentStage = TripStage.COMPLETED),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.emerald),
                  child: const Text('Simular Fin Viaje'),
                ),
              )
            ],
          )
        ],
      );
    }

    // ESTADO 4: POST-VIAJE Y CALIFICACIÓN DE 1 A 5 ESTRELLAS
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.emerald, size: 50),
        const SizedBox(height: 12),
        const Text('¡Has llegado a tu destino!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Cobro realizado: \$${estimatedFare.toStringAsFixed(2)} vía $selectedPayment', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        const Text('Califica a tu conductor:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
              onPressed: () => setState(() => rating = index + 1),
            );
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => setState(() => currentStage = TripStage.IDLE),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
            child: const Text('Finalizar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        )
      ],
    );
  }
}
