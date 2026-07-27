import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const TingoDriverApp());
}

class TingoDriverApp extends StatelessWidget {
  const TingoDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tingo - Conductor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981), // Verde para conductor
          surface: Color(0xFF111827),
        ),
      ),
      home: const DriverHomeScreen(),
    );
  }
}

enum DriverTripState { OFF_LINE, IDLE_ONLINE, RADAR_ALERT, PICKUP, IN_TRIP, COMPLETED }

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool isOnline = true;
  DriverTripState state = DriverTripState.IDLE_ONLINE;
  int timerSeconds = 20;
  Timer? radarTimer;

  // Resumen de Ganancias
  double todayEarnings = 42.80;
  double weeklyEarnings = 285.50;
  double cashReceived = 18.00;
  double stripeBalance = 267.50;

  final Map<String, dynamic> incomingTrip = {
    'id': 'TRIP-9921',
    'passenger_name': 'Laura Gutiérrez',
    'rating': 4.95,
    'pickup': 'Polanco, Av. Horacio 402',
    'dropoff': 'Aeropuerto Terminal 1',
    'fare': 14.50,
    'distance_km': 14.2,
    'duration_min': 28,
  };

  void _toggleOnline(bool value) {
    setState(() {
      isOnline = value;
      state = value ? DriverTripState.IDLE_ONLINE : DriverTripState.OFF_LINE;
    });
  }

  void _simulateIncomingTrip() {
    setState(() {
      state = DriverTripState.RADAR_ALERT;
      timerSeconds = 20;
    });

    radarTimer?.cancel();
    radarTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds > 1) {
        setState(() => timerSeconds--);
      } else {
        timer.cancel();
        if (state == DriverTripState.RADAR_ALERT) {
          setState(() => state = DriverTripState.IDLE_ONLINE);
        }
      }
    });
  }

  void _acceptTrip() {
    radarTimer?.cancel();
    setState(() => state = DriverTripState.PICKUP);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // MAPA DE NAVEGACIÓN PASO A PASO (OPENCENTER)
            Container(
              color: const Color(0xFF151D2A),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.navigation,
                      size: 70,
                      color: isOnline ? Colors.emerald : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isOnline ? 'GPS Conectado • Transmitiendo cada 20m' : 'Conductor Desconectado',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            // HEADER BAR CONDUCTOR (GANANCIAS HOY Y SWITCH CONECTADO)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ganancias Hoy', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('\$$todayEarnings', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.emeraldAccent)),
                      ],
                    ),
                    Row(
                      children: [
                        Text(isOnline ? 'CONECTADO' : 'OFFLINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isOnline ? Colors.emerald : Colors.grey)),
                        const SizedBox(width: 8),
                        Switch(
                          value: isOnline,
                          onChanged: _toggleOnline,
                          activeColor: Colors.emerald,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),

            // BOTÓN PRUEBA RADAR (SIMULACIÓN ALERTA EN VIVO)
            if (state == DriverTripState.IDLE_ONLINE)
              Positioned(
                top: 90,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: _simulateIncomingTrip,
                  icon: const Icon(Icons.bolt, color: Colors.amber),
                  label: const Text('Simular Solicitud RADAR'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F293D)),
                ),
              ),

            // MODAL INFERIOR RADAR DE VIAJE / NAVEGACIÓN PASO A PASO
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: _buildDriverStateContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverStateContent() {
    // ESTADO 1: RADAR DE VIAJE (ALERTA SONORA/VISUAL Y TIMER 15-30s)
    if (state == DriverTripState.RADAR_ALERT) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Text('¡NUEVO VIAJE CERCANO!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.redAccent,
                child: Text('$timerSeconds', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(incomingTrip['passenger_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('★ ${incomingTrip['rating']}', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                ],
              ),
              Text('\$${incomingTrip['fare']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.extrabold, color: Colors.emerald)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Origen: ${incomingTrip['pickup']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text('Destino: ${incomingTrip['dropoff']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => state = DriverTripState.IDLE_ONLINE),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _acceptTrip,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.emerald, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('ACEPTAR VIAJE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                ),
              )
            ],
          )
        ],
      );
    }

    // ESTADO 2: EN RUTA HACIA EL PASAJERO
    if (state == DriverTripState.PICKUP) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Recogiendo al Pasajero', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.emerald)),
          const SizedBox(height: 6),
          Text(incomingTrip['pickup'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => setState(() => state = DriverTripState.IN_TRIP),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.emerald),
              child: const Text('Llegué al Punto ➔ Iniciar Viaje', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      );
    }

    // ESTADO 3: VIAJE EN CURSO Y FINALIZAR
    if (state == DriverTripState.IN_TRIP) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Navegando hacia el Destino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 6),
          Text(incomingTrip['dropoff'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  todayEarnings += incomingTrip['fare'];
                  state = DriverTripState.IDLE_ONLINE;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('FINALIZAR VIAJE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      );
    }

    // ESTADO POR DEFECTO: ESPERANDO VIAJES / BILLETERA
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Billetera y Ganancias (Comisión Tingo 15%)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1F293D), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('Efectivo Recibido', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('\$$cashReceived', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1F293D), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('Saldo Stripe (Tarjetas)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('\$$stripeBalance', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent)),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
