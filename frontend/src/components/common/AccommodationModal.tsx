import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { Star, Leaf, Sparkles, Check, ArrowRight, X, ShieldCheck } from 'lucide-react';

export const AccommodationModal: React.FC = () => {
  const { selectedAccommodation, setSelectedAccommodation, navigateTo, showToast } = useAppStore();

  if (!selectedAccommodation) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="w-full max-w-md bg-[#F7F3E8] rounded-t-3xl sm:rounded-3xl max-h-[90vh] overflow-y-auto border border-[#D4AF37]/40 shadow-2xl animate-in slide-in-from-bottom-6">
        {/* Hero Image & Close */}
        <div className="relative h-56">
          <img
            src={selectedAccommodation.heroImage}
            alt={selectedAccommodation.name}
            className="w-full h-full object-cover"
          />
          <button
            onClick={() => setSelectedAccommodation(null)}
            className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/60 text-white flex items-center justify-center hover:bg-black transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
          <div className="absolute top-4 left-4 px-2.5 py-1 rounded-full bg-[#144032] text-[#D4AF37] text-[10px] font-bold uppercase tracking-wider">
            {selectedAccommodation.type.replace('_', ' ')}
          </div>
        </div>

        {/* Content */}
        <div className="p-5 space-y-4">
          <div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-1 text-xs font-bold text-[#144032]">
                <Star className="w-4 h-4 fill-[#D4AF37] text-[#D4AF37]" />
                <span>{selectedAccommodation.starRating}.0 Star Eco-Luxury</span>
              </div>
              <div className="flex items-center gap-1 text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                <Leaf className="w-3.5 h-3.5" />
                <span>Eco Score: {selectedAccommodation.ecoGreenScore}/100</span>
              </div>
            </div>
            <h3 className="font-serif text-xl font-bold text-[#144032] mt-1">
              {selectedAccommodation.name}
            </h3>
            <p className="text-xs text-gray-500 italic mt-0.5">{selectedAccommodation.tagline}</p>
          </div>

          {/* Explainable AI Score */}
          {selectedAccommodation.explanation && (
            <div className="p-3 rounded-2xl bg-[#E7EFEA] border border-[#C5D8CD] space-y-1.5">
              <div className="flex items-center justify-between text-xs font-bold text-[#144032]">
                <span className="flex items-center gap-1.5">
                  <Sparkles className="w-3.5 h-3.5 text-[#D4AF37]" />
                  AI Suitability Match: {selectedAccommodation.explanation.score}%
                </span>
                <span className="text-[10px] text-emerald-700 uppercase">Top Resort</span>
              </div>
              <ul className="text-[11px] text-gray-600 space-y-1 pl-4 list-disc">
                {selectedAccommodation.explanation.reasons.map((r, i) => (
                  <li key={i}>{r}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Description */}
          <p className="text-xs text-gray-700 leading-relaxed">
            {selectedAccommodation.description}
          </p>

          {/* Amenities Chips */}
          <div>
            <h4 className="font-serif text-xs font-bold text-[#144032] mb-1.5">Featured Amenities</h4>
            <div className="flex flex-wrap gap-1.5">
              {selectedAccommodation.amenities.map((amenity, i) => (
                <span key={i} className="px-2.5 py-1 rounded-xl bg-white border border-[#E2D3B8] text-[11px] font-medium text-[#144032]">
                  {amenity}
                </span>
              ))}
            </div>
          </div>

          {/* Available Room Types */}
          <div>
            <h4 className="font-serif text-xs font-bold text-[#144032] mb-2">Room Categories</h4>
            <div className="space-y-2">
              {selectedAccommodation.roomTypes.map((room) => (
                <div key={room.id} className="p-3 rounded-2xl bg-white border border-[#E2D3B8] flex items-center justify-between">
                  <div>
                    <p className="text-xs font-bold text-[#144032]">{room.name}</p>
                    <p className="text-[10px] text-gray-500">{room.features.join(' · ')}</p>
                  </div>
                  <div className="text-right">
                    <span className="text-xs font-bold text-[#C35B3A] block">
                      ₹{room.pricePerNight.toLocaleString('en-IN')}
                    </span>
                    <span className="text-[9px] text-gray-400">/ night</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Bottom Booking Action */}
          <div className="pt-2 border-t border-gray-200 flex items-center justify-between">
            <div>
              <p className="text-[10px] text-gray-400 uppercase font-bold">Starting from</p>
              <p className="font-serif text-lg font-extrabold text-[#C35B3A]">
                ₹{selectedAccommodation.basePricePerNight.toLocaleString('en-IN')}{' '}
                <span className="text-xs font-normal text-gray-500 font-sans">/ night</span>
              </p>
            </div>
            <button
              onClick={() => {
                setSelectedAccommodation(null);
                navigateTo('AI_PLANNER');
                showToast(`Selected "${selectedAccommodation.name}" for your AI journey!`);
              }}
              className="px-5 py-2.5 rounded-2xl bg-[#144032] text-[#F7F3E8] text-xs font-bold shadow-md hover:bg-[#10352A] transition-all flex items-center gap-1.5"
            >
              <span>Add to AI Trip</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
