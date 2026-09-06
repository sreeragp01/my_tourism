import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { Search, Sparkles, Bell, ArrowRight, Star, Heart, MapPin } from 'lucide-react';
import { KERALA_EXPERIENCES, KERALA_DESTINATIONS } from '../../data/keralaData';

export const HomeDiscover: React.FC = () => {
  const { navigateTo, currentUser, setSelectedExperience, setSelectedDestination } = useAppStore();
  const [searchQuery, setSearchQuery] = React.useState('');

  const categories = [
    { id: 'Nature', label: 'Nature', icon: '🌿' },
    { id: 'Beaches', label: 'Beaches', icon: '🌴' },
    { id: 'Hills', label: 'Hills', icon: '⛰️' },
    { id: 'Backwaters', label: 'Backwaters', icon: '🛶' },
    { id: 'Culture', label: 'Culture', icon: '🪔' },
    { id: 'Food', label: 'Food', icon: '🍛' },
    { id: 'Adventure', label: 'Adventure', icon: '🧗' },
    { id: 'Wildlife', label: 'Wildlife', icon: '🐘' },
  ];

  return (
    <div className="p-4 space-y-5 pb-8 text-[#1C231E]">
      {/* User Greeting & Header */}
      <div className="flex items-center justify-between pt-1">
        <div>
          <p className="text-xs text-[#6A8F71] font-medium tracking-wide">Good morning,</p>
          <h2 className="font-serif text-2xl font-bold text-[#144032] flex items-center gap-1.5">
            <span>{currentUser?.firstName || 'Sreerag'}</span>
            <span className="text-lg">🌴</span>
          </h2>
        </div>
        <div className="relative">
          <button
            onClick={() => navigateTo('COMPANION')}
            className="w-10 h-10 rounded-full bg-white border border-[#E2D3B8] shadow-sm flex items-center justify-center text-[#144032] hover:border-[#D4AF37] transition-all"
          >
            <Bell className="w-4 h-4" />
          </button>
          <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#C35B3A] ring-2 ring-white" />
        </div>
      </div>

      {/* Smart Search Bar */}
      <div className="relative">
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search destinations, experiences..."
          className="w-full pl-10 pr-4 py-3 rounded-2xl bg-white border border-[#E2D3B8] text-xs focus:outline-none focus:ring-2 focus:ring-[#144032] shadow-sm placeholder:text-gray-400"
        />
        <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-3.5" />
      </div>

      {/* Flagship Feature Banner: "Plan Your Perfect Trip" */}
      <div className="relative rounded-3xl overflow-hidden bg-gradient-to-br from-[#144032] to-[#0A1D19] p-5 text-[#F7F3E8] shadow-xl border border-[#D4AF37]/30">
        <div className="relative z-10 max-w-[240px]">
          <span className="inline-block px-2 py-0.5 rounded-full bg-[#D4AF37]/20 text-[#D4AF37] text-[10px] font-bold uppercase tracking-wider mb-1.5">
            AI Travel Architect
          </span>
          <h3 className="font-serif text-xl font-bold leading-tight">
            Plan your <br />
            <span className="italic text-[#D4AF37]">perfect trip</span>
          </h3>
          <p className="text-[11px] text-[#C5D8CD] mt-1 leading-relaxed">
            Let AI design a realistic, weather-aware trip just for you.
          </p>
          <button
            onClick={() => navigateTo('AI_PLANNER')}
            className="mt-3.5 px-4 py-2 rounded-xl bg-gradient-to-r from-[#D4AF37] to-[#E5C65C] text-[#0F2823] font-bold text-xs shadow-gold hover:opacity-95 transition-all flex items-center gap-1.5 transform active:scale-95"
          >
            <span>Plan with AI</span>
            <Sparkles className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Decorative Background Graphic */}
        <div className="absolute right-[-15px] bottom-[-10px] opacity-30 text-8xl pointer-events-none select-none">
          🪷
        </div>
      </div>

      {/* Popular Categories */}
      <div>
        <div className="flex items-center justify-between mb-3 px-1">
          <h3 className="font-serif text-base font-bold text-[#144032]">Popular Categories</h3>
          <button
            onClick={() => navigateTo('EXPLORE')}
            className="text-xs font-semibold text-[#C35B3A] hover:underline"
          >
            View all
          </button>
        </div>

        <div className="grid grid-cols-4 gap-2.5">
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => navigateTo('EXPLORE')}
              className="p-3 rounded-2xl bg-white border border-[#E2D3B8]/80 shadow-sm hover:border-[#D4AF37] transition-all flex flex-col items-center gap-1.5 group active:scale-95"
            >
              <span className="text-2xl group-hover:scale-110 transition-transform">{cat.icon}</span>
              <span className="text-[10px] font-bold text-[#144032]">{cat.label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Top Destinations Spotlight */}
      <div>
        <div className="flex items-center justify-between mb-3 px-1">
          <h3 className="font-serif text-base font-bold text-[#144032]">Top Destinations</h3>
          <button
            onClick={() => navigateTo('EXPLORE')}
            className="text-xs font-semibold text-[#C35B3A] hover:underline"
          >
            View all
          </button>
        </div>

        <div className="grid grid-cols-2 gap-3">
          {KERALA_DESTINATIONS.slice(0, 4).map((dest) => (
            <div
              key={dest.id}
              onClick={() => {
                setSelectedDestination(dest);
                navigateTo('EXPLORE');
              }}
              className="group relative rounded-2xl overflow-hidden shadow-md cursor-pointer border border-[#E2D3B8] h-32"
            >
              <img
                src={dest.heroImage}
                alt={dest.name}
                className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#0F2823] via-[#0F2823]/30 to-transparent flex flex-col justify-end p-2.5">
                <p className="text-xs font-bold text-white font-serif">{dest.name}</p>
                <p className="text-[10px] text-[#C5D8CD]">{dest.tags.slice(0, 2).join(' · ')}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Trending Experiences */}
      <div>
        <div className="flex items-center justify-between mb-3 px-1">
          <h3 className="font-serif text-base font-bold text-[#144032]">Trending Experiences</h3>
          <button
            onClick={() => navigateTo('EXPLORE')}
            className="text-xs font-semibold text-[#C35B3A] hover:underline"
          >
            View all
          </button>
        </div>

        <div className="space-y-3">
          {KERALA_EXPERIENCES.map((exp) => (
            <div
              key={exp.id}
              onClick={() => setSelectedExperience(exp)}
              className="p-3 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm hover:border-[#D4AF37] transition-all flex items-center gap-3 cursor-pointer group"
            >
              <img
                src={exp.heroImage}
                alt={exp.title}
                className="w-20 h-20 rounded-xl object-cover group-hover:scale-105 transition-transform"
              />
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-bold text-[#6A8F71] uppercase tracking-wide">
                    {exp.category}
                  </span>
                  <div className="flex items-center gap-1 text-[11px] font-bold text-[#144032]">
                    <Star className="w-3.5 h-3.5 fill-[#D4AF37] text-[#D4AF37]" />
                    <span>{exp.rating}</span>
                  </div>
                </div>
                <h4 className="text-xs font-bold text-[#144032] line-clamp-1 mt-0.5">{exp.title}</h4>
                <p className="text-[10px] text-gray-500 flex items-center gap-1 mt-0.5">
                  <MapPin className="w-3 h-3 text-gray-400" />
                  <span className="capitalize">{exp.destinationId}</span>
                  <span>·</span>
                  <span>{exp.durationHours} hrs</span>
                </p>
                <p className="text-xs font-bold text-[#C35B3A] mt-1">
                  ₹{exp.pricePerPerson.toLocaleString('en-IN')}{' '}
                  <span className="text-[10px] font-normal text-gray-500">/ person</span>
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
