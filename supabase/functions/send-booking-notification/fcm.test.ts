// Run: node --experimental-strip-types --test supabase/functions/send-booking-notification/fcm.test.ts
// (also runs under `deno test`). Uses a throwaway RSA key generated at runtime:
// no real credential is ever needed or stored.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  ANDROID_CHANNEL_ID,
  buildMessage,
  classifySendResult,
  createSignedJwt,
  maskToken,
  inspectServiceAccount,
  parseServiceAccount,
  type NotificationRow,
} from './fcm.ts';

const row = (over: Partial<NotificationRow> = {}): NotificationRow => ({
  id: '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d',
  user_id: '3847052c-6c16-4ba3-b8ae-04b12545dc04',
  type: 'booking_confirmed',
  booking_id: '0b6f6c1e-8a1c-4a8e-9f4e-2f1d6c7b8a90',
  data: {
    reference: 'RH-3F9A1C2B',
    travel_date: '2026-11-15',
    destination_name_en: 'Cairo',
    destination_name_ar: 'القاهرة',
  },
  ...over,
});

test('confirmation message: minimal data, deterministic, routed to the booking', () => {
  const m = buildMessage(row(), 'tok') as any;
  assert.equal(m.token, 'tok');
  assert.deepEqual(m.data, {
    type: 'booking_confirmed',
    booking_id: '0b6f6c1e-8a1c-4a8e-9f4e-2f1d6c7b8a90',
    notification_id: '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d',
    reference: 'RH-3F9A1C2B',
  });
  assert.equal(m.notification.title, 'Booking confirmed');
  assert.equal(m.notification.body, 'Your booking RH-3F9A1C2B is confirmed.');
  assert.equal(m.android.notification.channel_id, ANDROID_CHANNEL_ID);
  assert.equal(m.android.notification.title_loc_key, 'push_booking_confirmed_title');
  assert.deepEqual(m.android.notification.body_loc_args, ['RH-3F9A1C2B']);
  assert.deepEqual(buildMessage(row(), 'tok'), m, 'deterministic');
  // No personal or catalog details leave the server.
  const text = JSON.stringify(m);
  for (const leaked of ['Cairo', 'القاهرة', '2026-11-15', '3847052c']) assert.ok(!text.includes(leaked), leaked);
});

test('cancellation message', () => {
  const m = buildMessage(row({ type: 'booking_cancelled' }), 'tok') as any;
  assert.equal(m.data.type, 'booking_cancelled');
  assert.equal(m.notification.title, 'Booking cancelled');
  assert.equal(m.android.notification.body_loc_key, 'push_booking_cancelled_body');
});

test('anything that is not a well-formed booking event is not sent', () => {
  assert.equal(buildMessage(row({ type: 'trip_reminder' }), 't'), null);
  assert.equal(buildMessage(row({ type: 'promo' }), 't'), null);
  assert.equal(buildMessage(row({ booking_id: null }), 't'), null);
  assert.equal(buildMessage(row({ booking_id: '../etc' }), 't'), null);
  assert.equal(buildMessage(row({ data: null }), 't'), null);
  assert.equal(buildMessage(row({ data: { reference: '<script>' } }), 't'), null);
});

test('only permanently dead tokens are classified for removal', () => {
  const err = (status: string, message: string, errorCode?: string) => ({
    error: { status, message, details: errorCode ? [{ '@type': 'type.googleapis.com/google.firebase.fcm.v1.FcmError', errorCode }] : [] },
  });
  assert.equal(classifySendResult(200, { name: 'projects/p/messages/1' }), 'sent');
  assert.equal(classifySendResult(404, err('NOT_FOUND', 'Requested entity was not found.', 'UNREGISTERED')), 'invalid_token');
  assert.equal(classifySendResult(403, err('PERMISSION_DENIED', 'SenderId mismatch', 'SENDER_ID_MISMATCH')), 'invalid_token');
  assert.equal(
    classifySendResult(400, err('INVALID_ARGUMENT', 'The registration token is not a valid FCM registration token', 'INVALID_ARGUMENT')),
    'invalid_token',
  );
  // Payload problems, quota, outages and auth are not the token's fault.
  assert.equal(classifySendResult(400, err('INVALID_ARGUMENT', 'Invalid JSON payload received.', 'INVALID_ARGUMENT')), 'failed');
  assert.equal(classifySendResult(429, err('RESOURCE_EXHAUSTED', 'Quota exceeded', 'QUOTA_EXCEEDED')), 'failed');
  assert.equal(classifySendResult(503, err('UNAVAILABLE', 'Unavailable', 'UNAVAILABLE')), 'failed');
  assert.equal(classifySendResult(401, err('UNAUTHENTICATED', 'Bad credentials')), 'failed');
  assert.equal(classifySendResult(500, null), 'failed');
});

test('tokens are masked in logs', () => {
  const token = 'fcm-token-AAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  const masked = maskToken(token);
  assert.ok(!masked.includes(token.slice(6)));
  assert.ok(masked.includes(String(token.length)));
});

test('service account secret shape is validated', () => {
  assert.equal(parseServiceAccount(undefined), null);
  assert.equal(parseServiceAccount('not json'), null);
  assert.equal(parseServiceAccount(JSON.stringify({ type: 'authorized_user' })), null);
  const ok = parseServiceAccount(
    JSON.stringify({ type: 'service_account', project_id: 'p', client_email: 'e@p.iam', private_key: '-----BEGIN PRIVATE KEY-----\nx\n-----END PRIVATE KEY-----\n' }),
  );
  assert.equal(ok?.token_uri, 'https://oauth2.googleapis.com/token');
});

test('JWT is RS256-signed with the service account key and scoped to FCM', async () => {
  const pair = (await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true,
    ['sign', 'verify'],
  )) as CryptoKeyPair;
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey('pkcs8', pair.privateKey));
  const b64 = btoa(String.fromCharCode(...pkcs8)).replace(/(.{64})/g, '$1\n');
  const sa = {
    project_id: 'test-project',
    client_email: 'sender@test-project.iam.gserviceaccount.com',
    private_key: `-----BEGIN PRIVATE KEY-----\n${b64}\n-----END PRIVATE KEY-----\n`,
    token_uri: 'https://oauth2.googleapis.com/token',
  };
  const jwt = await createSignedJwt(sa, 1_800_000_000);
  const [h, c, s] = jwt.split('.');
  const decode = (part: string) => JSON.parse(atob(part.replace(/-/g, '+').replace(/_/g, '/')));
  assert.deepEqual(decode(h), { alg: 'RS256', typ: 'JWT' });
  const claims = decode(c);
  assert.equal(claims.scope, 'https://www.googleapis.com/auth/firebase.messaging');
  assert.equal(claims.iss, sa.client_email);
  assert.equal(claims.aud, sa.token_uri);
  assert.equal(claims.exp - claims.iat, 3600);
  const sig = Uint8Array.from(atob(s.replace(/-/g, '+').replace(/_/g, '/') + '=='.slice((s.length + 2) % 4 || 2)), (ch) =>
    ch.charCodeAt(0),
  );
  const valid = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', pair.publicKey, sig, new TextEncoder().encode(`${h}.${c}`));
  assert.ok(valid, 'signature verifies with the matching public key');
});

// Diagnostics for a misconfigured secret: codes only, never the value.
const KEY = '-----BEGIN PRIVATE KEY-----\nMIIBVQ\n-----END PRIVATE KEY-----\n';
const account = (over: Record<string, unknown> = {}) =>
  JSON.stringify({ type: 'service_account', project_id: 'p', client_email: 'e@p.iam', private_key: KEY, ...over });

test('secret diagnostics name the problem without echoing the value', () => {
  assert.equal(inspectServiceAccount(undefined).issue, 'missing');
  assert.equal(inspectServiceAccount('   ').issue, 'missing');
  assert.equal(inspectServiceAccount('{not json').issue, 'invalid_json');
  assert.equal(inspectServiceAccount('[1,2]').issue, 'invalid_json');
  assert.equal(inspectServiceAccount(account({ type: 'authorized_user' })).issue, 'not_service_account');
  assert.equal(inspectServiceAccount(account({ project_id: '' })).issue, 'missing_fields');
  assert.equal(inspectServiceAccount(account({ client_email: undefined })).issue, 'missing_fields');
  assert.equal(inspectServiceAccount(account({ private_key: 'PRIVATE KEY' })).issue, 'bad_private_key');
  const secretish = account({ private_key: 'super-secret-value' });
  const result = inspectServiceAccount(secretish);
  assert.equal(result.issue, 'bad_private_key');
  assert.ok(!JSON.stringify(result).includes('super-secret-value'), 'the diagnosis never contains the value');
});

test('common paste variants of a valid file are accepted', () => {
  // The file as downloaded.
  assert.equal(inspectServiceAccount(account()).issue, null);
  // Surrounding whitespace / trailing newline.
  assert.equal(inspectServiceAccount(`\n  ${account()}\n`).issue, null);
  // The key's \n escapes turned into real line breaks by a text box.
  const realNewlines = account().replaceAll('\\n', '\n');
  assert.throws(() => JSON.parse(realNewlines), SyntaxError, 'strict JSON rejects it');
  const parsed = inspectServiceAccount(realNewlines);
  assert.equal(parsed.issue, null);
  assert.equal(parsed.account?.private_key, KEY);
  // Windows line endings inside the key.
  assert.equal(inspectServiceAccount(account().replaceAll('\\n', '\r\n')).account?.private_key, KEY);
  // Stored as a JSON string that contains the JSON (double-encoded).
  assert.equal(inspectServiceAccount(JSON.stringify(account())).account?.project_id, 'p');
});
