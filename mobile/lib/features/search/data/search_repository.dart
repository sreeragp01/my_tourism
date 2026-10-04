import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../models/search_result_model.dart';
import '../../home/models/destination_model.dart';

class SearchRepository {
  final ApiClient _apiClient;
  final Map<String, SearchResults> _cache = {};

  SearchRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<SearchResults> search(SearchFilter filter) async {
    final queryParams = filter.toQueryParams();
    final cacheKey = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    try {
      final response = await _apiClient.get(
        ApiConstants.search,
        queryParameters: queryParams,
        requiresAuth: false,
      );

      final Map<String, dynamic> data = (response is Map<String, dynamic>)
          ? response
          : <String, dynamic>{};

      final results = SearchResults.fromJson(data);
      _cache[cacheKey] = results;
      return results;
    } on ApiException catch (_) {
      // Offline fallback: return cached results if available
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }

      // If network fails and no exact cache exists, provide offline fallback
      return _generateOfflineFallback(filter);
    } catch (e) {
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }
      return _generateOfflineFallback(filter);
    }
  }

  SearchResults _generateOfflineFallback(SearchFilter filter) {
    final q = filter.query.toLowerCase();
    final offlineDestinations = [
      const Destination(
        id: 'munnar',
        name: 'Munnar',
        slug: 'munnar',
        district: 'Idukki',
        tagline: 'Misty Tea Hills & Cloud-Kissed Valleys',
        description: 'Perched at 1,600m in the Western Ghats with rolling tea estates.',
        heroImage: 'https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=1200&q=80',
        latitude: 10.0889,
        longitude: 77.0595,
        bestSeason: 'September to March',
        tags: ['Hills', 'Tea', 'Romance'],
        familyFriendly: true,
      ),
      const Destination(
        id: 'alleppey',
        name: 'Alleppey (Alappuzha)',
        slug: 'alleppey',
        district: 'Alappuzha',
        tagline: 'Emerald Backwaters & Luxury Houseboats',
        description: 'Network of tranquil canals, palm-fringed lagoons, and backwaters.',
        heroImage: 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=1200&q=80',
        latitude: 9.4981,
        longitude: 76.3388,
        bestSeason: 'October to March',
        tags: ['Backwaters', 'Houseboat'],
        familyFriendly: true,
      ),
    ];

    final filtered = offlineDestinations.where((d) {
      if (q.isNotEmpty &&
          !d.name.toLowerCase().contains(q) &&
          !d.district.toLowerCase().contains(q) &&
          !d.tagline.toLowerCase().contains(q)) {
        return false;
      }
      if (filter.familyFriendly != null && d.familyFriendly != filter.familyFriendly) {
        return false;
      }
      return true;
    }).toList();

    return SearchResults(
      query: filter.query,
      totalCount: filtered.length,
      page: filter.page,
      pageSize: filter.pageSize,
      hasNext: false,
      destinations: filtered,
    );
  }
}
