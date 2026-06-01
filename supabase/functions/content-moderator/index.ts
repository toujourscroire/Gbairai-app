// Edge Function : content-moderator
// Appelée après chaque insertion de contenu via Database Webhook
// Analyse le contenu avec OpenAI et met à jour le statut de modération

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')!;

// HMAC-SHA256 secret configuré dans Supabase Dashboard → Database → Webhooks
// (même valeur dans Codemagic secret: WEBHOOK_SIGNING_SECRET)
const WEBHOOK_SECRET = Deno.env.get('WEBHOOK_SIGNING_SECRET');

/**
 * Vérifie la signature HMAC-SHA256 du webhook Supabase.
 * Supabase envoie le header `x-supabase-signature: sha256=<hex>`.
 * Sans cette vérification, n'importe qui connaissant l'URL peut déclencher
 * des modérations arbitraires ou épuiser le quota OpenAI.
 */
async function verifyWebhookSignature(req: Request, rawBody: string): Promise<boolean> {
  if (!WEBHOOK_SECRET) {
    // Si le secret n'est pas configuré, log un avertissement mais ne bloque pas
    // (permet le fonctionnement en développement sans secret)
    console.warn('[content-moderator] WEBHOOK_SIGNING_SECRET not set — skipping signature verification');
    return true;
  }

  const signature = req.headers.get('x-supabase-signature');
  if (!signature) {
    console.error('[content-moderator] Missing x-supabase-signature header');
    return false;
  }

  // Extraire le hash hex après "sha256="
  const expectedHash = signature.startsWith('sha256=')
    ? signature.slice(7)
    : signature;

  // Calculer le HMAC-SHA256 du body avec le secret
  const encoder = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    encoder.encode(WEBHOOK_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signatureBytes = await crypto.subtle.sign(
    'HMAC',
    keyMaterial,
    encoder.encode(rawBody),
  );

  const computedHash = Array.from(new Uint8Array(signatureBytes))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  // Comparaison en temps constant pour éviter les timing attacks
  if (computedHash.length !== expectedHash.length) return false;
  let diff = 0;
  for (let i = 0; i < computedHash.length; i++) {
    diff |= computedHash.charCodeAt(i) ^ expectedHash.charCodeAt(i);
  }
  return diff === 0;
}

interface WebhookPayload {
  type: 'INSERT';
  table: string;
  record: {
    id: string;
    type: string;
    caption: string | null;
    voice_title: string | null;
    user_id: string;
  };
}

Deno.serve(async (req: Request) => {
  // Lire le body une seule fois (les streams ne peuvent pas être relus)
  const rawBody = await req.text();

  // Vérification de la signature avant tout traitement
  const isValid = await verifyWebhookSignature(req, rawBody);
  if (!isValid) {
    return new Response('Unauthorized', { status: 401 });
  }

  const payload: WebhookPayload = JSON.parse(rawBody);

  if (payload.table !== 'contents' || payload.type !== 'INSERT') {
    return new Response('OK', { status: 200 });
  }

  const { id, caption, voice_title } = payload.record;
  const textToAnalyze = [caption, voice_title].filter(Boolean).join(' ').trim();

  if (!textToAnalyze) {
    // Pas de texte → approbation automatique
    await supabase
      .from('contents')
      .update({ moderation_status: 'approved', moderation_score: 0.0 })
      .eq('id', id);
    return new Response('approved', { status: 200 });
  }

  try {
    const openaiRes = await fetch('https://api.openai.com/v1/moderations', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ input: textToAnalyze }),
    });

    const { results } = await openaiRes.json();
    const result = results?.[0];

    if (!result) throw new Error('OpenAI moderation returned no results');

    const score: number = Math.max(...Object.values(result.category_scores as Record<string, number>));
    const flagged: boolean = result.flagged;

    let status: string;
    if (flagged || score > 0.8) {
      status = 'rejected';
    } else if (score > 0.5) {
      status = 'review';
    } else {
      status = 'approved';
    }

    await supabase
      .from('contents')
      .update({
        moderation_status: status,
        moderation_score: score,
        is_flagged: flagged,
        published_at: status === 'approved' ? new Date().toISOString() : null,
      })
      .eq('id', id);

    if (status === 'rejected') {
      await supabase.from('audit_logs').insert({
        user_id: payload.record.user_id,
        action: 'content_auto_rejected',
        target_type: 'content',
        target_id: id,
        metadata: { score, categories: result.categories },
      });
    }

    return new Response(JSON.stringify({ status, score }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('[content-moderator] error:', err);
    // En cas d'erreur OpenAI → laisser en 'pending' pour revue manuelle
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
