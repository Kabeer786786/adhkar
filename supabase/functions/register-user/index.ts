import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Regex patterns for validation
const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const PHONE_REGEX = /^\+?[0-9\s-]{7,20}$/;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ success: false, error: "Method not allowed" }),
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

    const rawName = (body.name ?? "").toString().trim();
    const rawEmail = (body.email ?? "").toString().trim().toLowerCase();
    const rawPhone = (body.phone ?? "").toString().trim();
    const rawLocation = (body.location ?? "").toString().trim() || "Unknown Location";

    // 1. Validate Name
    if (!rawName || rawName.length < 2) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Please provide a valid full name (at least 2 characters)",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 2. Validate Email with Regex
    if (!rawEmail || !EMAIL_REGEX.test(rawEmail)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Please provide a valid email address (e.g. name@example.com)",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 3. Validate Phone with Regex (allowing optional + and separators, requiring 7-15 digits)
    const digitsOnly = rawPhone.replace(/\D/g, "");
    if (!rawPhone || !PHONE_REGEX.test(rawPhone) || digitsOnly.length < 7 || digitsOnly.length > 15) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Please provide a valid phone number (7 to 15 digits)",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 4. Initialize Supabase Admin Client
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey =
      Deno.env.get("SERVICE_ROLE_KEY_SUPABASE") ??
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      console.error("Supabase server credentials are missing in Edge Function environment");
      return new Response(
        JSON.stringify({
          success: false,
          error: "Database service is not configured",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const nowIso = new Date().toISOString();

    // 5. Check if profile already exists by email
    const { data: existingProfile, error: searchError } = await supabase
      .from("profiles")
      .select("id, name, email, phone, location, created_at, updated_at")
      .eq("email", rawEmail)
      .maybeSingle();

    if (searchError) {
      console.error("Error checking existing profile:", searchError);
    }

    let savedProfile;

    if (existingProfile && existingProfile.id) {
      // Update existing profile
      const { data: updatedData, error: updateError } = await supabase
        .from("profiles")
        .update({
          name: rawName,
          phone: rawPhone,
          location: rawLocation,
          updated_at: nowIso,
        })
        .eq("id", existingProfile.id)
        .select()
        .single();

      if (updateError) {
        console.error("Error updating profile:", updateError);
        throw updateError;
      }
      savedProfile = updatedData;
    } else {
      // Insert new profile
      const { data: insertedData, error: insertError } = await supabase
        .from("profiles")
        .insert({
          name: rawName,
          email: rawEmail,
          phone: rawPhone,
          location: rawLocation,
          created_at: nowIso,
          updated_at: nowIso,
        })
        .select()
        .single();

      if (insertError) {
        console.error("Error inserting profile:", insertError);
        throw insertError;
      }
      savedProfile = insertedData;
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "User registered successfully",
        profile: {
          id: savedProfile.id,
          name: savedProfile.name,
          email: savedProfile.email,
          phone: savedProfile.phone,
          location: savedProfile.location,
        },
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("Unexpected error in register-user Edge Function:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: (error as Error)?.message ?? "Internal server error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
