from dataclasses import dataclass, field, asdict
from typing import List, Dict, Any, Optional
import uuid

@dataclass
class TravelSegment:
    from_name: str
    to_name: str
    from_coords: Dict[str, float]
    to_coords: Dict[str, float]
    distance_km: float
    duration_minutes: int
    is_ghat_route: bool = False
    origin: Optional[str] = None
    destination: Optional[str] = None
    distance: Optional[float] = None
    duration: Optional[int] = None

    def __post_init__(self):
        if not self.origin:
            self.origin = self.from_name
        if not self.destination:
            self.destination = self.to_name
        if self.distance is None:
            self.distance = self.distance_km
        if self.duration is None:
            self.duration = self.duration_minutes

    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        data['origin'] = self.from_name
        data['destination'] = self.to_name
        data['distance'] = self.distance_km
        data['duration'] = self.duration_minutes
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'TravelSegment':
        from_name = data.get('origin') or data.get('from_name', '')
        to_name = data.get('destination') or data.get('to_name', '')
        dist = float(data.get('distance', data.get('distance_km', 0.0)))
        dur = int(data.get('duration', data.get('duration_minutes', 0)))
        return cls(
            from_name=from_name,
            to_name=to_name,
            from_coords=data.get('from_coords', {'lat': 0.0, 'lng': 0.0}),
            to_coords=data.get('to_coords', {'lat': 0.0, 'lng': 0.0}),
            distance_km=dist,
            duration_minutes=dur,
            is_ghat_route=bool(data.get('is_ghat_route', False)),
            origin=from_name,
            destination=to_name,
            distance=dist,
            duration=dur,
        )

@dataclass
class ItineraryEvent:
    id: str
    type: str # 'EXPERIENCE', 'ACTIVITY', 'MEAL', 'STAY', 'TRANSIT', 'LEISURE'
    title: str
    destination_id: str
    destination_name: str
    coordinates: Dict[str, float]
    time: str = '09:00'
    start_time: str = '09:00'
    end_time: str = '10:00'
    duration_mins: int = 60
    duration: int = 60
    order: int = 1
    entity_type: str = 'ACTIVITY'
    entity_id: Optional[str] = None
    travel_duration_mins: int = 0
    experience_id: Optional[str] = None
    attraction_id: Optional[str] = None
    accommodation_id: Optional[str] = None
    availability_required: bool = False
    price: float = 0.0
    rain_friendly: bool = True
    rain_alternative_id: Optional[str] = None
    booking_required: bool = False
    metadata: Dict[str, Any] = field(default_factory=dict)

    def __post_init__(self):
        if not self.entity_type:
            self.entity_type = self.type
        if not self.entity_id:
            self.entity_id = self.experience_id or self.attraction_id or self.accommodation_id
        if not self.duration:
            self.duration = self.duration_mins
        if not self.start_time:
            self.start_time = self.time

    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        data['entity_type'] = self.entity_type or self.type
        data['entity_id'] = self.entity_id or self.experience_id or self.attraction_id or self.accommodation_id
        data['order'] = self.order
        data['start_time'] = self.start_time or self.time
        data['duration'] = self.duration_mins
        return data

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ItineraryEvent':
        coords = data.get('coordinates')
        if not isinstance(coords, dict):
            coords = {'lat': 10.0889, 'lng': 77.0595}

        time_val = data.get('time') or data.get('start_time') or '09:00'
        type_val = str(data.get('entity_type') or data.get('type', 'ACTIVITY')).upper()
        entity_id_val = data.get('entity_id') or data.get('experience_id') or data.get('attraction_id') or data.get('accommodation_id')
        dur = int(data.get('duration') or data.get('duration_mins', 60))

        return cls(
            id=str(data.get('id') or f"evt_{uuid.uuid4().hex[:8]}"),
            type=type_val,
            entity_type=type_val,
            title=str(data.get('title', 'Scheduled Activity')),
            destination_id=str(data.get('destination_id', '')),
            destination_name=str(data.get('destination_name', '')),
            coordinates=coords,
            time=time_val,
            start_time=data.get('start_time') or time_val,
            end_time=data.get('end_time') or '10:00',
            duration_mins=dur,
            duration=dur,
            order=int(data.get('order', 1)),
            entity_id=str(entity_id_val) if entity_id_val is not None else None,
            travel_duration_mins=int(data.get('travel_duration_mins', 0)),
            experience_id=str(data.get('experience_id')) if data.get('experience_id') else (str(entity_id_val) if type_val == 'EXPERIENCE' else None),
            attraction_id=str(data.get('attraction_id')) if data.get('attraction_id') else (str(entity_id_val) if type_val == 'ACTIVITY' else None),
            accommodation_id=str(data.get('accommodation_id')) if data.get('accommodation_id') else (str(entity_id_val) if type_val == 'STAY' else None),
            availability_required=bool(data.get('availability_required', False)),
            price=float(data.get('price', 0.0)),
            rain_friendly=bool(data.get('rain_friendly', True)),
            rain_alternative_id=data.get('rain_alternative_id'),
            booking_required=bool(data.get('booking_required', False)),
            metadata=dict(data.get('metadata') or {}),
        )

@dataclass
class ItineraryDay:
    day_number: int
    destination_id: str
    destination_name: str
    theme_title: str
    date: Optional[str] = None
    destination: Optional[Dict[str, Any]] = None
    timeline: List[ItineraryEvent] = field(default_factory=list)
    travel_segments: List[TravelSegment] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            'day_number': self.day_number,
            'date': self.date,
            'destination_id': self.destination_id,
            'destination_name': self.destination_name,
            'destination': self.destination or {'id': self.destination_id, 'name': self.destination_name},
            'theme_title': self.theme_title,
            'timeline': [ev.to_dict() for ev in self.timeline],
            'travel_segments': [seg.to_dict() for seg in self.travel_segments],
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ItineraryDay':
        raw_timeline = data.get('timeline', [])
        timeline_objs = [ItineraryEvent.from_dict(ev) for ev in raw_timeline]
        # Ensure sequential order
        for idx, ev in enumerate(timeline_objs, 1):
            if not ev.order or ev.order == 1:
                ev.order = idx
        raw_segments = data.get('travel_segments', [])
        seg_objs = [TravelSegment.from_dict(s) for s in raw_segments]

        dest_id = str(data.get('destination_id', ''))
        dest_name = str(data.get('destination_name', ''))
        dest_dict = data.get('destination') or {'id': dest_id, 'name': dest_name}

        return cls(
            day_number=int(data.get('day_number', 1)),
            date=data.get('date'),
            destination_id=dest_id,
            destination_name=dest_name,
            destination=dest_dict,
            theme_title=str(data.get('theme_title', '')),
            timeline=timeline_objs,
            travel_segments=seg_objs,
        )
