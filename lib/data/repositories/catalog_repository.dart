import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/catalog_models.dart';
import 'supabase_error_mapper.dart';

/// Read access to the public travel catalog. Throws `AppFailure`.
abstract interface class CatalogRepository {
  Future<List<TravelCategory>> fetchCategories();

  /// Published destinations, featured first. Optionally filtered by category.
  Future<List<DestinationSummary>> fetchDestinations({String? categoryId});

  /// Card data for specific destinations (e.g. the user's favourites), in the
  /// order of [ids]. Unknown / unpublished ids are simply absent.
  Future<List<DestinationSummary>> fetchDestinationsByIds(List<String> ids);

  /// A single published destination. Throws `FailureType.notFound` for an
  /// unknown, unpublished or malformed id.
  Future<DestinationDetails> fetchDestination(String id);

  /// Active packages of a destination, cheapest/sorted first.
  Future<List<TravelPackage>> fetchPackages(String destinationId);
}

/// `true` for a canonical UUID string (the format of every catalog id).
bool isUuid(String value) =>
    RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(value);

// Note: postgrest-dart's `.order()` defaults to DESCENDING, so every call
// below states its direction explicitly.
class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._client, {this.timeout = const Duration(seconds: 15)});

  final SupabaseClient _client;
  final Duration timeout;

  static const imagesBucket = 'destination-images';

  @override
  Future<List<TravelCategory>> fetchCategories() => _run('categories', () async {
        final rows = await _client.from('categories').select().order('sort_order', ascending: true).timeout(timeout);
        return parseRows(rows, TravelCategory.fromJson, 'categories');
      });

  @override
  Future<List<DestinationSummary>> fetchDestinations({String? categoryId}) => _run('destinations', () async {
        var query = _client.from('destination_summaries').select();
        if (categoryId != null) query = query.eq('category_id', categoryId);
        final rows =
            await query.order('is_featured', ascending: false).order('name_en', ascending: true).timeout(timeout);
        return parseRows(rows.map(_withResolvedCover).toList(), DestinationSummary.fromJson, 'destination_summaries');
      });

  @override
  Future<List<DestinationSummary>> fetchDestinationsByIds(List<String> ids) => _run('destinations by id', () async {
        final validIds = ids.where(isUuid).toList();
        if (validIds.isEmpty) return const <DestinationSummary>[];
        final rows = await _client.from('destination_summaries').select().inFilter('id', validIds).timeout(timeout);
        final parsed =
            parseRows(rows.map(_withResolvedCover).toList(), DestinationSummary.fromJson, 'destination_summaries');
        final byId = {for (final d in parsed) d.id: d};
        return [
          for (final id in validIds)
            if (byId[id] != null) byId[id]!
        ];
      });

  @override
  Future<DestinationDetails> fetchDestination(String id) => _run('destination $id', () async {
        // A malformed id can't exist; don't send it to the server (Postgres
        // would answer with a type error rather than "not found").
        if (!isUuid(id)) throw AppFailure(FailureType.notFound, debugMessage: 'Malformed destination id "$id"');
        final row = await _client.from('destinations').select().eq('id', id).maybeSingle().timeout(timeout);
        if (row == null) throw AppFailure(FailureType.notFound, debugMessage: 'No published destination $id');
        return DestinationDetails.fromJson({
          ...row,
          'cover_image': _resolveImage(row['cover_image']),
          'gallery': [for (final item in (row['gallery'] as List?) ?? const []) _resolveImage(item)],
        });
      });

  @override
  Future<List<TravelPackage>> fetchPackages(String destinationId) => _run('packages of $destinationId', () async {
        if (!isUuid(destinationId)) {
          throw AppFailure(FailureType.notFound, debugMessage: 'Malformed destination id "$destinationId"');
        }
        final rows = await _client
            .from('destination_packages')
            .select()
            .eq('destination_id', destinationId)
            .order('sort_order', ascending: true)
            .order('price_per_person', ascending: true)
            .timeout(timeout);
        return parseRows(rows, TravelPackage.fromJson, 'destination_packages');
      });

  Map<String, dynamic> _withResolvedCover(Map<String, dynamic> row) =>
      {...row, 'cover_image': _resolveImage(row['cover_image'])};

  /// Catalog images may be absolute URLs (seeded from Wikimedia Commons) or
  /// object paths inside the public [imagesBucket].
  Object? _resolveImage(Object? value) {
    if (value is! String || value.isEmpty || value.startsWith('http')) return value;
    return _client.storage.from(imagesBucket).getPublicUrl(value);
  }

  Future<T> _run<T>(String what, Future<T> Function() body) async {
    try {
      return await body();
    } catch (error, stack) {
      final failure = mapSupabaseError(error);
      // Expected outcomes (not found) aren't logged as errors.
      if (failure.type != FailureType.notFound) {
        AppLogger.error('Catalog: loading $what failed (${failure.type.name})',
            error: failure.debugMessage, stackTrace: stack);
      }
      throw failure;
    }
  }
}

/// Parses rows, skipping individually malformed ones (logged) so a single bad
/// record doesn't hide the whole catalog. If every row is malformed the
/// payload is considered invalid.
List<T> parseRows<T>(List<Map<String, dynamic>> rows, T Function(Map<String, dynamic>) parse, String source) {
  final parsed = <T>[];
  for (final row in rows) {
    try {
      parsed.add(parse(row));
    } on FormatException catch (e) {
      AppLogger.error('Skipping malformed $source row ${row['id'] ?? row['slug'] ?? '?'}: ${e.message}');
    }
  }
  if (rows.isNotEmpty && parsed.isEmpty) {
    throw AppFailure(FailureType.invalidData, debugMessage: 'All ${rows.length} $source rows were malformed');
  }
  return parsed;
}
