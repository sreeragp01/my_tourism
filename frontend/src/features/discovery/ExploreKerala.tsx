import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { KERALA_DESTINATIONS, KERALA_EXPERIENCES, KERALA_ACCOMMODATIONS } from '../../data/keralaData';
import { MapPin, Star, Sparkles, Filter, Leaf, ArrowRight, ShieldCheck, Heart } from 'lucide-react';
import { Experience, Accommodation, Destination } from '../../types/contracts';

export const ExploreKerala: React.FC = () => {
  const { setSelectedExperience, setSelectedAccommodation, setSelectedDestination, navigateTo } = useAppStore();
  const [activeTab, setActiveTab] = React.useState<'DESTINATIONS' | 'EXPERIENCES' | 'STAYS'>('DESTINATIONS');
  const [selectedFilter, setSelectedFilter] = React.useState<string>('ALL');

  const filters = ['ALL', 'Nature', 'Culture', 'Food', 'Water', 'Adventure'];

  return (
    <div className="p-4 space-y-4 pb-12 text-[#1C231E]">
      {/* Top Header */}
      <div className="flex items-center justify-between pt-1">
        <div>
          <h2 className="font-serif text-2xl font-bold text-[#144032]">Explore Kerala</h2>
          <p className="text-xs text-[#6A8F71]">Curated destinations, native experiences & boutique stays</p>
        </div>
        <button
          onClick={() => navigateTo('MAP')}
          className="px-3 py-1.5 rounded-xl bg-[#144032] text-[#D4AF37] text-xs font-bold flex items-center gap-1 shadow-sm"
        >
          <MapPin className="w-3.5 h-3.5" />
          <span>Map View</span>
        </button>
      </div>

      {/* Main Tabs (Destinations, Experiences, Stays) */}
      <div className="flex rounded-2xl bg-[#E9DDC5]/70 p-1 border border-[#E2D3B8]">
        {(['DESTINATIONS', 'EXPERIENCES', 'STAYS'] as const).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === tab
                ? 'bg-[#144032] text-[#F7F3E8] shadow-md'
                : 'text-[#144032] hover:bg-white/50'
            }`}
          >
            {tab === 'DESTINATIONS' ? 'Destinations' : tab === 'EXPERIENCES' ? 'Experiences' : 'Stays'}
          </button>
        ))}
      </div>

      {/* Category Pills */}
      <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-none">
        {filters.map((f) => (
          <button
            key={f}
            onClick={() => setSelectedFilter(f)}
            className={`px-3 py-1 rounded-full text-xs font-semibold whitespace-nowrap transition-all ${
              selectedFilter === f
                ? 'bg-[#144032] text-[#D4AF37] border border-[#D4AF37]/30 shadow-sm'
                : 'bg-white text-gray-700 border border-[#E2D3B8] hover:border-[#144032]'
            }`}
          >
            {f}
          </button>
        ))}
      </div>

      {/* TAB 1: DESTINATIONS */}
      {activeTab === 'DESTINATIONS' && (
        <div className="space-y-4 animate-in fade-in">
          {KERALA_DESTINATIONS.map((dest) => (
            <div
              key={dest.id}
              onClick={() => setSelectedDestination(dest)}
              className="bg-white rounded-3xl overflow-hidden border border-[#E2D3B8] shadow-sm hover:shadow-md transition-all cursor-pointer group"
            >
              <div className="relative h-44 overflow-hidden">
                <img
                  src={dest.heroImage}
                  alt={dest.name}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-[#0F2823] via-[#0F2823]/20 to-transparent flex flex-col justify-end p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-[#D4AF37] text-[#0F2823] uppercase">
                        {dest.district} District
                      </span>
                      <h3 className="font-serif text-xl font-bold text-white mt-1">{dest.name}</h3>
                    </div>
                    <div className="px-2 py-1 rounded-xl bg-black/40 backdrop-blur-md border border-white/20 text-right">
                      <span className="text-[10px] text-emerald-300 font-mono font-bold block">Avg. Stay</span>
                      <span className="text-xs font-bold text-white">{dest.averageStayDays} Days</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="p-4 space-y-3">
                <p className="text-xs text-[#382F26] italic font-serif">"{dest.tagline}"</p>
                <p className="text-xs text-gray-600 line-clamp-2 leading-relaxed">{dest.description}</p>
                
                {/* Preference Meters */}
                <div className="pt-2 border-t border-gray-100 flex items-center justify-between text-[11px] text-gray-600">
                  <span className="flex items-center gap-1 font-semibold text-[#144032]">
                    <Leaf className="w-3.5 h-3.5 text-emerald-600" />
                    Nature: {Math.round(dest.preferences.nature * 100)}%
                  </span>
                  <span className="flex items-center gap-1 font-semibold text-[#C35B3A]">
                    <Heart className="w-3.5 h-3.5 text-rose-500" />
                    Romance: {Math.round(dest.preferences.romance * 100)}%
                  </span>
                  <span className="text-[#D4AF37] font-bold">Best: {dest.bestSeason.split(' ')[0]}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* TAB 2: EXPERIENCES */}
      {activeTab === 'EXPERIENCES' && (
        <div className="space-y-3 animate-in fade-in">
          {KERALA_EXPERIENCES.map((exp) => (
            <div
              key={exp.id}
              onClick={() => setSelectedExperience(exp)}
              className="p-3.5 rounded-3xl bg-white border border-[#E2D3B8] shadow-sm hover:border-[#D4AF37] transition-all cursor-pointer group flex flex-col gap-2.5"
            >
              <div className="flex gap-3">
                <img
                  src={exp.heroImage}
                  alt={exp.title}
                  className="w-24 h-24 rounded-2xl object-cover group-hover:scale-105 transition-transform"
                />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-bold text-[#6A8F71] uppercase tracking-wider">
                      {exp.category}
                    </span>
                    <div className="flex items-center gap-1 text-xs font-bold text-[#144032]">
                      <Star className="w-3.5 h-3.5 fill-[#D4AF37] text-[#D4AF37]" />
                      <span>{exp.rating}</span>
                      <span className="text-[10px] text-gray-400">({exp.reviewCount})</span>
                    </div>
                  </div>
                  <h4 className="font-bold text-xs text-[#144032] line-clamp-2 mt-0.5">{exp.title}</h4>
                  <p className="text-[11px] text-gray-500 mt-1">Host: {exp.hostName}</p>
                </div>
              </div>

              {/* Explainable AI Banner */}
              {exp.explanation && (
                <div className="px-3 py-1.5 rounded-xl bg-[#E7EFEA] border border-[#C5D8CD] flex items-center justify-between text-[10px]">
                  <span className="font-bold text-[#144032] flex items-center gap-1">
                    <Sparkles className="w-3 h-3 text-[#D4AF37]" />
                    AI Match: {exp.explanation.score}%
                  </span>
                  <span className="text-gray-600 italic truncate max-w-[190px]">
                    {exp.explanation.reasons[0]}
                  </span>
                </div>
              )}

              <div className="flex items-center justify-between pt-1">
                <div>
                  <span className="text-sm font-extrabold text-[#C35B3A]">
                    ₹{exp.pricePerPerson.toLocaleString('en-IN')}
                  </span>
                  <span className="text-[10px] text-gray-500"> / person</span>
                </div>
                <span className="text-xs font-bold text-[#144032] group-hover:text-[#C35B3A] transition-colors flex items-center gap-1">
                  View Experience <ArrowRight className="w-3.5 h-3.5" />
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* TAB 3: STAYS */}
      {activeTab === 'STAYS' && (
        <div className="space-y-4 animate-in fade-in">
          {KERALA_ACCOMMODATIONS.map((hotel) => (
            <div
              key={hotel.id}
              onClick={() => setSelectedAccommodation(hotel)}
              className="bg-white rounded-3xl overflow-hidden border border-[#E2D3B8] shadow-sm hover:shadow-md transition-all cursor-pointer group"
            >
              <div className="relative h-44 overflow-hidden">
                <img
                  src={hotel.heroImage}
                  alt={hotel.name}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700"
                />
                <div className="absolute top-3 left-3 px-2.5 py-1 rounded-full bg-[#0F2823]/80 backdrop-blur-md border border-[#D4AF37]/30 text-[10px] font-bold text-[#D4AF37] uppercase">
                  {hotel.type.replace('_', ' ')}
                </div>
                <div className="absolute top-3 right-3 px-2 py-1 rounded-full bg-emerald-700/80 backdrop-blur-md text-white text-[10px] font-bold flex items-center gap-1">
                  <Leaf className="w-3 h-3" />
                  Eco {hotel.ecoGreenScore}/100
                </div>
              </div>

              <div className="p-4 space-y-2">
                <div className="flex items-center justify-between">
                  <h3 className="font-serif text-base font-bold text-[#144032]">{hotel.name}</h3>
                  <div className="flex items-center gap-1 text-xs font-bold text-[#144032]">
                    <Star className="w-3.5 h-3.5 fill-[#D4AF37] text-[#D4AF37]" />
                    <span>{hotel.starRating}.0</span>
                  </div>
                </div>
                <p className="text-xs text-gray-500 italic">{hotel.tagline}</p>
                <div className="flex flex-wrap gap-1.5 pt-1">
                  {hotel.amenities.slice(0, 3).map((a) => (
                    <span key={a} className="px-2 py-0.5 rounded-lg bg-[#F7F3E8] text-[10px] text-[#144032] border border-[#E2D3B8]">
                      {a}
                    </span>
                  ))}
                </div>

                <div className="pt-2 border-t border-gray-100 flex items-center justify-between">
                  <div>
                    <span className="text-sm font-extrabold text-[#C35B3A]">
                      ₹{hotel.basePricePerNight.toLocaleString('en-IN')}
                    </span>
                    <span className="text-[10px] text-gray-500"> / night</span>
                  </div>
                  <button className="px-3 py-1.5 rounded-xl bg-[#144032] text-[#F7F3E8] text-xs font-bold hover:bg-[#1A5340]">
                    Select Rooms
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
