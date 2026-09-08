import React from 'react';
import { httpAdapter } from '../../adapters/httpAdapter';
import { CloudRain, Sun, Cloud, AlertTriangle, ShieldCheck, RefreshCw, Wind } from 'lucide-react';
import { useAppStore } from '../../stores/useAppStore';

interface WeatherCardData {
  slug: string;
  name: string;
  temp: number;
  condition: string;
  rainProb: number;
  roadStatus: string;
  provider: string;
  isGhat: boolean;
}

export const LiveWeatherRibbon: React.FC = () => {
  const { navigateTo, setSelectedDestination, destinations } = useAppStore();
  const [corridorWeather, setCorridorWeather] = React.useState<WeatherCardData[]>([]);
  const [loading, setLoading] = React.useState<boolean>(true);
  const [lastUpdated, setLastUpdated] = React.useState<string>('Just now');

  const hubs = React.useMemo(
    () => [
      { slug: 'munnar', name: 'Munnar Hills', isGhat: true },
      { slug: 'kochi', name: 'Fort Kochi', isGhat: false },
      { slug: 'alleppey', name: 'Alleppey Backwaters', isGhat: false },
      { slug: 'thekkady', name: 'Thekkady Periyar', isGhat: true },
      { slug: 'wayanad', name: 'Wayanad High', isGhat: true },
    ],
    []
  );

  const fetchCorridorData = React.useCallback(async () => {
    setLoading(true);
    try {
      const results = await Promise.all(
        hubs.map(async (hub) => {
          const w = await httpAdapter.getDestinationWeather(hub.slug);
          return {
            slug: hub.slug,
            name: hub.name,
            temp: w.temperature_celsius ?? 22,
            condition: w.condition ?? 'PARTLY CLOUDY',
            rainProb: w.rain_probability_percent ?? 30,
            roadStatus: w.ghat_road_status ?? 'CLEAR',
            provider: w.provider ?? 'Live Telemetry',
            isGhat: hub.isGhat,
          };
        })
      );
      setCorridorWeather(results);
      setLastUpdated(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
    } catch (e) {
      console.warn('Weather fetch warning:', e);
    } finally {
      setLoading(false);
    }
  }, [hubs]);

  React.useEffect(() => {
    fetchCorridorData();
    const interval = setInterval(fetchCorridorData, 90000); // 90s background poll
    return () => clearInterval(interval);
  }, [fetchCorridorData]);

  const getWeatherIcon = (cond: string, rainProb: number) => {
    const c = cond.toUpperCase();
    if (rainProb >= 50 || c.includes('RAIN') || c.includes('DRIZZLE') || c.includes('SHOWER')) {
      return <CloudRain className="w-4 h-4 text-cyan-400 animate-bounce" />;
    }
    if (c.includes('MIST') || c.includes('FOG') || c.includes('CLOUD')) {
      return <Cloud className="w-4 h-4 text-slate-300" />;
    }
    return <Sun className="w-4 h-4 text-amber-400" />;
  };

  const handleCardClick = (slug: string) => {
    const match = destinations.find(
      (d) => d.id.toLowerCase() === slug || d.slug.toLowerCase() === slug
    );
    if (match) {
      setSelectedDestination(match);
      navigateTo('MAP');
    } else {
      navigateTo('MAP');
    }
  };

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between px-1">
        <div className="flex items-center gap-1.5">
          <span className="flex h-2 w-2 relative">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" />
          </span>
          <h3 className="font-serif text-xs sm:text-sm font-bold text-[#144032] flex items-center gap-1">
            <span>Live Kerala Meteorological Telemetry</span>
          </h3>
        </div>

        <div className="flex items-center gap-2 text-[10px] text-gray-500">
          <span>Synced: {lastUpdated}</span>
          <button
            onClick={fetchCorridorData}
            title="Refresh live weather"
            className="p-1 hover:text-[#144032] transition-colors"
          >
            <RefreshCw className={`w-3 h-3 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Horizontal Scrollable Weather Cards */}
      <div className="flex items-center gap-2.5 overflow-x-auto scrollbar-none pb-1 pt-0.5">
        {corridorWeather.map((card) => {
          const isCaution = card.rainProb >= 50 || card.roadStatus.includes('ALERT');

          return (
            <div
              key={card.slug}
              onClick={() => handleCardClick(card.slug)}
              className="p-2.5 min-w-[155px] max-w-[170px] rounded-2xl bg-[#0F2823] text-[#F7F3E8] border border-[#D4AF37]/30 shadow-md hover:border-[#D4AF37] transition-all cursor-pointer group shrink-0 active:scale-95"
            >
              <div className="flex items-center justify-between mb-1">
                <span className="text-[10px] font-bold text-[#D4AF37] truncate uppercase tracking-wider">
                  {card.name.split(' ')[0]}
                </span>
                {getWeatherIcon(card.condition, card.rainProb)}
              </div>

              <div className="flex items-baseline gap-1.5 my-0.5">
                <span className="font-serif text-xl font-extrabold text-white">
                  {card.temp}°C
                </span>
                <span className="text-[10px] text-emerald-400 font-mono font-bold">
                  {card.rainProb}% Rain
                </span>
              </div>

              <p className="text-[9px] text-[#C5D8CD] truncate capitalize">
                {card.condition.toLowerCase()}
              </p>

              {/* Road / Travel advisory indicator */}
              <div className="mt-1.5 pt-1.5 border-t border-white/10 flex items-center gap-1 text-[9px]">
                {isCaution ? (
                  <span className="flex items-center gap-1 text-amber-300 font-semibold truncate">
                    <AlertTriangle className="w-2.5 h-2.5 shrink-0" />
                    <span>Ghat 30 km/h</span>
                  </span>
                ) : (
                  <span className="flex items-center gap-1 text-emerald-300 font-semibold truncate">
                    <ShieldCheck className="w-2.5 h-2.5 shrink-0" />
                    <span>Clear Corridor</span>
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
