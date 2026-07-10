// supabase/functions/upload-pdf/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.21.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No authorization header provided" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase Client with client's bearer token for RLS validation
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: { headers: { Authorization: authHeader } },
      }
    );

    // Initialize Supabase admin client for database updates (bypassing RLS if necessary, or using policy validation)
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Parse multipart form-data
    const formData = await req.formData();
    const file = formData.get("file") as File | null;
    const quoteId = formData.get("quoteId") as string | null;

    if (!file || !quoteId) {
      return new Response(
        JSON.stringify({ error: "Missing 'file' or 'quoteId' parameter" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Convert file to ArrayBuffer
    const arrayBuffer = await file.arrayBuffer();
    const fileBuffer = new Uint8Array(arrayBuffer);

    const fileName = `cotizacion_${quoteId}.pdf`;
    const filePath = `quotes/${fileName}`;

    // Upload to Storage
    const { data: uploadData, error: uploadError } = await supabaseClient
      .storage
      .from("quotes")
      .upload(filePath, fileBuffer, {
        contentType: "application/pdf",
        upsert: true,
      });

    if (uploadError) {
      return new Response(
        JSON.stringify({ error: `Storage upload failed: ${uploadError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get public URL
    const { data: { publicUrl } } = supabaseClient
      .storage
      .from("quotes")
      .getPublicUrl(filePath);

    // Update quote in database
    const { error: dbError } = await supabaseAdmin
      .from("cotizaciones")
      .update({ pdf_url: publicUrl })
      .eq("id", quoteId);

    if (dbError) {
      return new Response(
        JSON.stringify({ error: `Database update failed: ${dbError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, url: publicUrl }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
