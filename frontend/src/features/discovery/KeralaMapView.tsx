import React from 'react';
import L from 'leaflet';
import { useAppStore } from '../../stores/useAppStore';
import { KERALA_DESTINATIONS } from '../../data/keralaData';
import {
  MapPin,
  Sparkles,
  ArrowRight,
  Layers,
  Compass,
  Navigation,
  CloudRain,
  Sun,
  Maximize2,
  Minimize2,
  Route,
  Info,
} from 'lucide-react';
import { Destination } from '../../types/contracts';
import { httpAdapter } from '../../adapters/httpAdapter';

type MapStyle = 'DARK' | 'SATELLITE' | 'STREET';

const TILE_PROVIDERS: Record<MapStyle, { url: string; attribution: string; name: string }> = {
  DARK: {
    url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    attribution: '&copy; <a href="https://carto.com/">CARTO</a>, &copy; OpenStreetMap',
    name: 'Dark Emerald',
  },
  SATELLITE: {
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '&copy; Esri, Maxar, Earthstar Geographics',
    name: 'Satellite',
  },
  STREET: {
    url: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    attribution: '&copy; <a href="https://carto.com/">CARTO</a>, &copy; OpenStreetMap',
    name: 'Voyager / Street',
  },
};

export const KeralaMapView: React.FC = () => {
  const { destinations, navigateTo, setSelectedDestination } = useAppStore();

  // Combine store destinations with fallback launch corridor data
  const destinationList: Destination[] = React.useMemo(() => {
    if (destinations && destinations.length > 0) return destinations;
    return KERALA_DESTINATIONS;
  }, [destinations]);

  const [activePin, setActivePin] = React.useState<Destination>(destinationList[0]);
  const [selectedCategory, setSelectedCategory] = React.useState<string>('ALL');
  const [mapStyle, setMapStyle] = React.useState<MapStyle>('DARK');
  const [viewType, setViewType] = React.useState<'LEAFLET' | 'ILLUSTRATED'>('LEAFLET');
  const [weatherTelemetry, setWeatherTelemetry] = React.useState<any>(null);
  const [isRouteActive, setIsRouteActive] = React.useState<boolean>(true);
  const [routeInfo, setRouteInfo] = React.useState<{ distanceKm: number; durationHours: number } | null>(null);

  const mapContainerRef = React.useRef<HTMLDivElement>(null);
  const mapInstanceRef = React.useRef<L.Map | null>(null);
  const tileLayerRef = React.useRef<L.TileLayer | null>(null);
  const markersGroupRef = React.useRef<L.LayerGroup | null>(null);
  const routePolylineRef = React.useRef<L.Polyline | null>(null);

  // Filter destinations by category / district profile
  const filteredDestinations = React.useMemo(() => {
    if (selectedCategory === 'ALL') return destinationList;
    if (selectedCategory === 'HILLS') {
      return destinationList.filter((d) =>
        ['munnar', 'wayanad', 'thekkady'].some((k) => d.id.toLowerCase().includes(k) || d.slug.toLowerCase().includes(k))
      );
    }
    if (selectedCategory === 'BACKWATERS') {
      return destinationList.filter((d) =>
        ['alleppey', 'kumarakom', 'alappuzha'].some((k) => d.id.toLowerCase().includes(k) || d.slug.toLowerCase().includes(k))
      );
    }
    if (selectedCategory === 'BEACHES') {
      return destinationList.filter((d) =>
        ['varkala', 'kovalam', 'bekal', 'marari'].some((k) => d.id.toLowerCase().includes(k) || d.slug.toLowerCase().includes(k))
      );
    }
    if (selectedCategory === 'CULTURE') {
      return destinationList.filter((d) =>
        ['kochi', 'thrissur', 'trivandrum'].some((k) => d.id.toLowerCase().includes(k) || d.slug.toLowerCase().includes(k))
      );
    }
    return destinationList;
  }, [destinationList, selectedCategory]);

  // Fetch live weather telemetry for the selected pin
  React.useEffect(() => {
    let isSubscribed = true;
    const destSlug = activePin.slug || activePin.id;
    httpAdapter.getDestinationWeather(destSlug).then((data) => {
      if (isSubscribed) {
        setWeatherTelemetry(data);
      }
    });
    return () => {
      isSubscribed = false;
    };
  }, [activePin]);

  // Initialize Leaflet Map
  React.useEffect(() => {
    if (viewType !== 'LEAFLET') return;
    if (!mapContainerRef.current) return;

    // Destroy existing instance if container already initialized
    if (mapInstanceRef.current) {
      mapInstanceRef.current.remove();
      mapInstanceRef.current = null;
    }

    // Default center on central Kerala (Idukki / Ernakulam corridor)
    const map = L.map(mapContainerRef.current, {
      center: [9.98, 76.58],
      zoom: 8,
      zoomControl: false,
      attributionControl: false,
      minZoom: 6,
      maxZoom: 18,
    });

    // Custom zoom control in bottom-right
    L.control.zoom({ position: 'bottomright' }).addTo(map);

    // Add Tile Layer
    const tileConf = TILE_PROVIDERS[mapStyle];
    const tileLayer = L.tileLayer(tileConf.url, {
      maxZoom: 19,
      subdomains: 'abcd',
    }).addTo(map);

    const markersGroup = L.layerGroup().addTo(map);

    tileLayerRef.current = tileLayer;
    markersGroupRef.current = markersGroup;
    mapInstanceRef.current = map;

    // Invalidate size after layout mounts
    const timer = setTimeout(() => {
      map.invalidateSize();
    }, 250);

    return () => {
      clearTimeout(timer);
      map.remove();
      mapInstanceRef.current = null;
    };
  }, [viewType]);

  // Update Tile Layer when style changes
  React.useEffect(() => {
    if (!mapInstanceRef.current || !tileLayerRef.current) return;
    const tileConf = TILE_PROVIDERS[mapStyle];
    tileLayerRef.current.setUrl(tileConf.url);
  }, [mapStyle]);

  // Render Destination Markers on Leaflet Map
  React.useEffect(() => {
    const map = mapInstanceRef.current;
    const markersGroup = markersGroupRef.current;
    if (!map || !markersGroup) return;

    markersGroup.clearLayers();

    filteredDestinations.forEach((dest) => {
      const lat = dest.coordinates?.lat ?? 10.0;
      const lng = dest.coordinates?.lng ?? 76.5;
      const isSelected = activePin.id === dest.id;

      // Custom DivIcon with glowing ring & badge
      const customIcon = L.divIcon({
        className: 'custom-leaflet-marker',
        html: `
          <div style="position: relative; display: flex; flex-direction: column; align-items: center; cursor: pointer;">
            <div style="
              width: ${isSelected ? '36px' : '28px'};
              height: ${isSelected ? '36px' : '28px'};
              border-radius: 9999px;
              display: flex;
              align-items: center;
              justify-content: center;
              background: ${isSelected ? '#D4AF37' : '#0F2823'};
              color: ${isSelected ? '#0F2823' : '#D4AF37'};
              border: 2px solid ${isSelected ? '#FFFFFF' : '#D4AF37'};
              box-shadow: ${isSelected ? '0 0 16px rgba(212, 175, 55, 0.9)' : '0 4px 10px rgba(0,0,0,0.5)'};
              transform: scale(${isSelected ? '1.15' : '1.0'});
              transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
            ">
              <span style="font-size: ${isSelected ? '15px' : '12px'}; font-weight: bold;">🌴</span>
            </div>
            <div style="
              margin-top: 4px;
              padding: 2px 8px;
              border-radius: 9999px;
              font-size: 10px;
              font-weight: 700;
              letter-spacing: 0.02em;
              white-space: nowrap;
              background: ${isSelected ? '#D4AF37' : 'rgba(15, 40, 35, 0.92)'};
              color: ${isSelected ? '#0F2823' : '#F7F3E8'};
              border: 1px solid ${isSelected ? '#FFFFFF' : 'rgba(212, 175, 55, 0.4)'};
              box-shadow: 0 2px 6px rgba(0,0,0,0.6);
            ">
              ${dest.name.split(' ')[0]}
            </div>
          </div>
        `,
        iconSize: [80, 50],
        iconAnchor: [40, 25],
      });

      const marker = L.marker([lat, lng], { icon: customIcon });

      marker.on('click', () => {
        setActivePin(dest);
        map.flyTo([lat, lng], Math.max(map.getZoom(), 10), {
          duration: 1.2,
          easeLinearity: 0.25,
        });
      });

      markersGroup.addLayer(marker);
    });
  }, [filteredDestinations, activePin]);

  // Draw Scenic Highway Corridor Route Polylines
  React.useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map) return;

    if (routePolylineRef.current) {
      map.removeLayer(routePolylineRef.current);
      routePolylineRef.current = null;
    }

    if (!isRouteActive) return;

    // Major corridor waypoints (Kochi -> Munnar -> Thekkady -> Alleppey -> Varkala)
    const corridorCoords: [number, number][] = [
      [9.9656, 76.2421], // Fort Kochi
      [10.0889, 77.0595], // Munnar Hills
      [9.6031, 77.1615], // Thekkady
      [9.4981, 76.3388], // Alleppey
      [8.7379, 76.7163], // Varkala Cliff
    ];

    // Attempt to fetch real OSRM driving polyline from backend
    httpAdapter
      .getRoute(corridorCoords[0][0], corridorCoords[0][1], corridorCoords[1][0], corridorCoords[1][1])
      .then((data) => {
        let polyCoords: [number, number][] = corridorCoords;
        if (data && data.polyline && data.polyline.length > 0) {
          polyCoords = data.polyline;
          setRouteInfo({ distanceKm: data.distance_km, durationHours: data.duration_hours });
        } else {
          setRouteInfo({ distanceKm: 345, durationHours: 7.5 });
        }

        const polyline = L.polyline(polyCoords, {
          color: '#D4AF37',
          weight: 4,
          opacity: 0.85,
          dashArray: '8, 6',
          lineCap: 'round',
        }).addTo(map);

        routePolylineRef.current = polyline;
      })
      .catch(() => {
        const polyline = L.polyline(corridorCoords, {
          color: '#D4AF37',
          weight: 3.5,
          opacity: 0.75,
          dashArray: '6, 6',
        }).addTo(map);
        routePolylineRef.current = polyline;
      });
  }, [isRouteActive]);

  const handleCenterOnDestination = (dest: Destination) => {
    setActivePin(dest);
    if (mapInstanceRef.current) {
      const lat = dest.coordinates?.lat ?? 10.0;
      const lng = dest.coordinates?.lng ?? 76.5;
      mapInstanceRef.current.flyTo([lat, lng], 11, { duration: 1.2 });
    }
  };

  return (
    <div className="relative h-full flex flex-col bg-[#0A1D19] text-[#F7F3E8] overflow-hidden">
      {/* Top Map Filter & Layer Header */}
      <div className="p-3 sm:p-4 bg-[#0F2823]/95 backdrop-blur-md border-b border-[#D4AF37]/20 z-20 space-y-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Compass className="w-5 h-5 text-[#D4AF37]" />
            <div>
              <h2 className="font-serif text-base sm:text-lg font-bold leading-tight">
                Interactive Kerala Map
              </h2>
              <p className="text-[10px] text-[#C5D8CD] hidden sm:block">
                OpenStreetMap & OSRM Live Corridor Routing
              </p>
            </div>
          </div>

          {/* Right Action Controls */}
          <div className="flex items-center gap-1.5">
            {/* View Mode Toggle: Interactive Leaflet vs Stylized Graphic */}
            <div className="bg-[#144032] border border-[#D4AF37]/30 rounded-lg p-0.5 flex items-center text-[10px] font-bold">
              <button
                onClick={() => setViewType('LEAFLET')}
                className={`px-2 py-1 rounded transition-all ${
                  viewType === 'LEAFLET' ? 'bg-[#D4AF37] text-[#0F2823] shadow-sm' : 'text-[#C5D8CD]'
                }`}
              >
                Tile Map
              </button>
              <button
                onClick={() => setViewType('ILLUSTRATED')}
                className={`px-2 py-1 rounded transition-all ${
                  viewType === 'ILLUSTRATED' ? 'bg-[#D4AF37] text-[#0F2823] shadow-sm' : 'text-[#C5D8CD]'
                }`}
              >
                Contour
              </button>
            </div>

            {/* Tile Style Selector (When in Leaflet mode) */}
            {viewType === 'LEAFLET' && (
              <div className="hidden sm:flex items-center gap-1 bg-[#144032] border border-white/10 rounded-lg p-0.5 text-[10px]">
                {(['DARK', 'SATELLITE', 'STREET'] as MapStyle[]).map((style) => (
                  <button
                    key={style}
                    onClick={() => setMapStyle(style)}
                    className={`px-2 py-0.5 rounded font-semibold transition-all ${
                      mapStyle === style
                        ? 'bg-[#D4AF37] text-[#0F2823]'
                        : 'text-[#C5D8CD] hover:text-white'
                    }`}
                  >
                    {style === 'DARK' ? '🌙 Dark' : style === 'SATELLITE' ? '🛰️ Satellite' : '🗺️ Street'}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Filter Pills */}
        <div className="flex items-center justify-between gap-2 overflow-x-auto scrollbar-none pt-1">
          <div className="flex items-center gap-1.5">
            {(['ALL', 'HILLS', 'BACKWATERS', 'BEACHES', 'CULTURE'] as const).map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-2.5 py-1 rounded-full text-[10px] font-bold tracking-wider transition-all uppercase whitespace-nowrap ${
                  selectedCategory === cat
                    ? 'bg-[#D4AF37] text-[#0F2823] shadow-gold'
                    : 'bg-[#144032] text-[#C5D8CD] hover:text-white'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>

          {/* Toggle Route Overlay Button */}
          {viewType === 'LEAFLET' && (
            <button
              onClick={() => setIsRouteActive(!isRouteActive)}
              className={`px-2 py-1 rounded-md text-[10px] font-bold flex items-center gap-1 shrink-0 transition-all ${
                isRouteActive
                  ? 'bg-[#D4AF37]/20 text-[#D4AF37] border border-[#D4AF37]/40'
                  : 'bg-[#144032] text-gray-400 border border-white/10'
              }`}
            >
              <Route className="w-3 h-3" />
              <span>Corridor Route</span>
            </button>
          )}
        </div>
      </div>

      {/* Main Map Container */}
      <div className="flex-1 relative w-full h-full">
        {viewType === 'LEAFLET' ? (
          /* Live Leaflet OpenStreetMap Container */
          <div className="w-full h-full relative">
            <div ref={mapContainerRef} className="w-full h-full min-h-[360px]" />

            {/* Floating Quick Destination Chips */}
            <div className="absolute top-3 left-3 right-3 z-[1000] flex items-center gap-1.5 overflow-x-auto scrollbar-none pointer-events-auto">
              {filteredDestinations.slice(0, 6).map((dest) => (
                <button
                  key={dest.id}
                  onClick={() => handleCenterOnDestination(dest)}
                  className={`px-2.5 py-1 rounded-xl text-[11px] font-bold shadow-lg backdrop-blur-md transition-all flex items-center gap-1 shrink-0 ${
                    activePin.id === dest.id
                      ? 'bg-[#D4AF37] text-[#0F2823] ring-2 ring-white/50 scale-105'
                      : 'bg-[#0F2823]/90 text-[#F7F3E8] border border-[#D4AF37]/30 hover:border-[#D4AF37]'
                  }`}
                >
                  <MapPin className="w-3 h-3" />
                  <span>{dest.name.split(' ')[0]}</span>
                </button>
              ))}
            </div>

            {/* Route Stats Badge Overlay */}
            {isRouteActive && routeInfo && (
              <div className="absolute bottom-3 left-3 z-[1000] bg-[#0F2823]/90 backdrop-blur-md border border-[#D4AF37]/40 rounded-xl px-2.5 py-1 text-[10px] flex items-center gap-2 shadow-lg">
                <Navigation className="w-3.5 h-3.5 text-[#D4AF37] animate-pulse" />
                <span>
                  <strong className="text-white">OSRM Scenic Trail:</strong> {routeInfo.distanceKm} km (~
                  {routeInfo.durationHours} hrs drive)
                </span>
              </div>
            )}
          </div>
        ) : (
          /* Stylized Artistic Contour Representation */
          <div className="w-full h-full bg-gradient-to-b from-[#0F2823] via-[#144032] to-[#0A1D19] flex items-center justify-center p-4">
            <div className="relative w-full max-w-[340px] h-[460px] bg-[#10352A]/70 rounded-3xl border border-[#D4AF37]/30 shadow-2xl p-4 overflow-hidden">
              <div className="absolute inset-y-0 left-0 w-16 bg-gradient-to-r from-teal-900/30 to-transparent pointer-events-none" />
              <span className="absolute top-1/2 left-2 -rotate-90 text-[10px] font-serif text-[#C5D8CD]/40 uppercase tracking-widest pointer-events-none">
                Arabian Sea
              </span>
              <div className="absolute inset-y-0 right-0 w-24 bg-gradient-to-l from-emerald-950/60 to-transparent pointer-events-none" />
              <span className="absolute top-1/3 right-2 rotate-90 text-[10px] font-serif text-[#D4AF37]/40 uppercase tracking-widest pointer-events-none">
                Western Ghats (1,600m)
              </span>

              {/* Destination markers on illustrated map */}
              {destinationList.map((dest, idx) => {
                const isSelected = activePin.id === dest.id;
                const topPerc = 20 + idx * 8;
                const leftPerc = 40 + (idx % 2 === 0 ? 15 : -5);

                return (
                  <div
                    key={dest.id}
                    onClick={() => setActivePin(dest)}
                    style={{ top: `${topPerc}%`, left: `${leftPerc}%` }}
                    className="absolute -translate-x-1/2 -translate-y-1/2 cursor-pointer z-10"
                  >
                    <div
                      className={`w-8 h-8 rounded-full flex items-center justify-center transition-all ${
                        isSelected
                          ? 'bg-[#D4AF37] text-[#0F2823] scale-125 shadow-gold ring-4 ring-[#D4AF37]/40'
                          : 'bg-[#144032] text-[#D4AF37] border border-[#D4AF37]/60'
                      }`}
                    >
                      <MapPin className="w-3.5 h-3.5" />
                    </div>
                    <span className="absolute top-9 left-1/2 -translate-x-1/2 whitespace-nowrap px-1.5 py-0.5 rounded text-[9px] font-bold bg-[#0F2823]/90 text-white border border-white/10">
                      {dest.name.split(' ')[0]}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* Bottom Selected Destination Telemetry Drawer */}
      <div className="p-3.5 bg-[#0F2823] border-t border-[#D4AF37]/30 z-20 shadow-2xl">
        <div className="flex gap-3">
          <img
            src={activePin.heroImage || 'https://images.unsplash.com/photo-1544735716-392fe2489ffa'}
            alt={activePin.name}
            className="w-20 h-20 sm:w-24 sm:h-24 rounded-2xl object-cover border border-[#D4AF37]/40 shadow-md shrink-0"
          />

          <div className="flex-1 min-w-0">
            {/* Badges: District & Live Weather */}
            <div className="flex items-center justify-between gap-1 flex-wrap">
              <span className="text-[10px] font-bold text-[#D4AF37] uppercase tracking-wider">
                {activePin.district || 'Kerala'} District
              </span>

              {weatherTelemetry && (
                <div className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-[#144032] border border-[#D4AF37]/30 text-[10px] font-semibold text-emerald-300">
                  {weatherTelemetry.rain_probability_percent >= 50 ? (
                    <CloudRain className="w-3 h-3 text-cyan-400" />
                  ) : (
                    <Sun className="w-3 h-3 text-amber-400" />
                  )}
                  <span>
                    {weatherTelemetry.temperature_celsius ?? 22}°C • {weatherTelemetry.rain_probability_percent ?? 20}% Rain
                  </span>
                </div>
              )}
            </div>

            <h3 className="font-serif text-base font-bold text-white mt-0.5 truncate">
              {activePin.name}
            </h3>
            <p className="text-[11px] text-[#C5D8CD] line-clamp-1 italic font-serif">
              "{activePin.tagline}"
            </p>

            {/* Action Buttons */}
            <div className="flex items-center gap-2 mt-2">
              <button
                onClick={() => {
                  setSelectedDestination(activePin);
                  navigateTo('EXPLORE');
                }}
                className="px-3 py-1.5 rounded-xl bg-[#D4AF37] text-[#0F2823] text-xs font-bold shadow-gold flex items-center gap-1 hover:opacity-95"
              >
                <span>Explore Hub</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>

              <button
                onClick={() => {
                  setSelectedDestination(activePin);
                  navigateTo('AI_PLANNER');
                }}
                className="px-3 py-1.5 rounded-xl bg-[#144032] text-[#F7F3E8] text-xs font-semibold border border-[#D4AF37]/30 hover:border-[#D4AF37] flex items-center gap-1"
              >
                <Sparkles className="w-3 h-3 text-[#D4AF37]" />
                <span>AI Plan</span>
              </button>

              {activePin.coordinates && (
                <button
                  onClick={() => handleCenterOnDestination(activePin)}
                  title="Fly camera to destination coordinates"
                  className="p-1.5 rounded-xl bg-[#144032] text-[#D4AF37] border border-white/10 hover:border-[#D4AF37]"
                >
                  <Navigation className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
