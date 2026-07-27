/**
 * TINGO BACKEND - SERVIDOR DE LÓGICA & MATCHING (Node.js + Socket.io)
 * Diseñado para alojar gratis en Render.com ($0/mes)
 */

// Polyfill para WebSockets nativo requerido por Supabase JS SDK en Node
global.WebSocket = require('ws');

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});

app.use(cors());
app.use(express.json());

// Configuración de cliente Supabase
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://xyz.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'service-role-key-placeholder';
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// Health check endpoint para Render.com
app.get('/', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'Tingo Backend Brain ($0/mes)',
    timestamp: new Date().toISOString()
  });
});

// Endpoint: Cotizar tarifa localmente
app.post('/api/calculate-fare', async (req, res) => {
  try {
    const { distance_km, duration_min } = req.body;
    
    // Obtener parámetros globales de Supabase
    const { data: settings } = await supabase
      .from('system_settings')
      .select('*')
      .eq('id', 1)
      .single();

    const baseFare = settings ? parseFloat(settings.base_fare) : 2.50;
    const costPerKm = settings ? parseFloat(settings.cost_per_km) : 0.85;
    const costPerMin = settings ? parseFloat(settings.cost_per_minute) : 0.20;
    const minFare = settings ? parseFloat(settings.minimum_fare) : 3.50;

    let total = baseFare + (distance_km * costPerKm) + (duration_min * costPerMin);
    if (total < minFare) total = minFare;

    res.json({
      success: true,
      estimated_fare: parseFloat(total.toFixed(2)),
      currency: 'USD',
      breakdown: { baseFare, costPerKm, costPerMin, minFare }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// WEBSOCKETS EN TIEMPO REAL
io.on('connection', (socket) => {
  console.log(`🔌 Dispositivo conectado: ${socket.id}`);

  // 1. Conductor transmite su posición GPS (optimizado cada 20m)
  socket.on('driver_location_update', async (data) => {
    const { driver_id, lat, lng, heading, is_online } = data;
    if (!driver_id || !lat || !lng) return;

    try {
      // Reenviar posición a pasajeros escuchando la zona (Canal Realtime)
      socket.broadcast.emit(`driver_${driver_id}_position`, { lat, lng, heading });

      // Guardar en Supabase PostGIS
      await supabase.from('driver_locations').upsert({
        driver_id,
        location: `POINT(${lng} ${lat})`,
        heading,
        is_online: is_online ?? true,
        updated_at: new Date().toISOString()
      });
    } catch (err) {
      console.error('Error actualizando ubicación:', err.message);
    }
  });

  // 2. Conductor acepta viaje en el radar (dentro del temporizador de 15-30s)
  socket.on('accept_trip', async ({ trip_id, driver_id }) => {
    try {
      const { data: updatedTrip, error } = await supabase
        .from('trips')
        .update({
          driver_id,
          status: 'ACCEPTED',
          accepted_at: new Date().toISOString()
        })
        .eq('id', trip_id)
        .select('*, passenger:profiles!passenger_id(*), driver:profiles!driver_id(*)')
        .single();

      if (!error && updatedTrip) {
        // Notificar a pasajero y conductor
        io.emit(`trip_${trip_id}_status`, { status: 'ACCEPTED', trip: updatedTrip });
        console.log(`✅ Viaje ${trip_id} ACEPTADO por conductor ${driver_id}`);
      }
    } catch (err) {
      console.error('Error al aceptar viaje:', err.message);
    }
  });

  // 3. Transiciones de Estado del Viaje ('ARRIVED' -> 'IN_PROGRESS' -> 'COMPLETED' -> 'CANCELLED')
  socket.on('update_trip_status', async ({ trip_id, status, cancellation_reason }) => {
    try {
      const updatePayload = { status };
      if (status === 'STARTED' || status === 'IN_PROGRESS') updatePayload.started_at = new Date().toISOString();
      if (status === 'COMPLETED') updatePayload.completed_at = new Date().toISOString();
      if (status === 'CANCELLED') updatePayload.cancellation_reason = cancellation_reason || 'Cancelado por usuario';

      const { data: trip } = await supabase
        .from('trips')
        .update(updatePayload)
        .eq('id', trip_id)
        .select('*')
        .single();

      io.emit(`trip_${trip_id}_status`, { status, trip });
    } catch (err) {
      console.error('Error actualizando estado de viaje:', err.message);
    }
  });

  socket.on('disconnect', () => {
    console.log(`❌ Dispositivo desconectado: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Servidor Tingo Cerebro ejecutándose en puerto ${PORT}`);
});
