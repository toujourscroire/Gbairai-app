// Edge Function : alert-dispatcher
// Crée une alerte Gbairai et envoie les notifications FCM multicast
//
// Migration FCM Legacy → FCM HTTP v1
// L'API Legacy (fcm.googleapis.com/fcm/send + key=) a été arrêtée en juillet 2024.
// On utilise désormais FCM HTTP v1 avec un access token OAuth2 obtenu via
// un service account Google (clé JSON stockée dans FIREBASE_SERVICE_ACCOUNT_JSON).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

// ── OAuth2 / FCM v1 ───────────────────────────────────────────────────────────

const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!;

/**
 * Obtient un access token Google OAuth2 à partir d'un service account JSON.
 * Le JWT est signé avec RS256, puis échangé contre un access token Google.
 */
async function getFcmAccessToken(): Promise<string> {
  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
  if (!serviceAccountJson) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON secret is not set');
  }

  const sa = JSON.parse(serviceAccountJson);
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: sa.client_email,
    sub: sa.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');

  const headerB64 = encode(header);
  const payloadB64 = encode(payload);
  const signingInput = `${headerB64}.${payloadB64}`;

  // Import RSA private key (PKCS#8 PEM)
  const pemBody = sa.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBytes,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signatureBytes = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );
  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signatureBytes)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');

  const jwt = `${signingInput}.${signatureB64}`;

  // Échange JWT contre access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const err = await tokenResponse.text();
    throw new Error(`OAuth2 token exchange failed: ${err}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token as string;
}

/**
 * Envoie une notification FCM HTTP v1 à un seul token.
 * FCM v1 n'a pas de multicast natif — on envoie via l'API `/messages:send`
 * ou on utilise le Batch API. Ici on limite à 500 tokens via Promise.all
 * par groupes de 100 pour respecter les quotas.
 */
async function sendFcmNotification(params: {
  token: string;
  title: string;
  body: string;
  sound: string;
  data: Record<string, string>;
  accessToken: string;
}): Promise<{ success: boolean; error?: string }> {
  const { token, title, body, sound, data, accessToken } = params;

  const message = {
    message: {
      token,
      notification: { title, body },
      data,
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound,
            badge: 1,
            'content-available': 1,
          },
        },
      },
      android: {
        priority: 'HIGH',
        notification: { sound, channel_id: 'gbairai_alerts' },
      },
    },
  };

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    },
  );

  if (!res.ok) {
    const err = await res.text();
    // Token invalide/expiré → le supprimer de la DB (non bloquant)
    if (res.status === 404 || err.includes('UNREGISTERED')) {
      return { success: false, error: 'UNREGISTERED' };
    }
    return { success: false, error: err };
  }

  return { success: true };
}

// ── Types ─────────────────────────────────────────────────────────────────────

interface AlertRequest {
  contentId: string;
  level: 'local' | 'national' | 'legendaire';
}

const LEVEL_TITLES: Record<string, string> = {
  pre_gbairai: 'Ça commence à chauffer !',
  local:       'Gbairai local en cours !',
  national:    'Gbairai national — tout le pays en parle !',
  legendaire:  'GBAIRAI LÉGENDAIRE — Histoire de la Côte d\'Ivoire !',
};

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const authHeader = req.headers.get('Authorization');
  if (authHeader !== `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  const requestBody: AlertRequest = await req.json();
  const { contentId, level } = requestBody;

  if (!contentId || !level) {
    return new Response('Missing contentId or level', { status: 400 });
  }

  try {
    // Vérifie qu'il n'y a pas déjà une alerte de ce niveau pour ce contenu
    const { data: existing } = await supabase
      .from('gbairai_alerts')
      .select('id')
      .eq('content_id', contentId)
      .eq('level', level)
      .single();

    if (existing) {
      return new Response(JSON.stringify({ skipped: true }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Récupère le contenu
    const { data: content, error: contentError } = await supabase
      .from('contents')
      .select('caption, city, type, user_id, profiles(display_name)')
      .eq('id', contentId)
      .single();

    if (contentError || !content) throw contentError ?? new Error('Content not found');

    const notifTitle = LEVEL_TITLES[level] ?? 'Gbairai Alert';
    const notifBody = content.caption
      ? content.caption.slice(0, 100)
      : `Contenu ${content.type} depuis ${content.city}`;

    // Crée l'alerte en DB
    const { data: alert, error: alertError } = await supabase
      .from('gbairai_alerts')
      .insert({
        content_id: contentId,
        level,
        title_generated: notifTitle,
        city_scope: level === 'local' ? content.city : null,
      })
      .select('id')
      .single();

    if (alertError) throw alertError;

    // Récupère les FCM tokens des utilisateurs cibles
    let fcmQuery = supabase
      .from('profiles')
      .select('fcm_token')
      .not('fcm_token', 'is', null);

    if (level === 'local') {
      fcmQuery = fcmQuery.eq('city', content.city);
    }

    const { data: profilesWithToken } = await fcmQuery.limit(500);
    const tokens = (profilesWithToken ?? [])
      .map((p: { fcm_token: string | null }) => p.fcm_token)
      .filter(Boolean) as string[];

    let sentCount = 0;
    const unregisteredTokens: string[] = [];

    if (tokens.length > 0) {
      // Obtenir l'access token FCM v1 une seule fois
      const accessToken = await getFcmAccessToken();

      const notifData: Record<string, string> = {
        type: 'gbairai_alert',
        alertId: alert.id,
        contentId,
        level,
        deepLink: `gbairai://alert/${alert.id}`,
      };

      // Envoyer par groupes de 100 (respect des quotas FCM)
      const CHUNK_SIZE = 100;
      for (let i = 0; i < tokens.length; i += CHUNK_SIZE) {
        const chunk = tokens.slice(i, i + CHUNK_SIZE);
        const results = await Promise.all(
          chunk.map((token) =>
            sendFcmNotification({
              token,
              title: notifTitle,
              body: notifBody,
              sound: 'gbairai_alert.aiff',
              data: notifData,
              accessToken,
            })
          ),
        );

        for (let j = 0; j < results.length; j++) {
          if (results[j].success) {
            sentCount++;
          } else if (results[j].error === 'UNREGISTERED') {
            unregisteredTokens.push(chunk[j]);
          }
        }
      }

      // Supprimer les tokens expirés/invalides (nettoyage asynchrone)
      if (unregisteredTokens.length > 0) {
        await supabase
          .from('profiles')
          .update({ fcm_token: null })
          .in('fcm_token', unregisteredTokens);
      }
    }

    // Met à jour le compteur de l'alerte
    await supabase
      .from('gbairai_alerts')
      .update({ sent_count: sentCount })
      .eq('id', alert.id);

    return new Response(
      JSON.stringify({ alertId: alert.id, sentTo: sentCount, unregistered: unregisteredTokens.length }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('[alert-dispatcher] error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
