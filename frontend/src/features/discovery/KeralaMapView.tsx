import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { KERALA_DESTINATIONS } from '../../data/keralaData';
import { MapPin, Navigation, Sparkles, Star, ArrowRight, Layers, Compass } from 'lucide-react';
import { Destination } from '../../types/contracts';

export const KeralaMapView: React.FC = () => {
  const { navigateTo, setSelectedDestination } = useAppStore();
  const [activePin, setActivePin] = React.useState<Destination>(KERALA_DESTINATIONS[0]);
  const [selectedLayer, setSelectedLayer] = React.useState<'ALL' | 'HILLS' | 'BACKWATERS' | 'BEACHES'>('ALL');

  // Relative normalized percentage coordinates for visual Kerala vertical spine
  const pinPositions: Record<string, { top: string; left: string }> = {
    wayanad: { top: '20%', left: '42%' },
    kochi: { top: '48%', left: '38%' },
    munnar: { top: '46%', left: '72%' },
    thekkady: { top: '58%', left: '76%' },
    alleppey: { top: '62%', left: '36%' },
    varkala: { top: '78%', left: '45%' },
  };

  return (
    <div className="relative h-full flex flex-col bg-[#0A1D19] text-[#F7F3E8] overflow-hidden">
      {/* Top Map Filter Header */}
      <div className="p-4 bg-[#0F2823]/90 backdrop-blur-md border-b border-[#D4AF37]/20 z-20">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-2">
            <Compass className="w-5 h-5 text-[#D4AF37]" />
            <h2 className="font-serif text-lg font-bold">Kerala Tourism Map</h2>
          </div>
          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#144032] text-emerald-400 border border-emerald-500/30">
            6 Corridor Hubs
          </span>
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto scrollbar-none">
          {(['ALL', 'HILLS', 'BACKWATERS', 'BEACHES'] as const).map((layer) => (
            <button
              key={layer}
              onClick={() => setSelectedLayer(layer)}
              className={`px-3 py-1 rounded-full text-[10px] font-bold tracking-wider transition-all uppercase ${
                selectedLayer === layer
                  ? 'bg-[#D4AF37] text-[#0F2823] shadow-gold'
                  : 'bg-[#144032] text-[#C5D8CD] hover:text-white'
              }`}
            >
              {layer}
            </button>
          ))}
        </div>
      </div>

      {/* Interactive Map Canvas / SVG Representation */}
      <div className="flex-1 relative bg-gradient-to-b from-[#0F2823] via-[#144032] to-[#0A1D19] flex items-center justify-center p-4">
        {/* Kerala Coastline & Terrain Contour Graphic */}
        <div className="relative w-full max-w-[340px] h-[480px] bg-[#10352A]/60 rounded-3xl border border-[#D4AF37]/20 shadow-2xl p-4 overflow-hidden">
          {/* Arabian Sea Blue Hue on Left */}
          <div className="absolute inset-y-0 left-0 w-16 bg-gradient-to-r from-teal-900/30 to-transparent pointer-events-none" />
          <span className="absolute top-1/2 left-2 -rotate-90 text-[10px] font-serif text-[#C5D8CD]/30 uppercase tracking-widest pointer-events-none">
            Arabian Sea
          </span>

          {/* Western Ghats Mountain Hue on Right */}
          <div className="absolute inset-y-0 right-0 w-24 bg-gradient-to-l from-emerald-950/60 to-transparent pointer-events-none" />
          <span className="absolute top-1/3 right-2 rotate-90 text-[10px] font-serif text-[#D4AF37]/30 uppercase tracking-widest pointer-events-none">
            Western Ghats (1,600m)
          </span>

          {/* Golden Connecting Scenic Corridor Trail */}
          <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-40">
            <path
              d="M 140 100 Q 130 230 130 235 T 240 220 T 255 280 T 120 300 T 150 375"
              fill="none"
              stroke="#D4AF37"
              strokeWidth="2.5"
              strokeDasharray="6 4"
            />
          </svg>

          {/* Destination Markers */}
          {KERALA_DESTINATIONS.map((dest) => {
            const pos = pinPositions[dest.id] || { top: '50%', left: '50%' };
            const isSelected = activePin.id === dest.id;

            return (
              <div
                key={dest.id}
                onClick={() => setActivePin(dest)}
                style={{ top: pos.top, left: pos.left }}
                className="absolute -translate-x-1/2 -translate-y-1/2 cursor-pointer z-10 group"
              >
                {/* Pulsing ring */}
                <div
                  className={`w-9 h-9 rounded-full flex items-center justify-center transition-all ${
                    isSelected
                      ? 'bg-[#D4AF37] text-[#0F2823] scale-125 shadow-gold ring-4 ring-[#D4AF37]/40'
                      : 'bg-[#144032] text-[#D4AF37] border border-[#D4AF37]/60 group-hover:scale-110 shadow-lg'
                  }`}
                >
                  <MapPin className="w-4 h-4" />
                </div>
                {/* Pin Title Label */}
                <span
                  className={`absolute top-10 left-1/2 -translate-x-1/2 whitespace-nowrap px-2 py-0.5 rounded text-[10px] font-bold shadow-md transition-all ${
                    isSelected
                      ? 'bg-[#D4AF37] text-[#0F2823]'
                      : 'bg-[#0F2823]/90 text-[#F7F3E8] border border-white/10'
                  }`}
                >
                  {dest.name.split(' ')[0]}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Bottom Selected Pin Detail Drawer */}
      <div className="p-4 bg-[#0F2823] border-t border-[#D4AF37]/30 z-20 animate-in slide-in-from-bottom-4">
        <div className="flex gap-3">
          <img
            src={activePin.heroImage}
            alt={activePin.name}
            className="w-20 h-20 rounded-2xl object-cover border border-[#D4AF37]/30 shadow-md"
          />
          <div className="flex-1 min-w-0">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-bold text-[#D4AF37] uppercase">
                {activePin.district} District
              </span>
              <span className="text-[10px] text-emerald-300 font-mono font-bold">
                {activePin.averageStayDays} Days Ideal
              </span>
            </div>
            <h3 className="font-serif text-base font-bold text-white mt-0.5 truncate">{activePin.name}</h3>
            <p className="text-[11px] text-[#C5D8CD] line-clamp-1 italic font-serif">"{activePin.tagline}"</p>
            <div className="flex items-center gap-2 mt-2">
              <button
                onClick={() => {
                  setSelectedDestination(activePin);
                  navigateTo('EXPLORE');
                }}
                className="px-3 py-1.5 rounded-xl bg-[#D4AF37] text-[#0F2823] text-xs font-bold shadow-gold flex items-center gap-1 hover:opacity-95"
              >
                <span>Explore {activePin.name.split(' ')[0]}</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={() => navigateTo('AI_PLANNER')}
                className="px-3 py-1.5 rounded-xl bg-[#144032] text-[#F7F3E8] text-xs font-semibold border border-white/10 hover:border-[#D4AF37]"
              >
                Plan Trip Here
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
