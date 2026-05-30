// Edge Function : score-worker
// Appelée toutes les 60s par un pg_cron ou Cron externe
// Recalcule les scores + détecte les niveaux Gbairai + dispatch les alertes

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

interface ContentRow {
  id: string;
  views_count: number;
  reactions_count: number;
  gbairai_level: string | null;
}

Deno.serve(async (req: Request) => {
  // Vérification du secret cron (évite les appels non autorisés)
  const authHeader = req.headers.get('Authorization');
  const cronSecret = Deno.env.get('CRON_SECRET');
  if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    // Récupère les contenus actifs des dernières 48h pour scoring
    const { data: contents, error } = await supabase
      .from('contents')
      .select('id, views_count, reactions_count, gbairai_level')
      .is('deleted_at', null)
      .eq('moderation_status', 'approved')
      .gte('created_at', new Date(Date.now() - 48 * 3600 * 1000).toISOString())
      .order('score_adjusted', { ascending: false })
      .limit(500);

    if (error) throw error;

    const levelChanges: { contentId: string; oldLevel: string | null; newLevel: string }[] = [];

    for (const content of (contents as ContentRow[])) {
      const { data: newLevel } = await supabase.rpc('evaluate_gbairai_level', {
        p_content_id: content.id,
      });

      if (newLevel && newLevel !== content.gbairai_level) {
        levelChanges.push({
          contentId: content.id,
          oldLevel: content.gbairai_level,
          newLevel,
        });
      }
    }

    // Dispatch les alertes pour les nouveaux niveaux
    if (levelChanges.length > 0) {
      await Promise.allSettled(
        levelChanges.map(async ({ contentId, newLevel }) => {
          // Appel à alert-dispatcher pour les niveaux significatifs
          if (['local', 'national', 'legendaire'].includes(newLevel)) {
            await supabase.functions.invoke('alert-dispatcher', {
              body: { contentId, level: newLevel },
            });
          }
        }),
      );
    }

    return new Response(
      JSON.stringify({
        processed: contents?.length ?? 0,
        levelChanges: levelChanges.length,
      }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('[score-worker] error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
