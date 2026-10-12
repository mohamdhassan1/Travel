import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guards over the SQL that defines the backend. They can't replace
/// running it against Postgres, but they catch regressions in the security
/// model and the honesty rules for seed data.
void main() {
  final migration = File(
    'supabase/migrations/20260929000000_initial_schema.sql',
  ).readAsStringSync();
  final seed = File('supabase/seed.sql').readAsStringSync();

  const tables = [
    'profiles',
    'categories',
    'destinations',
    'destination_packages',
    'favorites',
    'bookings',
    'device_tokens',
    'notifications',
  ];

  test('every public table is created with row level security enabled', () {
    for (final table in tables) {
      expect(
        migration,
        contains('create table if not exists public.$table'),
        reason: table,
      );
      expect(
        migration,
        contains('alter table public.$table enable row level security'),
        reason: table,
      );
    }
    expect(migration, isNot(contains('disable row level security')));
  });

  test(
    'user-owned tables are never readable by anon or with `using (true)`',
    () {
      for (final table in [
        'profiles',
        'favorites',
        'bookings',
        'device_tokens',
        'notifications',
      ]) {
        final policies = RegExp(
          'create policy "[^"]+" on public\\.$table[^;]*;',
          dotAll: true,
        ).allMatches(migration).map((m) => m[0]!).toList();
        expect(policies, isNotEmpty, reason: table);
        for (final policy in policies) {
          expect(
            policy,
            isNot(contains('using (true)')),
            reason: '$table: $policy',
          );
          expect(policy, isNot(contains('to anon')), reason: '$table: $policy');
          expect(policy, contains('auth.uid()'), reason: '$table: $policy');
        }
      }
    },
  );

  test('security-definer functions pin search_path', () {
    final definers = RegExp(
      r'create or replace function[\s\S]*?\$\$;',
    ).allMatches(migration).map((m) => m[0]!);
    for (final fn in definers.where((f) => f.contains('security definer'))) {
      expect(
        fn,
        contains("set search_path = ''"),
        reason: fn.split('\n').first,
      );
    }
  });

  test('clients cannot write prices, references or statuses on bookings', () {
    final insertGrant = RegExp(
      r'grant insert \(([^)]*)\)\s+on table public\.bookings',
    ).firstMatch(migration);
    expect(insertGrant, isNotNull);
    final columns = insertGrant![1]!;
    for (final forbidden in [
      'unit_price',
      'total_price',
      'currency',
      'status',
      'reference',
      'user_id',
    ]) {
      expect(columns, isNot(contains(forbidden)));
    }
    expect(
      migration,
      isNot(matches(RegExp(r'grant update[^;]*public\.bookings'))),
    );
  });

  group('seed data', () {
    test('contains 20 destinations and 40 packages, each destination with credited Wikimedia images', () {
      final slugs = RegExp(
        r"^\(\n  '([a-z-]+)', '(heritage|city|beach|islands)'",
        multiLine: true,
      ).allMatches(seed).map((m) => m[1]).toList();
      expect(slugs, hasLength(20));
      expect(slugs.toSet(), hasLength(20));
      expect(RegExp("'Wikimedia Commons: ").allMatches(seed), hasLength(20));
      // Two packages per destination, each tied to a seeded slug.
      final packageSlugs =
          RegExp(r"^  \('([a-z-]+)', '[^']+', '[^']+',$", multiLine: true).allMatches(seed).map((m) => m[1]).toList();
      expect(packageSlugs, hasLength(40));
      expect(packageSlugs.toSet(), slugs.toSet());

      final urls = RegExp(
        r"'(https?://[^']+)'",
      ).allMatches(seed).map((m) => m[1]!);
      expect(urls, isNotEmpty);
      for (final url in urls) {
        expect(
          url,
          startsWith('https://thumb.wikimedia.org/wikipedia/commons/'),
          reason: url,
        );
      }
    });

    test('has no fabricated ratings, reviews or testimonials', () {
      final lower = seed.toLowerCase();
      for (final word in ['rating', 'review', 'testimonial', 'stars']) {
        // Allowed only inside the header comment that says there are none.
        final hits = RegExp(word).allMatches(lower).length;
        expect(hits, lessThanOrEqualTo(1), reason: word);
      }
      expect(migration.toLowerCase(), isNot(contains('rating')));
    });

    test(
      'is idempotent (upserts by natural keys) and touches no user data',
      () {
        expect(seed, contains('on conflict (id) do update'));
        expect(seed, contains('on conflict (slug) do update'));
        expect(
          seed,
          contains('on conflict (destination_id, name_en) do update'),
        );
        for (final table in [
          'profiles',
          'favorites',
          'bookings',
          'device_tokens',
          'notifications',
        ]) {
          expect(seed, isNot(contains('public.$table')), reason: table);
        }
      },
    );
  });
}
