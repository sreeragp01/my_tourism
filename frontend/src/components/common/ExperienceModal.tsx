import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { Star, Clock, Users, ShieldCheck, MapPin, Sparkles, Check, ArrowRight, X, Umbrella } from 'lucide-react';

export const ExperienceModal: React.FC = () => {
  const { selectedExperience, setSelectedExperience, navigateTo, showToast } = useAppStore();

  if (!selectedExperience) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="w-full max-w-md bg-[#F7F3E8] rounded-t-3xl sm:rounded-3xl max-h-[90vh] overflow-y-auto border border-[#D4AF37]/40 shadow-2xl animate-in slide-in-from-bottom-6">
        {/* Hero Image & Close */}
        <div className="relative h-56">
          <img
            src={selectedExperience.heroImage}
            alt={selectedExperience.title}
            className="w-full h-full object-cover"
          />
          <button
            onClick={() => setSelectedExperience(null)}
            className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/60 text-white flex items-center justify-center hover:bg-black transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
          <div className="absolute top-4 left-4 px-2.5 py-1 rounded-full bg-[#144032] text-[#D4AF37] text-[10px] font-bold uppercase tracking-wider">
            {selectedExperience.category}
          </div>
        </div>

        {/* Content */}
        <div className="p-5 space-y-4">
          <div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-[#6A8F71] capitalize">
                {selectedExperience.destinationId} District
              </span>
              <div className="flex items-center gap-1 text-xs font-bold text-[#144032]">
                <Star className="w-4 h-4 fill-[#D4AF37] text-[#D4AF37]" />
                <span>{selectedExperience.rating}</span>
                <span className="text-gray-400">({selectedExperience.reviewCount} reviews)</span>
              </div>
            </div>
            <h3 className="font-serif text-xl font-bold text-[#144032] mt-1">
              {selectedExperience.title}
            </h3>
          </div>

          {/* Explainable AI Score */}
          {selectedExperience.explanation && (
            <div className="p-3 rounded-2xl bg-[#E7EFEA] border border-[#C5D8CD] space-y-1.5">
              <div className="flex items-center justify-between text-xs font-bold text-[#144032]">
                <span className="flex items-center gap-1.5">
                  <Sparkles className="w-3.5 h-3.5 text-[#D4AF37]" />
                  AI Suitability Match: {selectedExperience.explanation.score}%
                </span>
                <span className="text-[10px] text-emerald-700 uppercase">Top Choice</span>
              </div>
              <ul className="text-[11px] text-gray-600 space-y-1 pl-4 list-disc">
                {selectedExperience.explanation.reasons.map((r, i) => (
                  <li key={i}>{r}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Quick Info Grid */}
          <div className="grid grid-cols-2 gap-2 text-xs">
            <div className="p-2.5 rounded-xl bg-white border border-[#E2D3B8] flex items-center gap-2">
              <Clock className="w-4 h-4 text-[#144032]" />
              <span>{selectedExperience.durationHours} Hours Duration</span>
            </div>
            <div className="p-2.5 rounded-xl bg-white border border-[#E2D3B8] flex items-center gap-2">
              <Users className="w-4 h-4 text-[#144032]" />
              <span>Max {selectedExperience.maxGroupSize} People</span>
            </div>
          </div>

          {/* Description */}
          <p className="text-xs text-gray-700 leading-relaxed">
            {selectedExperience.description}
          </p>

          {/* What's Included */}
          <div>
            <h4 className="font-serif text-xs font-bold text-[#144032] mb-1.5">What’s Included</h4>
            <div className="space-y-1">
              {selectedExperience.includedItems.map((item, i) => (
                <div key={i} className="flex items-center gap-2 text-xs text-gray-600">
                  <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                  <span>{item}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Host Profile */}
          <div className="p-3 rounded-2xl bg-[#FAF5EA] border border-[#E2D3B8] flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-[#144032] text-[#D4AF37] font-serif font-bold text-base flex items-center justify-center">
              {selectedExperience.hostName.charAt(0)}
            </div>
            <div>
              <p className="text-xs font-bold text-[#144032]">{selectedExperience.hostName}</p>
              <p className="text-[10px] text-gray-500">{selectedExperience.hostRole}</p>
            </div>
          </div>

          {/* Bottom Booking Action */}
          <div className="pt-2 border-t border-gray-200 flex items-center justify-between">
            <div>
              <p className="text-[10px] text-gray-400 uppercase font-bold">Price</p>
              <p className="font-serif text-lg font-extrabold text-[#C35B3A]">
                ₹{selectedExperience.pricePerPerson.toLocaleString('en-IN')}{' '}
                <span className="text-xs font-normal text-gray-500 font-sans">/ person</span>
              </p>
            </div>
            <button
              onClick={() => {
                setSelectedExperience(null);
                navigateTo('AI_PLANNER');
                showToast(`Added "${selectedExperience.title}" to trip preferences!`);
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
