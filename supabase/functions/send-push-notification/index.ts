import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { create as createJWT, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts"

serve(async (req) => {
  try {
    const body = await req.json()
    console.log(`📦 Raw body:`, JSON.stringify(body))
    const { record } = body
    
    if (!record) {
      console.error('❌ Error: No record found in request body')
      return new Response(JSON.stringify({ error: 'No record found' }), { status: 400 })
    }

    console.log(`🔔 Notification trigger for message: ${record.id}`)
    console.log(`From: ${record.sender_id} to: ${record.receiver_id}`)

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Get Receiver Token
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('fcm_token')
      .eq('id', record.receiver_id)
      .single()

    // 2. Get Sender Name
    const { data: sender } = await supabaseAdmin
      .from('profiles')
      .select('full_name')
      .eq('id', record.sender_id)
      .single()

    if (profile?.fcm_token) {
      console.log(`✅ Token found for receiver. Preparing FCM v1 send...`)
      const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}')
      
      // 3. Generate Access Token for FCM v1
      const jwtContent = {
        iss: serviceAccount.client_email,
        sub: serviceAccount.client_email,
        aud: "https://oauth2.googleapis.com/token",
        iat: getNumericDate(0),
        exp: getNumericDate(3600),
        scope: "https://www.googleapis.com/auth/cloud-platform",
      }

      console.log(`🔑 Generating JWT for ${serviceAccount.client_email}`)
      
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
      )

      const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
          assertion: jwt,
        }),
      })
      
      const tokenJson = await tokenRes.json()
      const { access_token } = tokenJson
      
      if (!access_token) {
        console.error('❌ Failed to get Google Access Token:', JSON.stringify(tokenJson))
        throw new Error('Access token missing')
      }

      console.log(`🛰️ Access token obtained. Sending to FCM v1...`)

      // 4. Send Notification
      const fcmRes = await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${access_token}`,
        },
        body: JSON.stringify({
          message: {
            token: profile.fcm_token,
            notification: {
              title: sender?.full_name || 'New Message',
              body: record.content,
            },
            data: {
              chat_id: record.sender_id,
            },
          },
        }),
      })

      const fcmResult = await fcmRes.json()
      console.log(`📡 FCM Response:`, JSON.stringify(fcmResult))
    } else {
      console.log(`⚠️ No FCM token found for receiver: ${record.receiver_id}`)
    }

    return new Response(JSON.stringify({ ok: true }), { headers: { "Content-Type": "application/json" } })

  } catch (error) {
    console.error(`❌ Function Error:`, error.message)
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 500, 
      headers: { "Content-Type": "application/json" } 
    })
  }
})
