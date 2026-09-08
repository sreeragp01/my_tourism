from typing import Dict, Any, Optional
from .adapters import BaseSearchAdapter, DatabaseSearchAdapter, get_search_adapter


class UnifiedSearchService:
    """
    Unified Discovery & Search Service for KeraLink.
    Orchestrates search queries across Destinations, Experiences, Stays, and Attractions.
    Supports multi-criteria filtering, geo-proximity sorting, and deterministic pagination.
    """

    def __init__(self, adapter: Optional[BaseSearchAdapter] = None):
        self.adapter = adapter or get_search_adapter()

    def search(self, params: Dict[str, Any]) -> Dict[str, Any]:
        page = max(1, int(params.get('page') or 1))
        page_size = min(100, max(1, int(params.get('page_size') or 20)))

        # Retrieve raw multi-model search result sets
        raw = self.adapter.search(params)

        destinations = raw.get('destinations', [])
        experiences = raw.get('experiences', [])
        accommodations = raw.get('accommodations', [])
        attractions = raw.get('attractions', [])

        total_count = len(destinations) + len(experiences) + len(accommodations) + len(attractions)

        # Pagination: calculate window
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size

        # If a specific type was requested, slice that array;
        # otherwise, slice all categorized arrays gracefully.
        item_type = params.get('type') or 'all'

        if item_type in ('destinations', 'destination'):
            paged_dest = destinations[start_idx:end_idx]
            has_next = end_idx < len(destinations)
            return {
                'query': params.get('q', ''),
                'total_count': len(destinations),
                'page': page,
                'page_size': page_size,
                'has_next': has_next,
                'destinations': paged_dest,
                'experiences': [],
                'accommodations': [],
                'attractions': [],
            }
        elif item_type in ('experiences', 'experience'):
            paged_exp = experiences[start_idx:end_idx]
            has_next = end_idx < len(experiences)
            return {
                'query': params.get('q', ''),
                'total_count': len(experiences),
                'page': page,
                'page_size': page_size,
                'has_next': has_next,
                'destinations': [],
                'experiences': paged_exp,
                'accommodations': [],
                'attractions': [],
            }
        elif item_type in ('accommodations', 'accommodation', 'stays', 'stay'):
            paged_acc = accommodations[start_idx:end_idx]
            has_next = end_idx < len(accommodations)
            return {
                'query': params.get('q', ''),
                'total_count': len(accommodations),
                'page': page,
                'page_size': page_size,
                'has_next': has_next,
                'destinations': [],
                'experiences': [],
                'accommodations': paged_acc,
                'attractions': [],
            }
        elif item_type in ('attractions', 'attraction'):
            paged_att = attractions[start_idx:end_idx]
            has_next = end_idx < len(attractions)
            return {
                'query': params.get('q', ''),
                'total_count': len(attractions),
                'page': page,
                'page_size': page_size,
                'has_next': has_next,
                'destinations': [],
                'experiences': [],
                'accommodations': [],
                'attractions': paged_att,
            }
        else:
            # Unified 'all' results
            has_next = end_idx < total_count
            return {
                'query': params.get('q', ''),
                'total_count': total_count,
                'page': page,
                'page_size': page_size,
                'has_next': has_next,
                'destinations': destinations[start_idx:end_idx],
                'experiences': experiences[start_idx:end_idx],
                'accommodations': accommodations[start_idx:end_idx],
                'attractions': attractions[start_idx:end_idx],
            }
