import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../models/destination_model.dart';

class DestinationRepository {
  final ApiClient apiClient;
  final ISecureTokenStorage storage;

  List<Destination>? _cachedDestinations;

  DestinationRepository({
    required this.apiClient,
    required this.storage,
  });

  /// Fetch all destinations with memory & persistent fallback
  Future<List<Destination>> getDestinations({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedDestinations != null && _cachedDestinations!.isNotEmpty) {
      return _cachedDestinations!;
    }

    try {
      final response = await apiClient.get(
        ApiConstants.destinations,
        requiresAuth: false,
      );

      final list = (response as List)
          .map((item) => Destination.fromJson(item as Map<String, dynamic>))
          .toList();

      _cachedDestinations = list;

      // Save to local cache for offline resiliency
      try {
        final encoded = jsonEncode(list.map((d) => d.toJson()).toList());
        await storage.saveUserData(encoded);
      } catch (_) {}

      return list;
    } catch (e) {
      // Offline fallback: load cached destinations
      if (_cachedDestinations != null && _cachedDestinations!.isNotEmpty) {
        return _cachedDestinations!;
      }

      // If no network and no cache, return calibrated offline baseline
      return _getCalibratedOfflineDestinations();
    }
  }

  /// Retrieve a single destination by slug (e.g. 'munnar')
  Future<Destination> getDestinationBySlug(String slug) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.destinations}$slug/',
        requiresAuth: false,
      );
      return Destination.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      final all = await getDestinations();
      return all.firstWhere(
        (d) => d.slug == slug || d.id == slug,
        orElse: () => all.first,
      );
    }
  }

  List<Destination> _getCalibratedOfflineDestinations() {
    return [
      const Destination(
        id: 'munnar',
        name: 'Munnar',
        slug: 'munnar',
        district: 'Idukki',
        tagline: 'Misty Tea Hills & Valleys',
        description: 'Emerald tea plantations, mountain peaks, and crisp air.',
        heroImage: 'https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=800&q=80',
        latitude: 10.0889,
        longitude: 77.0595,
        tags: ['Hills', 'Tea Estates', 'Nature'],
      ),
      const Destination(
        id: 'alleppey',
        name: 'Alleppey (Alappuzha)',
        slug: 'alleppey',
        district: 'Alappuzha',
        tagline: 'Serene Backwaters & Houseboats',
        description: 'Tranquil canals, paddy fields, and traditional thatched kettuvallams.',
        heroImage: 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80',
        latitude: 9.4981,
        longitude: 76.3388,
        tags: ['Backwaters', 'Houseboats', 'Relaxation'],
      ),
      const Destination(
        id: 'kochi',
        name: 'Fort Kochi',
        slug: 'kochi',
        district: 'Ernakulam',
        tagline: 'Historic Spice Port & Biennale',
        description: 'Colonial lanes, Chinese fishing nets, and Kathakali theatres.',
        heroImage: 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80',
        latitude: 9.9656,
        longitude: 76.2421,
        tags: ['Culture', 'Heritage', 'Art'],
      ),
    ];
  }
}
