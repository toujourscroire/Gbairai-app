// Edge Function : content-moderator
// Appelée après chaque insertion de contenu via Database Webhook
// Analyse le contenu avec OpenAI et met à jour le statut de modération

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')!;

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
  const payload: WebhookPayload = await req.json();

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
