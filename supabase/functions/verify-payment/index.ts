import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

async function generateHmac(
  secret: string,
  message: string,
): Promise<string> {
  const encoder = new TextEncoder();

  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    {
      name: "HMAC",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(message),
  );

  return bytesToHex(new Uint8Array(signature));
}

function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }

  let result = 0;

  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }

  return result === 0;
}

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
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
    } = await req.json();

    if (
      !razorpay_order_id ||
      !razorpay_payment_id ||
      !razorpay_signature
    ) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing payment verification details",
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

    const razorpaySecret = Deno.env.get(
      "RAZORPAY_KEY_SECRET",
    );

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get(
      "SERVICE_ROLE_KEY_SUPABASE",
    );

    if (
      !razorpaySecret ||
      !supabaseUrl ||
      !serviceRoleKey
    ) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Server configuration error",
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

    /*
     * IMPORTANT:
     *
     * Do not trust the order ID from Flutter.
     *
     * Find the donation record created by create-order
     * and use the order ID stored in our database.
     */

    const { data: donation, error: donationLookupError } =
      await supabase
        .from("donations")
        .select(
          "id, razorpay_order_id, amount, currency, status",
        )
        .eq(
          "razorpay_order_id",
          razorpay_order_id,
        )
        .maybeSingle();

    if (donationLookupError) {
      console.error(
        "Donation lookup failed:",
        donationLookupError,
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: "Unable to find donation",
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

    if (!donation) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Donation order not found",
        }),
        {
          status: 404,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    /*
     * Prevent accidentally processing an already-successful
     * donation again.
     */
    if (donation.status === "successful") {
      return new Response(
        JSON.stringify({
          success: true,
          message: "Payment already verified",
        }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    /*
     * Razorpay signature:
     *
     * HMAC-SHA256(
     *   order_id + "|" + payment_id,
     *   Razorpay Key Secret
     * )
     */
    const message =
      `${donation.razorpay_order_id}|${razorpay_payment_id}`;

    const generatedSignature = await generateHmac(
      razorpaySecret,
      message,
    );

    if (
      !safeEqual(
        generatedSignature,
        razorpay_signature,
      )
    ) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Invalid payment signature",
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
     * Signature is valid.
     */
    const { error: updateError } = await supabase
      .from("donations")
      .update({
        razorpay_payment_id:
          razorpay_payment_id,
        razorpay_signature:
          razorpay_signature,
        status: "successful",
      })
      .eq("id", donation.id);

    if (updateError) {
      console.error(
        "Donation update failed:",
        updateError,
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: "Failed to update donation",
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
        message: "Payment verified successfully",
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
    console.error("verify-payment error:", error);

    return new Response(
      JSON.stringify({
        success: false,
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