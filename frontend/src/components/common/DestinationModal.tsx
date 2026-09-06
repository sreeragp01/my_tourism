import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { MapPin, Leaf, Heart, Compass, Sparkles, ArrowRight, X } from 'lucide-react';

export const DestinationModal: React.FC = () => {
  const { selectedDestination, setSelectedDestination, navigateTo } = useAppStore();

  if (!selectedDestination) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="w-full max-w-md bg-[#F7F3E8] rounded-t-3xl sm:rounded-3xl max-h-[90vh] overflow-y-auto border border-[#D4AF37]/40 shadow-2xl animate-in slide-in-from-bottom-6">
        {/* Hero Image & Close */}
        <div className="relative h-60">
          <img
            src={selectedDestination.heroImage}
            alt={selectedDestination.name}
            className="w-full h-full object-cover"
          />
          <button
            onClick={() => setSelectedDestination(null)}
            className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/60 text-white flex items-center justify-center hover:bg-black transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
          <div className="absolute top-4 left-4 px-2.5 py-1 rounded-full bg-[#144032] text-[#D4AF37] text-[10px] font-bold uppercase tracking-wider">
            {selectedDestination.district} District
          </div>
        </div>

        {/* Content */}
        <div className="p-5 space-y-4">
          <div>
            <h3 className="font-serif text-2xl font-bold text-[#144032]">
              {selectedDestination.name}
            </h3>
            <p className="text-xs text-gray-500 italic font-serif mt-0.5">
              "{selectedDestination.tagline}"
            </p>
          </div>

          {/* Description */}
          <p className="text-xs text-gray-700 leading-relaxed">
            {selectedDestination.description}
          </p>

          {/* Preference Metrics Bar */}
          <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] space-y-2">
            <h4 className="font-serif text-xs font-bold text-[#144032]">Vibe & Affinity Profile</h4>
            <div className="space-y-1.5 text-xs">
              <div>
                <div className="flex justify-between text-[10px] font-semibold text-gray-600 mb-0.5">
                  <span className="flex items-center gap-1 text-[#144032]">
                    <Leaf className="w-3 h-3 text-emerald-600" /> Nature & Greenery
                  </span>
                  <span>{Math.round(selectedDestination.preferences.nature * 100)}%</span>
                </div>
                <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-emerald-600 rounded-full"
                    style={{ width: `${selectedDestination.preferences.nature * 100}%` }}
                  />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-[10px] font-semibold text-gray-600 mb-0.5">
                  <span className="flex items-center gap-1 text-[#C35B3A]">
                    <Heart className="w-3 h-3 text-rose-500" /> Romance & Serenity
                  </span>
                  <span>{Math.round(selectedDestination.preferences.romance * 100)}%</span>
                </div>
                <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-[#C35B3A] rounded-full"
                    style={{ width: `${selectedDestination.preferences.romance * 100}%` }}
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Highlights & Best Season */}
          <div className="grid grid-cols-2 gap-2 text-xs">
            <div className="p-2.5 rounded-xl bg-white border border-[#E2D3B8]">
              <p className="text-[10px] text-gray-400 font-bold uppercase">Best Season</p>
              <p className="font-bold text-[#144032] mt-0.5">{selectedDestination.bestSeason}</p>
            </div>
            <div className="p-2.5 rounded-xl bg-white border border-[#E2D3B8]">
              <p className="text-[10px] text-gray-400 font-bold uppercase">Average Stay</p>
              <p className="font-bold text-[#144032] mt-0.5">{selectedDestination.averageStayDays} Days Ideal</p>
            </div>
          </div>

          {/* Action CTA */}
          <div className="pt-2 border-t border-gray-200">
            <button
              onClick={() => {
                setSelectedDestination(null);
                navigateTo('AI_PLANNER');
              }}
              className="w-full py-3 rounded-2xl bg-[#144032] text-[#F7F3E8] text-xs font-bold shadow-md hover:bg-[#10352A] transition-all flex items-center justify-center gap-2"
            >
              <Sparkles className="w-4 h-4 text-[#D4AF37]" />
              <span>Plan AI Journey in {selectedDestination.name.split(' ')[0]}</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
