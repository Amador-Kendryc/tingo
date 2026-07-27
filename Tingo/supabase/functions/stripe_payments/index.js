// Supabase Edge Function: Stripe Payment Flow (Pre-autorización, Captura y Liberación)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2022-11-15',
  httpClient: Stripe.createFetchHttpClient(),
})

Deno.serve(async (req) => {
  try {
    const { action, trip_id, amount_cents, payment_method_id, customer_id } = await req.json()
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // ACCIÓN 1: PRE-AUTORIZAR RETENCIÓN EN TARJETA (Al solicitar el viaje)
    if (action === 'PRE_AUTHORIZE') {
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount_cents),
        currency: 'usd',
        payment_method: payment_method_id,
        customer: customer_id,
        capture_method: 'manual', // Retención manual (no cobra inmediatamente)
        confirm: true,
        off_session: true,
      })

      await supabase
        .from('trips')
        .update({
          stripe_payment_intent_id: paymentIntent.id,
          pay_status: 'AUTHORIZED'
        })
        .eq('id', trip_id)

      return new Response(
        JSON.stringify({ success: true, payment_intent_id: paymentIntent.id, status: 'AUTHORIZED' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // ACCIÓN 2: CAPTURA DEFINITIVA DE DINERO (Al finalizar el viaje)
    if (action === 'CAPTURE') {
      const { data: trip } = await supabase.from('trips').select('stripe_payment_intent_id').eq('id', trip_id).single()
      
      if (!trip || !trip.stripe_payment_intent_id) {
        return new Response(JSON.stringify({ error: 'Payment Intent no encontrado para este viaje' }), { status: 400 })
      }

      const capturedIntent = await stripe.paymentIntents.capture(trip.stripe_payment_intent_id, {
        amount_to_capture: Math.round(amount_cents)
      })

      await supabase
        .from('trips')
        .update({ pay_status: 'CAPTURED' })
        .eq('id', trip_id)

      return new Response(
        JSON.stringify({ success: true, payment_intent_id: capturedIntent.id, status: 'CAPTURED' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // ACCIÓN 3: LIBERAR RETENCIÓN SIN COBRO (Al cancelar viaje)
    if (action === 'RELEASE_HOLD') {
      const { data: trip } = await supabase.from('trips').select('stripe_payment_intent_id').eq('id', trip_id).single()

      if (trip && trip.stripe_payment_intent_id) {
        await stripe.paymentIntents.cancel(trip.stripe_payment_intent_id)
        await supabase
          .from('trips')
          .update({ pay_status: 'RELEASED' })
          .eq('id', trip_id)
      }

      return new Response(
        JSON.stringify({ success: true, status: 'RELEASED' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    return new Response(JSON.stringify({ error: 'Acción no válida' }), { status: 400 })
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
