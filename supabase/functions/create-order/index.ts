import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      {
        status: 405,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }

  try {
    const body = await req.json();

    const amount = Number(body.amount);
    const currency = body.currency ?? "INR";
    const userId = body.user_id ?? null;
    const userDetails = body.user_details ?? {};

    if (!Number.isFinite(amount) || amount <= 0) {
      return new Response(
        JSON.stringify({
          error: "Invalid donation amount",
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    if (currency !== "INR" && currency !== "USD") {
      return new Response(
        JSON.stringify({
          error: "Only INR and USD are currently supported",
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const razorpayKeyId = Deno.env.get("RAZORPAY_KEY_ID");
    const razorpayKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET");

    if (!razorpayKeyId || !razorpayKeySecret) {
      console.error("Razorpay credentials are missing");

      return new Response(
        JSON.stringify({
          error: "Payment service is not configured",
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    /*
     * Razorpay expects amount in the smallest currency unit.
     * Example:
     * ₹50 = 5000 paise
     */
    const amountInPaise = Math.round(amount * 100);

    if (amountInPaise < 100) {
      return new Response(
        JSON.stringify({
          error: "Minimum donation amount is ₹1",
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const auth = btoa(
      `${razorpayKeyId}:${razorpayKeySecret}`,
    );

    const receipt = `rcpt_${Date.now()}_${Math.floor(Math.random() * 10000)}`;

    const razorpayResponse = await fetch(
      "https://api.razorpay.com/v1/orders",
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${auth}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          amount: amountInPaise,
          currency,
          receipt,
          notes: {
            donor_name: userDetails.name ?? "Anonymous",
            donor_email: userDetails.email ?? "",
          },
        }),
      },
    );

    const razorpayData = await razorpayResponse.json();

    if (!razorpayResponse.ok) {
      console.error(
        "Razorpay order creation failed:",
        razorpayData,
      );

      return new Response(
        JSON.stringify({
          error:
            razorpayData?.error?.description ??
            "Failed to create Razorpay order",
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    /*
     * Use Supabase server-side credentials.
     */
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get(
      "SERVICE_ROLE_KEY_SUPABASE",
    );

    if (!supabaseUrl || !serviceRoleKey) {
      console.error("Supabase server credentials are missing");

      return new Response(
        JSON.stringify({
          error: "Database service is not configured",
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const supabase = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      },
    );

    const { error: donationError } = await supabase
      .from("donations")
      .insert({
        user_id: userId,
        amount,
        currency,
        razorpay_order_id: razorpayData.id,
        status: "created",
      });

    if (donationError) {
      console.error(
        "Failed to save donation:",
        donationError,
      );

      return new Response(
        JSON.stringify({
          error: "Failed to create donation record",
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        order_id: razorpayData.id,
        amount: amountInPaise,
        currency,
        key_id: razorpayKeyId,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (error) {
    console.error("create-order error:", error);

    return new Response(
      JSON.stringify({
        error: "Internal server error",
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }
});