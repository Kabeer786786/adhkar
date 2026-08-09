import { createClient } from "npm:@supabase/supabase-js@2";

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

  return Array.from(
    new Uint8Array(signature),
  )
    .map((byte) =>
      byte.toString(16).padStart(2, "0")
    )
    .join("");
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
  try {
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({
          error: "Method not allowed",
        }),
        {
          status: 405,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    const webhookSecret = Deno.env.get(
      "RAZORPAY_WEBHOOK_SECRET",
    );

    const signature = req.headers.get(
      "x-razorpay-signature",
    );

    if (!webhookSecret || !signature) {
      return new Response(
        JSON.stringify({
          error: "Webhook configuration error",
        }),
        {
          status: 400,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    /*
     * IMPORTANT:
     *
     * Razorpay webhook signature must be calculated
     * against the exact raw request body.
     */
    const rawBody = await req.text();

    const expectedSignature = await generateHmac(
      webhookSecret,
      rawBody,
    );

    if (
      !safeEqual(
        expectedSignature,
        signature,
      )
    ) {
      console.error(
        "Invalid Razorpay webhook signature",
      );

      return new Response(
        JSON.stringify({
          error: "Invalid webhook signature",
        }),
        {
          status: 400,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    const payload = JSON.parse(rawBody);

    const event = payload.event;

    const supabaseUrl = Deno.env.get(
      "SUPABASE_URL",
    );

    const serviceRoleKey = Deno.env.get(
      "SERVICE_ROLE_KEY_SUPABASE",
    );

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({
          error: "Database configuration error",
        }),
        {
          status: 500,
          headers: {
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
     * Handle successful captured payments.
     */
    if (event === "payment.captured") {
      const payment =
        payload.payload?.payment?.entity;

      const paymentId = payment?.id;
      const orderId = payment?.order_id;

      if (!paymentId || !orderId) {
        return new Response(
          JSON.stringify({
            error: "Invalid payment webhook payload",
          }),
          {
            status: 400,
            headers: {
              "Content-Type": "application/json",
            },
          },
        );
      }

      /*
       * Idempotency:
       *
       * If Razorpay sends the same webhook again,
       * updating the same record is safe.
       */
      const { error } = await supabase
        .from("donations")
        .update({
          razorpay_payment_id: paymentId,
          status: "successful",
        })
        .eq(
          "razorpay_order_id",
          orderId,
        );

      if (error) {
        console.error(
          "Donation webhook update failed:",
          error,
        );

        return new Response(
          JSON.stringify({
            error: "Database update failed",
          }),
          {
            status: 500,
            headers: {
              "Content-Type": "application/json",
            },
          },
        );
      }
    }

    /*
     * Handle failed payments.
     */
    if (event === "payment.failed") {
      const payment =
        payload.payload?.payment?.entity;

      const paymentId = payment?.id;
      const orderId = payment?.order_id;

      if (orderId) {
        await supabase
          .from("donations")
          .update({
            razorpay_payment_id:
              paymentId ?? null,
            status: "failed",
          })
          .eq(
            "razorpay_order_id",
            orderId,
          );
      }
    }

    return new Response(
      JSON.stringify({
        status: "ok",
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  } catch (error) {
    console.error(
      "razorpay-webhook error:",
      error,
    );

    return new Response(
      JSON.stringify({
        error: "Internal server error",
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
        },
      },
    );
  }
});