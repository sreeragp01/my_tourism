import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { Sparkles, Calendar, MapPin, Users, Heart, ArrowRight, ArrowLeft, Send, Check } from 'lucide-react';
import { httpAdapter } from '../../adapters/httpAdapter';
import { TripProfile } from '../../types/contracts';

export const AIPlannerFlow: React.FC = () => {
  const { generateTrip, setTripProfile } = useAppStore();

  const [mode, setMode] = React.useState<'PROMPT' | 'WIZARD'>('PROMPT');
  const [promptText, setPromptText] = React.useState('6 days with wife in June, peaceful nature and backwaters, good food, no long drives, budget 80k');
  const [step, setStep] = React.useState(1);

  // Wizard Form State
  const [startDate, setStartDate] = React.useState('2026-06-20');
  const [endDate, setEndDate] = React.useState('2026-06-25');
  const [startingLocation, setStartingLocation] = React.useState('Kochi (COK)');
  const [adults, setAdults] = React.useState(2);
  const [children, setChildren] = React.useState(0);
  const [infants, setInfants] = React.useState(0);
  const [selectedInterests, setSelectedInterests] = React.useState<string[]>(['Nature', 'Beaches', 'Food', 'Backwaters']);
  const [budget, setBudget] = React.useState(80000);
  const [travelStyle, setTravelStyle] = React.useState<'RELAXED' | 'BALANCED' | 'PACKED'>('RELAXED');

  const interestsList = [
    { id: 'Nature', label: 'Nature', icon: '🌿' },
    { id: 'Beaches', label: 'Beaches', icon: '🏖️' },
    { id: 'Food', label: 'Food', icon: '🍛' },
    { id: 'Culture', label: 'Culture', icon: '🪔' },
    { id: 'Adventure', label: 'Adventure', icon: '🧗' },
    { id: 'Wildlife', label: 'Wildlife', icon: '🐘' },
    { id: 'Photography', label: 'Photography', icon: '📷' },
    { id: 'Wellness', label: 'Wellness', icon: '🧘' },
    { id: 'Shopping', label: 'Shopping', icon: '🛍️' },
  ];

  const quickPrompts = [
    { label: 'Romantic Getaway', text: '6 days honeymoon in Munnar & Alleppey houseboat, luxury and relaxation, budget 90k' },
    { label: 'Family Escape', text: '5 days with parents and kids, peaceful nature, tea gardens, easy travel, budget 65k' },
    { label: 'Monsoon Magic', text: '4 days monsoon retreat in Wayanad and Kochi, Ayurvedic spa and rain food trails, budget 45k' },
    { label: 'Adventure & Wildlife', text: '7 days bamboo rafting in Thekkady, cliff jumping in Varkala, trekking, budget 55k' },
  ];

  const toggleInterest = (id: string) => {
    if (selectedInterests.includes(id)) {
      setSelectedInterests(selectedInterests.filter((i) => i !== id));
    } else {
      setSelectedInterests([...selectedInterests, id]);
    }
  };

  const handlePromptSubmit = async () => {
    const profile = await httpAdapter.parseNaturalLanguagePrompt(promptText);
    setTripProfile(profile);
    generateTrip(profile);
  };

  const handleWizardSubmit = () => {
    const durationDays = 6;
    const profile: TripProfile = {
      id: 'profile-' + Date.now(),
      startDate,
      endDate,
      durationDays,
      adults,
      children,
      infants,
      startingLocation,
      budgetLimit: budget,
      travelStyle: budget > 100000 ? 'LUXURY' : budget > 60000 ? 'PREMIUM' : 'COMFORT',
      pace: travelStyle,
      transportPreference: 'SEDAN',
      interests: selectedInterests,
      rawPrompt: `Wizard trip with ${adults} adults, ${selectedInterests.join(', ')}`,
    };
    setTripProfile(profile);
    generateTrip(profile);
  };

  return (
    <div className="p-4 flex flex-col justify-between min-h-full bg-[#F7F3E8] text-[#1C231E]">
      {/* Top Header */}
      <div>
        <div className="flex items-center justify-between pt-1">
          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-[#C35B3A]">
              Flagship AI Architect
            </span>
            <h2 className="font-serif text-2xl font-bold text-[#144032]">
              Let's plan your trip
            </h2>
          </div>
          {/* Mode Switcher */}
          <div className="bg-[#E9DDC5] p-0.5 rounded-xl flex items-center text-xs font-bold border border-[#E2D3B8]">
            <button
              onClick={() => setMode('PROMPT')}
              className={`px-2.5 py-1 rounded-lg transition-all ${
                mode === 'PROMPT' ? 'bg-[#144032] text-[#D4AF37] shadow-sm' : 'text-gray-600'
              }`}
            >
              Natural AI
            </button>
            <button
              onClick={() => setMode('WIZARD')}
              className={`px-2.5 py-1 rounded-lg transition-all ${
                mode === 'WIZARD' ? 'bg-[#144032] text-[#D4AF37] shadow-sm' : 'text-gray-600'
              }`}
            >
              Step Wizard
            </button>
          </div>
        </div>

        {/* MODE A: NATURAL LANGUAGE INPUT (PROMPT MODE) */}
        {mode === 'PROMPT' && (
          <div className="mt-5 space-y-4 animate-in fade-in">
            <p className="text-xs text-[#4D7054]">
              Describe your dream trip or select a ready template below:
            </p>

            {/* Conversational Textarea */}
            <div className="relative rounded-3xl bg-white p-4 border border-[#E2D3B8] shadow-sm focus-within:ring-2 focus-within:ring-[#144032] transition-all">
              <textarea
                value={promptText}
                onChange={(e) => setPromptText(e.target.value)}
                rows={4}
                placeholder="e.g. 6 days with wife in June, peaceful nature and backwaters, good food, no long drives, budget 80k"
                className="w-full text-xs text-[#144032] bg-transparent resize-none focus:outline-none placeholder:text-gray-400 font-medium leading-relaxed"
              />
              <div className="flex items-center justify-between pt-2 border-t border-gray-100">
                <span className="text-[10px] text-gray-400">Deterministic NLP Parsing</span>
                <span className="text-[10px] text-[#6A8F71] font-bold">Kerala 2026 Engine</span>
              </div>
            </div>

            {/* Quick Templates */}
            <div>
              <p className="text-[11px] font-bold text-[#144032] mb-2">Popular Inquiries</p>
              <div className="space-y-2">
                {quickPrompts.map((qp) => (
                  <button
                    key={qp.label}
                    onClick={() => setPromptText(qp.text)}
                    className="w-full text-left p-2.5 rounded-2xl bg-white border border-[#E2D3B8] hover:border-[#D4AF37] transition-all flex items-center justify-between group active:scale-98"
                  >
                    <div>
                      <p className="text-xs font-bold text-[#144032]">{qp.label}</p>
                      <p className="text-[10px] text-gray-500 line-clamp-1">{qp.text}</p>
                    </div>
                    <ArrowRight className="w-3.5 h-3.5 text-[#D4AF37] group-hover:translate-x-1 transition-transform" />
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* MODE B: STEP-BY-STEP WIZARD */}
        {mode === 'WIZARD' && (
          <div className="mt-4 space-y-4 animate-in fade-in">
            {/* Step 1: Trip Basics */}
            {step === 1 && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-serif text-base font-bold text-[#144032]">Trip Basics</h3>
                  <span className="text-xs font-mono text-gray-500 font-bold">Step 1 of 4</span>
                </div>

                <div className="space-y-3">
                  <div>
                    <label className="text-[11px] font-bold text-gray-600 block mb-1">Trip Start Date</label>
                    <div className="relative">
                      <input
                        type="date"
                        value={startDate}
                        onChange={(e) => setStartDate(e.target.value)}
                        className="w-full p-3 rounded-2xl bg-white border border-[#E2D3B8] text-xs font-medium focus:ring-2 focus:ring-[#144032] focus:outline-none"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="text-[11px] font-bold text-gray-600 block mb-1">Trip End Date</label>
                    <div className="relative">
                      <input
                        type="date"
                        value={endDate}
                        onChange={(e) => setEndDate(e.target.value)}
                        className="w-full p-3 rounded-2xl bg-white border border-[#E2D3B8] text-xs font-medium focus:ring-2 focus:ring-[#144032] focus:outline-none"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="text-[11px] font-bold text-gray-600 block mb-1">Starting Location</label>
                    <div className="relative">
                      <input
                        type="text"
                        value={startingLocation}
                        onChange={(e) => setStartingLocation(e.target.value)}
                        className="w-full p-3 rounded-2xl bg-white border border-[#E2D3B8] text-xs font-medium focus:ring-2 focus:ring-[#144032] focus:outline-none"
                      />
                      <MapPin className="w-4 h-4 text-gray-400 absolute right-3.5 top-3.5" />
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Step 2: Travelers Composition */}
            {step === 2 && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-serif text-base font-bold text-[#144032]">Travelers</h3>
                  <span className="text-xs font-mono text-gray-500 font-bold">Step 2 of 4</span>
                </div>

                <div className="space-y-3">
                  {/* Adults */}
                  <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] flex items-center justify-between">
                    <div>
                      <p className="text-xs font-bold text-[#144032]">Adults</p>
                      <p className="text-[10px] text-gray-500">Ages 13 and above</p>
                    </div>
                    <div className="flex items-center gap-3">
                      <button
                        onClick={() => setAdults(Math.max(1, adults - 1))}
                        className="w-8 h-8 rounded-xl bg-gray-100 text-sm font-bold flex items-center justify-center hover:bg-gray-200"
                      >
                        -
                      </button>
                      <span className="font-bold text-sm text-[#144032] w-4 text-center">{adults}</span>
                      <button
                        onClick={() => setAdults(adults + 1)}
                        className="w-8 h-8 rounded-xl bg-[#144032] text-white text-sm font-bold flex items-center justify-center"
                      >
                        +
                      </button>
                    </div>
                  </div>

                  {/* Children */}
                  <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] flex items-center justify-between">
                    <div>
                      <p className="text-xs font-bold text-[#144032]">Children</p>
                      <p className="text-[10px] text-gray-500">Ages 2 to 12</p>
                    </div>
                    <div className="flex items-center gap-3">
                      <button
                        onClick={() => setChildren(Math.max(0, children - 1))}
                        className="w-8 h-8 rounded-xl bg-gray-100 text-sm font-bold flex items-center justify-center hover:bg-gray-200"
                      >
                        -
                      </button>
                      <span className="font-bold text-sm text-[#144032] w-4 text-center">{children}</span>
                      <button
                        onClick={() => setChildren(children + 1)}
                        className="w-8 h-8 rounded-xl bg-[#144032] text-white text-sm font-bold flex items-center justify-center"
                      >
                        +
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Step 3: Interests Multi-Select */}
            {step === 3 && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="font-serif text-base font-bold text-[#144032]">Interests</h3>
                    <p className="text-[10px] text-gray-500">Choose what you love</p>
                  </div>
                  <span className="text-xs font-mono text-gray-500 font-bold">Step 3 of 4</span>
                </div>

                <div className="grid grid-cols-3 gap-2">
                  {interestsList.map((int) => {
                    const isSelected = selectedInterests.includes(int.id);
                    return (
                      <button
                        key={int.id}
                        onClick={() => toggleInterest(int.id)}
                        className={`p-3 rounded-2xl border text-center transition-all flex flex-col items-center gap-1.5 ${
                          isSelected
                            ? 'bg-[#144032] text-[#D4AF37] border-[#D4AF37] shadow-md scale-105'
                            : 'bg-white text-gray-700 border-[#E2D3B8] hover:border-gray-400'
                        }`}
                      >
                        <span className="text-2xl">{int.icon}</span>
                        <span className="text-[11px] font-bold">{int.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Step 4: Budget & Style */}
            {step === 4 && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-serif text-base font-bold text-[#144032]">Budget & Style</h3>
                  <span className="text-xs font-mono text-gray-500 font-bold">Step 4 of 4</span>
                </div>

                {/* Budget Slider */}
                <div className="p-4 rounded-3xl bg-white border border-[#E2D3B8] space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-gray-600">Total Budget Limit</span>
                    <span className="text-base font-extrabold text-[#C35B3A]">
                      ₹{budget.toLocaleString('en-IN')}
                    </span>
                  </div>
                  <input
                    type="range"
                    min={20000}
                    max={180000}
                    step={5000}
                    value={budget}
                    onChange={(e) => setBudget(parseInt(e.target.value, 10))}
                    className="w-full accent-[#144032] cursor-pointer"
                  />
                  <div className="flex justify-between text-[10px] text-gray-400 font-mono">
                    <span>₹20k (Budget)</span>
                    <span>₹80k (Premium)</span>
                    <span>₹1.5L+ (Luxury)</span>
                  </div>
                </div>

                {/* Travel Style Pills */}
                <div>
                  <label className="text-[11px] font-bold text-gray-600 block mb-2">Travel Pace</label>
                  <div className="grid grid-cols-3 gap-2">
                    {(['RELAXED', 'BALANCED', 'PACKED'] as const).map((style) => (
                      <button
                        key={style}
                        onClick={() => setTravelStyle(style)}
                        className={`py-2.5 rounded-2xl text-xs font-bold transition-all ${
                          travelStyle === style
                            ? 'bg-[#144032] text-[#D4AF37] border border-[#D4AF37] shadow-md'
                            : 'bg-white text-gray-700 border border-[#E2D3B8]'
                        }`}
                      >
                        {style === 'RELAXED' ? 'Relaxed' : style === 'BALANCED' ? 'Balanced' : 'Packed'}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Bottom Actions */}
      <div className="pt-6">
        {mode === 'PROMPT' ? (
          <button
            onClick={handlePromptSubmit}
            className="w-full py-3.5 rounded-2xl bg-[#144032] text-[#F7F3E8] font-bold text-sm shadow-md hover:bg-[#10352A] transition-all flex items-center justify-center gap-2 transform active:scale-95"
          >
            <Sparkles className="w-4 h-4 text-[#D4AF37]" />
            <span>Start Planning</span>
          </button>
        ) : (
          <div className="flex items-center gap-2">
            {step > 1 && (
              <button
                onClick={() => setStep(step - 1)}
                className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] text-[#144032] font-bold"
              >
                <ArrowLeft className="w-4 h-4" />
              </button>
            )}
            {step < 4 ? (
              <button
                onClick={() => setStep(step + 1)}
                className="flex-1 py-3.5 rounded-2xl bg-[#144032] text-[#F7F3E8] font-bold text-sm flex items-center justify-center gap-2"
              >
                <span>Next</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            ) : (
              <button
                onClick={handleWizardSubmit}
                className="flex-1 py-3.5 rounded-2xl bg-gradient-to-r from-[#D4AF37] to-[#E5C65C] text-[#0F2823] font-bold text-sm shadow-gold flex items-center justify-center gap-2"
              >
                <Sparkles className="w-4 h-4 text-[#0F2823]" />
                <span>Generate Journey</span>
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
