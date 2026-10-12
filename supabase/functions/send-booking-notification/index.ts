// send-booking-notification — delivers a booking notification row to the
// owner's registered devices through Firebase Cloud Messaging (HTTP v1).
//
// Caller: only the `notifications_dispatch_push` database trigger (pg_net),
// authenticated by the `x-push-dispatch-secret` header, which is checked
// against a Vault secret through a service-role-only function. The request
// body is just `{ notification_id }`; recipient, tokens, type and text are
// all derived server-side from the database.
//
// Secrets (Edge Function secrets, never in the app or Git):
//   FIREBASE_SERVICE_ACCOUNT_JSON  service account with the FCM API role
// Provided by the platform: SUPABASE_URL, SUPABASE_SECRET_KEYS (or the legacy
// SUPABASE_SERVICE_ROLE_KEY).
import { createClient } from 'npm:@supabase/supabase-js@2';
import {
  buildMessage,
  classifySendResult,
  createSignedJwt,
  isBookingEvent,
  maskToken,
  inspectServiceAccount,
  type NotificationRow,
  type ServiceAccount,
} from './fcm.ts';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

function adminKey(): string | undefined {
  const keys = Deno.env.get('SUPABASE_SECRET_KEYS');
  if (keys) {
    try {
      const parsed = JSON.parse(keys) as Record<string, string>;
      if (parsed['default']) return parsed['default'];
    } catch {
      // fall through to the legacy key
    }
  }
  return Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? undefined;
}

let cachedAccessToken: { value: string; expiresAt: number } | null = null;

async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt - 60 > now) return cachedAccessToken.value;
  const assertion = await createSignedJwt(sa, now);
  const res = await fetch(sa.token_uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
  });
  if (!res.ok) throw new Error(`oauth_token_${res.status}`);
  const body = (await res.json()) as { access_token: string; expires_in: number };
  cachedAccessToken = { value: body.access_token, expiresAt: now + (body.expires_in ?? 3600) };
  return body.access_token;
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return json(405, { error: 'method_not_allowed' });

  const url = Deno.env.get('SUPABASE_URL');
  const key = adminKey();
  if (!url || !key) return json(500, { error: 'server_misconfigured' });
  const admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });

  // 1. Only the database trigger may call this.
  const presented = req.headers.get('x-push-dispatch-secret') ?? '';
  if (presented.length < 32) return json(401, { error: 'unauthorized' });
  const { data: authorized, error: authError } = await admin.rpc('verify_push_dispatch_secret', { p_secret: presented });
  if (authError) {
    console.error('dispatch secret check failed', authError.code);
    return json(500, { error: 'auth_check_failed' });
  }
  if (authorized !== true) return json(401, { error: 'unauthorized' });

  // 2. Only an id is accepted from the caller (or the credential check below).
  let body: Record<string, unknown> | null;
  try {
    body = (await req.json()) as Record<string, unknown> | null;
  } catch {
    return json(400, { error: 'invalid_body' });
  }
  const healthCheck = body?.['check'] === 'fcm_auth';
  const notificationId = body?.['notification_id'];
  if (!healthCheck && (typeof notificationId !== 'string' || !UUID.test(notificationId))) {
    return json(400, { error: 'invalid_body' });
  }

  // 3. Configuration check before claiming, so nothing is lost while the
  //    Firebase credential is missing.
  //    The reason code describes the secret's shape only, never its value.
  const { account: sa, issue } = inspectServiceAccount(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON'));
  if (!sa) {
    console.error('fcm not configured', issue);
    // A secret saved under a slightly different name (typo, spaces, case)
    // shows up here: variable NAMES only, never values.
    const similarNames =
      issue === 'missing'
        ? Object.keys(Deno.env.toObject()).filter(
            (n) => /fire|fcm|service.?account|google/i.test(n) && n !== 'FIREBASE_SERVICE_ACCOUNT_JSON',
          )
        : [];
    return json(503, { error: 'fcm_not_configured', reason: issue, similar_names: similarNames });
  }

  // Credential check for operators: exchanges the signed JWT for a Google
  // access token. Reads no rows and sends no message. Returns only the
  // (public) Firebase project id, never the token or the key.
  if (healthCheck) {
    try {
      await accessToken(sa);
      return json(200, { status: 'fcm_auth_ok', project_id: sa.project_id });
    } catch (e) {
      console.error('fcm auth failed', (e as Error).message);
      return json(502, { error: 'fcm_auth_failed', detail: (e as Error).message });
    }
  }

  // 4. Claim the row: at most one push per notification.
  const { data: claimed, error: claimError } = await admin.rpc('claim_notification_push', {
    p_notification_id: notificationId,
  });
  if (claimError) {
    console.error('claim failed', claimError.code);
    return json(500, { error: 'claim_failed' });
  }
  const row = (Array.isArray(claimed) ? claimed[0] : null) as NotificationRow | null;
  if (!row || !isBookingEvent(row.type) || !row.booking_id) return json(200, { status: 'skipped' });

  // 5. The booking must still exist and belong to the same user.
  const { data: booking } = await admin
    .from('bookings')
    .select('id')
    .eq('id', row.booking_id)
    .eq('user_id', row.user_id)
    .maybeSingle();
  if (!booking) return json(200, { status: 'skipped_no_booking' });

  // 6. Only the owner's tokens (one row per device).
  const { data: tokens, error: tokenError } = await admin
    .from('device_tokens')
    .select('token')
    .eq('user_id', row.user_id);
  if (tokenError) {
    console.error('token lookup failed', tokenError.code);
    return json(500, { error: 'token_lookup_failed' });
  }
  if (!tokens || tokens.length === 0) return json(200, { status: 'no_devices' });

  let bearer: string;
  try {
    bearer = await accessToken(sa);
  } catch (e) {
    console.error('fcm auth failed', (e as Error).message);
    return json(502, { error: 'fcm_auth_failed' });
  }

  const endpoint = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
  const result = { sent: 0, removed: 0, failed: 0 };
  for (const { token } of tokens as { token: string }[]) {
    const message = buildMessage(row, token);
    if (!message) return json(200, { status: 'skipped_invalid_payload' });
    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${bearer}` },
        body: JSON.stringify({ message }),
      });
      const body = await res.json().catch(() => null);
      const outcome = classifySendResult(res.status, body);
      if (outcome === 'sent') {
        result.sent++;
      } else if (outcome === 'invalid_token') {
        // Remove only this dead token; the others are untouched.
        await admin.from('device_tokens').delete().eq('token', token).eq('user_id', row.user_id);
        result.removed++;
        console.log('removed invalid token', maskToken(token));
      } else {
        result.failed++;
        console.warn('fcm send failed', res.status, maskToken(token));
      }
    } catch (e) {
      result.failed++;
      console.warn('fcm send error', (e as Error).name, maskToken(token));
    }
  }
  return json(200, { status: 'done', ...result });
});
