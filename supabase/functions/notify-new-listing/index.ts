import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { create as createJWT, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts"

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}');
    
    const body = await req.json();
    console.log('Received listing payload:', JSON.stringify(body));

    const { record } = body;
    const propertyName = record.name;
    const uploaderId = record.user_id;

    console.log(`🏠 New property listing: ${propertyName} by user: ${uploaderId}`);

    // 1. Fetch all FCM tokens
    const { data: profiles, error: profileError } = await supabase
      .from('profiles')
      .select('id, fcm_token')
      .not('fcm_token', 'is', null);

    if (profileError) throw profileError;

    // Filter out the uploader in code to be 100% sure
    const tokens = profiles
      ?.filter(p => p.id !== uploaderId && p.fcm_token)
      .map(p => p.fcm_token) || [];
    
    console.log(`🎯 Targeted ${tokens.length} users for notification (excluded uploader ${uploaderId}).`);
    
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ success: true, message: 'No tokens found.' }), { status: 200 });
    }

    // 2. Get Google Access Token
    const jwtContent = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/cloud-platform",
      aud: "https://oauth2.googleapis.com/token",
      exp: getNumericDate(3600),
      iat: getNumericDate(0),
    };

    const jwt = await createJWT(
      { alg: "RS256", typ: "JWT" },
      jwtContent,
      await crypto.subtle.importKey(
        "pkcs8",
        new Uint8Array(
          atob(serviceAccount.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, ""))
            .split("")
            .map((c) => c.charCodeAt(0))
        ),
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"]
      )
    );

    const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    });

    const tokenJson = await tokenRes.json();
    const accessToken = tokenJson.access_token;
    
    if (!accessToken) throw new Error('Failed to obtain Google Access Token');

    // 3. Send Notifications
    const projectId = serviceAccount.project_id;
    const results = await Promise.all(tokens.map(async (token) => {
      try {
        const fcmRes = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token: token,
              notification: {
                title: '🏠 New Home Added!',
                body: `${propertyName} is now available near you.`,
              },
              data: {
                type: 'new_listing',
                propertyId: record.id.toString(),
              }
            }
          })
        });
        return await fcmRes.json();
      } catch (e) {
        return { error: e.message };
      }
    }));

    return new Response(JSON.stringify({ success: true, count: tokens.length, results }), { status: 200 });
  } catch (error) {
    console.error('❌ Error:', error.message);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
})
