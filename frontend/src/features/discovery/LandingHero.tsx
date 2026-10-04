import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { Sparkles, Compass, ShieldCheck, Hotel, ArrowRight, Waves } from 'lucide-react';

export const LandingHero: React.FC = () => {
  const { navigateTo } = useAppStore();

  return (
    <div className="relative min-h-full bg-gradient-to-b from-[#0F2823] via-[#144032] to-[#0A1D19] text-[#F7F3E8] p-6 flex flex-col justify-between overflow-hidden">
      {/* Ambient Glows & Watermarked Kerala Botanical Motifs */}
      <div className="absolute -top-24 -right-24 w-80 h-80 bg-[#D4AF37]/15 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute top-1/2 -left-20 w-60 h-60 bg-emerald-600/10 rounded-full blur-2xl pointer-events-none" />

      {/* Top Brand Emblem & Header */}
      <div className="pt-4 text-center relative z-10">
        <div className="w-16 h-16 mx-auto mb-3 rounded-2xl bg-gradient-to-tr from-[#1A5340] to-[#144032] border border-[#D4AF37]/40 flex items-center justify-center shadow-gold animate-float">
          <span className="text-3xl">🪷</span>
        </div>
        <h1 className="font-serif text-4xl font-extrabold tracking-tight text-[#F7F3E8] drop-shadow-md">
          KeraLink
        </h1>
        <p className="font-serif italic text-lg text-[#D4AF37] mt-1 font-medium">
          Your Kerala. Your Way.
        </p>
        <div className="inline-block px-3 py-1 rounded-full bg-[#D4AF37]/15 border border-[#D4AF37]/30 text-[11px] font-semibold text-[#D4AF37] uppercase tracking-wider mt-2">
          AI-Powered Experiential Travel
        </div>
      </div>

      {/* Center Cinematic Card & Narrative */}
      <div className="my-6 relative z-10">
        <div className="relative rounded-3xl overflow-hidden border border-[#D4AF37]/30 shadow-2xl group">
          <img
            src="https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80"
            alt="Kerala Backwaters Houseboat"
            className="w-full h-48 object-cover group-hover:scale-105 transition-transform duration-700"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-[#0F2823] via-[#0F2823]/40 to-transparent flex flex-col justify-end p-4">
            <p className="text-xs text-[#C5D8CD] font-medium leading-relaxed drop-shadow">
              Discover authentic experiences, personalized itineraries and boutique stays across God’s Own Country.
            </p>
          </div>
        </div>

        {/* Primary CTA Buttons */}
        <div className="mt-5 space-y-2.5">
          <button
            onClick={() => navigateTo('AI_PLANNER')}
            className="w-full py-3.5 px-6 rounded-2xl bg-gradient-to-r from-[#D4AF37] to-[#E5C65C] text-[#0F2823] font-bold text-sm tracking-wide shadow-gold hover:opacity-95 transition-all flex items-center justify-center gap-2 transform active:scale-95"
          >
            <Sparkles className="w-4 h-4 text-[#0F2823]" />
            <span>Create My Journey</span>
            <ArrowRight className="w-4 h-4" />
          </button>

          <button
            onClick={() => navigateTo('EXPLORE')}
            className="w-full py-3 px-6 rounded-2xl bg-[#144032]/80 hover:bg-[#1A5340] border border-[#D4AF37]/30 text-[#F7F3E8] font-semibold text-sm transition-all flex items-center justify-center gap-2"
          >
            <Compass className="w-4 h-4 text-[#D4AF37]" />
            <span>Explore Kerala</span>
          </button>

          <button
            onClick={() => navigateTo('ONBOARDING')}
            className="w-full py-2 text-center text-xs text-[#C5D8CD] hover:text-[#D4AF37] transition-colors"
          >
            View Guided Story Tour →
          </button>
        </div>
      </div>

      {/* Feature Pillar Badges */}
      <div className="grid grid-cols-2 gap-2 relative z-10 pt-2 border-t border-white/10">
        <div
          onClick={() => navigateTo('AI_PLANNER')}
          className="p-2.5 rounded-xl bg-[#144032]/70 border border-white/10 flex items-center gap-2 cursor-pointer hover:border-[#D4AF37]/40 transition-all"
        >
          <div className="p-1.5 rounded-lg bg-[#D4AF37]/20 text-[#D4AF37]">
            <Sparkles className="w-3.5 h-3.5" />
          </div>
          <div>
            <p className="text-[11px] font-bold text-[#F7F3E8]">AI Trip Planner</p>
            <p className="text-[9px] text-[#C5D8CD]">Personalized routes</p>
          </div>
        </div>

        <div
          onClick={() => navigateTo('EXPLORE')}
          className="p-2.5 rounded-xl bg-[#144032]/70 border border-white/10 flex items-center gap-2 cursor-pointer hover:border-[#D4AF37]/40 transition-all"
        >
          <div className="p-1.5 rounded-lg bg-emerald-500/20 text-emerald-400">
            <Waves className="w-3.5 h-3.5" />
          </div>
          <div>
            <p className="text-[11px] font-bold text-[#F7F3E8]">Local Experiences</p>
            <p className="text-[9px] text-[#C5D8CD]">Native hosts</p>
          </div>
        </div>

        <div
          onClick={() => navigateTo('EXPLORE')}
          className="p-2.5 rounded-xl bg-[#144032]/70 border border-white/10 flex items-center gap-2 cursor-pointer hover:border-[#D4AF37]/40 transition-all"
        >
          <div className="p-1.5 rounded-lg bg-amber-500/20 text-amber-300">
            <Hotel className="w-3.5 h-3.5" />
          </div>
          <div>
            <p className="text-[11px] font-bold text-[#F7F3E8]">Premium Stays</p>
            <p className="text-[9px] text-[#C5D8CD]">Eco-villas & boats</p>
          </div>
        </div>

        <div
          onClick={() => navigateTo('SAFETY')}
          className="p-2.5 rounded-xl bg-[#144032]/70 border border-white/10 flex items-center gap-2 cursor-pointer hover:border-[#D4AF37]/40 transition-all"
        >
          <div className="p-1.5 rounded-lg bg-rose-500/20 text-rose-300">
            <ShieldCheck className="w-3.5 h-3.5" />
          </div>
          <div>
            <p className="text-[11px] font-bold text-[#F7F3E8]">Trusted & Safe</p>
            <p className="text-[9px] text-[#C5D8CD]">Tourist police 24/7</p>
          </div>
        </div>
      </div>
    </div>
  );
};
