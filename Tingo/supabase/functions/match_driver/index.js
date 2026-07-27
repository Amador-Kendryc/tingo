// Supabase Edge Function: Match Driver (Algoritmo de Asignación por Proximidad PostGIS)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  try {
    const { trip_id, passenger_lat, passenger_lng, search_radius_km = 5.0 } = await req.json()

    if (!trip_id || !passenger_lat || !passenger_lng) {
      return new Response(
        JSON.stringify({ error: 'Faltan parámetros requeridos (trip_id, passenger_lat, passenger_lng)' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Invocar función espacial PostGIS para hallar conductores disponibles más cercanos
    const { data: nearbyDrivers, error: geoError } = await supabase.rpc('fn_get_nearby_drivers', {
      passenger_lat: parseFloat(passenger_lat),
      passenger_lng: parseFloat(passenger_lng),
      radius_km: parseFloat(search_radius_km)
    })

    if (geoError) {
      throw geoError
    }

    if (!nearbyDrivers || nearbyDrivers.length === 0) {
      // Ningún conductor cercano disponible
      await supabase
        .from('trips')
        .update({ status: 'CANCELLED', cancellation_reason: 'Sin conductores disponibles cercanos' })
        .eq('id', trip_id)

      return new Response(
        JSON.stringify({ success: false, message: 'No hay conductores disponibles cercanos.' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 2. Seleccionar el conductor más cercano (primer elemento ordenado por distancia)
    const selectedDriver = nearbyDrivers[0]

    // 3. Actualizar viaje a estado MATCHING con el conductor seleccionado
    const { error: updateError } = await supabase
      .from('trips')
      .update({
        driver_id: selectedDriver.driver_id,
        status: 'MATCHING'
      })
      .eq('id', trip_id)

    if (updateError) throw updateError

    // 4. Retornar los detalles del conductor asignado para notificación Realtime/WebSocket
    return new Response(
      JSON.stringify({
        success: true,
        trip_id,
        matched_driver: selectedDriver,
        candidate_count: nearbyDrivers.length
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
