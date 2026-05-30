// Edge Function : alert-dispatcher
// Crée une alerte Gbairai et envoie les notifications FCM multicast

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!;

interface AlertRequest {
  contentId: string;
  level: 'local' | 'national' | 'legendaire';
}

const LEVEL_TITLES: Record<string, string> = {
  pre_gbairai: '🔥 Ça commence à chauffer !',
  local:       '📍 Gbairai local en cours !',
  national:    '🇨🇮 Gbairai national — tout le pays en parle !',
  legendaire:  '👑 GBAIRAI LÉGENDAIRE — Histoire de la Côte d\'Ivoire !',
};

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const authHeader = req.headers.get('Authorization');
  if (authHeader !== `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  const body: AlertRequest = await req.json();
  const { contentId, level } = body;

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

    const title = LEVEL_TITLES[level] ?? '🔥 Gbairai Alert';
    const body_text = content.caption
      ? content.caption.slice(0, 100)
      : `Contenu ${content.type} depuis ${content.city}`;

    // Crée l'alerte en DB
    const { data: alert, error: alertError } = await supabase
      .from('gbairai_alerts')
      .insert({
        content_id: contentId,
        level,
        title_generated: title,
        city_scope: level === 'local' ? content.city : null,
      })
      .select('id')
      .single();

    if (alertError) throw alertError;

    // Récupère les FCM tokens des utilisateurs cibles
    // Pour 'local' : ville uniquement; pour 'national'/'legendaire' : tous
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

    if (tokens.length > 0) {
      // FCM multicast (batch de 500 max)
      const fcmPayload = {
        registration_ids: tokens,
        notification: {
          title,
          body: body_text,
          sound: 'gbairai_alert.aiff',
        },
        data: {
          type: 'gbairai_alert',
          alertId: alert.id,
          contentId,
          level,
          deepLink: `gbairai://alert/${alert.id}`,
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body: body_text },
              sound: 'gbairai_alert.aiff',
              badge: 1,
              'content-available': 1,
            },
          },
        },
        priority: 'high',
      };

      const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          Authorization: `key=${FCM_SERVER_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload),
      });

      const fcmResult = await fcmResponse.json();

      // Met à jour les compteurs de l'alerte
      await supabase
        .from('gbairai_alerts')
        .update({
          sent_count: tokens.length,
          fcm_message_id: fcmResult.multicast_id?.toString(),
        })
        .eq('id', alert.id);
    }

    return new Response(
      JSON.stringify({ alertId: alert.id, sentTo: tokens.length }),
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
