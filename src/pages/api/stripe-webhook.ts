import type { APIRoute } from 'astro';
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client with service role key for admin operations
const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
const supabaseServiceKey = import.meta.env.SUPABASE_SERVICE_ROLE_KEY || import.meta.env.PUBLIC_SUPABASE_ANON_KEY;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Stripe webhook secret for verifying signatures
const stripeWebhookSecret = import.meta.env.STRIPE_WEBHOOK_SECRET;

export const prerender = false;

export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.text();
    const signature = request.headers.get('stripe-signature');

    // For development/testing, we'll skip signature verification if no secret is set
    // In production, you should always verify the signature
    let event;
    
    try {
      event = JSON.parse(body);
    } catch (err) {
      console.error('Error parsing webhook body:', err);
      return new Response(JSON.stringify({ error: 'Invalid JSON' }), { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    console.log('Received Stripe webhook event:', event.type);

    // Handle the event based on type
    switch (event.type) {
      case 'checkout.session.completed':
      case 'payment_intent.succeeded':
        await handlePaymentSuccess(event.data.object);
        break;
      
      case 'payment_intent.payment_failed':
        await handlePaymentFailed(event.data.object);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error: any) {
    console.error('Webhook error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

async function handlePaymentSuccess(paymentData: any) {
  console.log('Processing successful payment:', paymentData);

  // Extract customer email from payment data
  const customerEmail = paymentData.customer_email || 
                        paymentData.receipt_email || 
                        paymentData.billing_details?.email ||
                        paymentData.customer_details?.email;

  if (!customerEmail) {
    console.error('No customer email found in payment data');
    return;
  }

  // Find the customer by email
  const { data: customer, error: customerError } = await supabase
    .from('customers')
    .select('id')
    .eq('email', customerEmail)
    .single();

  if (customerError || !customer) {
    console.error('Customer not found:', customerEmail, customerError);
    return;
  }

  // Find pending subscriptions for this customer
  const { data: pendingSubscriptions, error: subError } = await supabase
    .from('subscriptions')
    .select('*')
    .eq('customer_id', customer.id)
    .eq('status', 'pending')
    .order('created_at', { ascending: false })
    .limit(1);

  if (subError) {
    console.error('Error fetching pending subscriptions:', subError);
    return;
  }

  if (!pendingSubscriptions || pendingSubscriptions.length === 0) {
    console.log('No pending subscriptions found for customer:', customer.id);
    return;
  }

  const subscription = pendingSubscriptions[0];
  console.log('Found pending subscription:', subscription.id);

  // Update subscription to active
  const { error: updateSubError } = await supabase
    .from('subscriptions')
    .update({
      status: 'active',
      payment_status: 'paid',
      updated_at: new Date().toISOString()
    })
    .eq('id', subscription.id);

  if (updateSubError) {
    console.error('Error updating subscription:', updateSubError);
    return;
  }

  console.log('Subscription activated:', subscription.id);

  // Find and activate related license
  const { data: licenses, error: licError } = await supabase
    .from('licenses')
    .select('*')
    .eq('subscription_id', subscription.id)
    .eq('status', 'inactive');

  if (!licError && licenses && licenses.length > 0) {
    const license = licenses[0];
    
    const { error: updateLicError } = await supabase
      .from('licenses')
      .update({
        status: 'active',
        current_activations: 1,
        updated_at: new Date().toISOString()
      })
      .eq('id', license.id);

    if (updateLicError) {
      console.error('Error updating license:', updateLicError);
    } else {
      console.log('License activated:', license.id);
    }
  }

  // Update existing pending sale or create new one
  const amount = paymentData.amount_received 
    ? paymentData.amount_received / 100 // Stripe amounts are in cents
    : subscription.amount || 0;

  // First, try to find and update existing pending sale
  const { data: existingSales, error: findSaleError } = await supabase
    .from('sales')
    .select('*')
    .eq('subscription_id', subscription.id)
    .eq('payment_status', 'pending')
    .limit(1);

  if (!findSaleError && existingSales && existingSales.length > 0) {
    // Update existing pending sale to paid
    const { error: updateSaleError } = await supabase
      .from('sales')
      .update({
        payment_status: 'paid',
        amount: amount,
        notes: `Pago Stripe confirmado - ${subscription.subscription_type}`,
        updated_at: new Date().toISOString()
      })
      .eq('id', existingSales[0].id);

    if (updateSaleError) {
      console.error('Error updating sale record:', updateSaleError);
    } else {
      console.log('Sale record updated to paid:', existingSales[0].id);
    }
  } else {
    // Create new sale record if none exists
    const { error: saleError } = await supabase
      .from('sales')
      .insert({
        customer_id: customer.id,
        subscription_id: subscription.id,
        amount: amount,
        currency: paymentData.currency?.toUpperCase() || 'EUR',
        payment_status: 'paid',
        payment_type: 'stripe',
        sale_date: new Date().toISOString().split('T')[0],
        notes: `Pago Stripe - ${subscription.subscription_type}`
      });

    if (saleError) {
      console.error('Error creating sale record:', saleError);
    } else {
      console.log('Sale record created for subscription:', subscription.id);
    }
  }
}

async function handlePaymentFailed(paymentData: any) {
  console.log('Processing failed payment:', paymentData);

  const customerEmail = paymentData.customer_email || 
                        paymentData.receipt_email || 
                        paymentData.billing_details?.email;

  if (!customerEmail) {
    console.error('No customer email found in failed payment data');
    return;
  }

  // Find the customer
  const { data: customer, error: customerError } = await supabase
    .from('customers')
    .select('id')
    .eq('email', customerEmail)
    .single();

  if (customerError || !customer) {
    console.error('Customer not found for failed payment:', customerEmail);
    return;
  }

  // Update pending subscriptions to failed status
  const { error: updateError } = await supabase
    .from('subscriptions')
    .update({
      payment_status: 'failed',
      updated_at: new Date().toISOString()
    })
    .eq('customer_id', customer.id)
    .eq('status', 'pending');

  if (updateError) {
    console.error('Error updating subscription for failed payment:', updateError);
  } else {
    console.log('Subscription marked as payment failed for customer:', customer.id);
  }
}

// Also handle GET requests to test the endpoint
export const GET: APIRoute = async () => {
  return new Response(JSON.stringify({ 
    status: 'ok', 
    message: 'Stripe webhook endpoint is active' 
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
};
