// Pure FCM HTTP v1 helpers for send-booking-notification. No Deno- or
// Supabase-specific imports, so they run under Deno (the function) and under
// Node's test runner (fcm.test.ts) alike.

export type BookingEventType = 'booking_confirmed' | 'booking_cancelled';

/** The notification row fields the sender needs (from public.notifications). */
export interface NotificationRow {
  id: string;
  user_id: string;
  type: string;
  booking_id: string | null;
  data: Record<string, unknown> | null;
}

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri: string;
}

/** Android channel the app creates for remote booking pushes. */
export const ANDROID_CHANNEL_ID = 'booking_updates';
/** Monochrome status-bar icon shipped in the Android app (res/drawable). */
export const ANDROID_ICON = 'ic_stat_rahala';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const REFERENCE = /^RH-[0-9A-F]{8}$/;

const COPY: Record<BookingEventType, { title: string; body: (ref: string) => string; key: string }> = {
  booking_confirmed: {
    title: 'Booking confirmed',
    body: (ref) => `Your booking ${ref} is confirmed.`,
    key: 'push_booking_confirmed',
  },
  booking_cancelled: {
    title: 'Booking cancelled',
    body: (ref) => `Your booking ${ref} was cancelled.`,
    key: 'push_booking_cancelled',
  },
};

export function isBookingEvent(type: string): type is BookingEventType {
  return type === 'booking_confirmed' || type === 'booking_cancelled';
}

/**
 * Builds the FCM v1 `message` for one device, entirely from server data.
 * Returns null for anything that isn't a well-formed booking event.
 *
 * Contents are deliberately minimal: event type, booking id and the booking
 * reference — no names, phone numbers, prices or destinations. On Android the
 * text is localized on the device from string resources (title_loc_key /
 * body_loc_key); the English title/body are the fallback.
 */
export function buildMessage(row: NotificationRow, token: string): Record<string, unknown> | null {
  if (!isBookingEvent(row.type) || !row.booking_id || !UUID.test(row.booking_id) || !UUID.test(row.id)) {
    return null;
  }
  const rawRef = row.data?.['reference'];
  const reference = typeof rawRef === 'string' && REFERENCE.test(rawRef) ? rawRef : null;
  if (!reference) return null;
  const copy = COPY[row.type];
  return {
    token,
    notification: { title: copy.title, body: copy.body(reference) },
    data: {
      type: row.type,
      booking_id: row.booking_id,
      notification_id: row.id,
      reference,
    },
    android: {
      priority: 'high',
      notification: {
        channel_id: ANDROID_CHANNEL_ID,
        icon: ANDROID_ICON,
        tag: `notification-${row.id}`,
        title_loc_key: `${copy.key}_title`,
        body_loc_key: `${copy.key}_body`,
        body_loc_args: [reference],
      },
    },
  };
}

export type SendOutcome = 'sent' | 'invalid_token' | 'failed';

/**
 * Classifies an FCM v1 send response. Only errors that mean "this token will
 * never work again" are `invalid_token` (the row is then deleted); anything
 * else (quota, server errors, auth, a bad payload) is `failed` and the token
 * is kept.
 */
export function classifySendResult(status: number, body: unknown): SendOutcome {
  if (status >= 200 && status < 300) return 'sent';
  const error = (body as { error?: { status?: string; message?: string; details?: unknown[] } } | null)?.error;
  const codes = (Array.isArray(error?.details) ? error!.details : [])
    .map((d) => (d as { errorCode?: string } | null)?.errorCode)
    .filter((c): c is string => typeof c === 'string');
  if (codes.includes('UNREGISTERED') || codes.includes('SENDER_ID_MISMATCH')) return 'invalid_token';
  if (status === 404 && error?.status === 'NOT_FOUND') return 'invalid_token';
  // INVALID_ARGUMENT is only a dead token when FCM says the token is the problem.
  if (
    (codes.includes('INVALID_ARGUMENT') || error?.status === 'INVALID_ARGUMENT') &&
    /registration token/i.test(error?.message ?? '')
  ) {
    return 'invalid_token';
  }
  return 'failed';
}

/** Safe for logs: never the full token. */
export function maskToken(token: string): string {
  return `${token.slice(0, 6)}…(${token.length})`;
}

/**
 * Why FIREBASE_SERVICE_ACCOUNT_JSON can't be used. Codes describe the shape
 * only — never any part of the value — so they are safe to return to the
 * (authenticated) caller and to log.
 */
export type ServiceAccountIssue =
  | 'missing'
  | 'invalid_json'
  | 'not_service_account'
  | 'missing_fields'
  | 'bad_private_key';

/**
 * Escapes raw line breaks that appear *inside* JSON strings. A dashboard
 * text box can turn the key's `\n` escapes into real newlines, which strict
 * JSON rejects; whitespace between tokens is left alone.
 */
function escapeNewlinesInStrings(raw: string): string {
  let out = '';
  let inString = false;
  let escaped = false;
  for (const ch of raw) {
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch === '\\') {
        escaped = true;
      } else if (ch === '"') {
        inString = false;
      } else if (ch === '\n') {
        out += '\\n';
        continue;
      } else if (ch === '\r') {
        continue;
      }
    } else if (ch === '"') {
      inString = true;
    }
    out += ch;
  }
  return out;
}

function parseLenient(raw: string, depth = 0): unknown {
  let value: unknown;
  try {
    value = JSON.parse(raw);
  } catch {
    value = JSON.parse(escapeNewlinesInStrings(raw)); // may throw: invalid_json
  }
  // Pasted as a JSON *string* that contains the JSON (double-encoded).
  return typeof value === 'string' && depth < 2 ? parseLenient(value.trim(), depth + 1) : value;
}

/** Parses the FIREBASE_SERVICE_ACCOUNT_JSON secret, or says why it can't. */
export function inspectServiceAccount(
  raw: string | undefined | null,
): { account: ServiceAccount; issue: null } | { account: null; issue: ServiceAccountIssue } {
  if (!raw || !raw.trim()) return { account: null, issue: 'missing' };
  let json: Record<string, unknown>;
  try {
    const value = parseLenient(raw.trim());
    if (typeof value !== 'object' || value === null || Array.isArray(value)) {
      return { account: null, issue: 'invalid_json' };
    }
    json = value as Record<string, unknown>;
  } catch {
    return { account: null, issue: 'invalid_json' };
  }
  if (json.type !== 'service_account') return { account: null, issue: 'not_service_account' };
  const { project_id, client_email, private_key } = json;
  if (typeof project_id !== 'string' || !project_id || typeof client_email !== 'string' || !client_email) {
    return { account: null, issue: 'missing_fields' };
  }
  if (
    typeof private_key !== 'string' ||
    !/-----BEGIN PRIVATE KEY-----[\s\S]+-----END PRIVATE KEY-----/.test(private_key)
  ) {
    return { account: null, issue: 'bad_private_key' };
  }
  const token_uri = typeof json.token_uri === 'string' ? json.token_uri : 'https://oauth2.googleapis.com/token';
  return { account: { project_id, client_email, private_key, token_uri }, issue: null };
}

/** Validates the FIREBASE_SERVICE_ACCOUNT_JSON secret's shape. */
export function parseServiceAccount(raw: string | undefined | null): ServiceAccount | null {
  return inspectServiceAccount(raw).account;
}

function base64Url(bytes: Uint8Array): string {
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToPkcs8(pem: string): Uint8Array {
  const body = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, '').replace(/\s+/g, '');
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

/**
 * Signed JWT for the OAuth2 service-account flow (RS256), scoped to FCM only.
 * Exchanged at `token_uri` for a short-lived access token.
 */
export async function createSignedJwt(sa: ServiceAccount, nowSeconds: number): Promise<string> {
  const encoder = new TextEncoder();
  const header = base64Url(encoder.encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const claims = base64Url(
    encoder.encode(
      JSON.stringify({
        iss: sa.client_email,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: sa.token_uri,
        iat: nowSeconds,
        exp: nowSeconds + 3600,
      }),
    ),
  );
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToPkcs8(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, encoder.encode(`${header}.${claims}`));
  return `${header}.${claims}.${base64Url(new Uint8Array(signature))}`;
}
