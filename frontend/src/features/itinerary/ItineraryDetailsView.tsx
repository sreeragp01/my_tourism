import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import {
  Sparkles,
  MapPin,
  Clock,
  Car,
  ChevronRight,
  Sliders,
  DollarSign,
  ShieldCheck,
  Leaf,
  RefreshCw,
  Umbrella,
  TrendingDown,
  Compass,
  ArrowRight,
  CloudRain,
  Sun,
  AlertTriangle,
} from 'lucide-react';
import { ItineraryDay } from '../../types/contracts';
import { httpAdapter } from '../../adapters/httpAdapter';

export const ItineraryDetailsView: React.FC = () => {
  const {
    currentPlan,
    selectedDayNumber,
    setSelectedDayNumber,
    regenerateDay,
    navigateTo,
    createBooking,
    isGenerating,
  } = useAppStore();

  const [customizeModalOpen, setCustomizeModalOpen] = React.useState(false);
  const [costBreakdownOpen, setCostBreakdownOpen] = React.useState(false);
  const [dayWeather, setDayWeather] = React.useState<any>(null);

  if (!currentPlan) {
    return (
      <div className="p-8 text-center space-y-4">
        <p className="text-sm text-gray-500">No active itinerary generated yet.</p>
        <button
          onClick={() => navigateTo('AI_PLANNER')}
          className="px-4 py-2 rounded-xl bg-[#144032] text-white text-xs font-bold"
        >
          Plan a Trip Now
        </button>
      </div>
    );
  }

  const currentVersion = currentPlan.currentVersion;
  const days = currentVersion.itineraryDays;
  const activeDay = days.find((d) => d.dayNumber === selectedDayNumber) || days[0];

  React.useEffect(() => {
    if (!activeDay) return;
    let isMounted = true;
    const destSlug = activeDay.destinationId?.toLowerCase() || 'munnar';
    httpAdapter.getDestinationWeather(destSlug).then((data) => {
      if (isMounted) setDayWeather(data);
    });
    return () => {
      isMounted = false;
    };
  }, [activeDay]);

  const handleBookNow = async () => {
    await createBooking({
      name: 'Sreerag P',
      phone: '+91 98460 12345',
      email: 'sreerag@keralink.travel',
    });
  };

  return (
    <div className="p-4 space-y-4 pb-12 text-[#1C231E]">
      {/* Top Trip Summary Hero Card */}
      <div className="rounded-3xl bg-gradient-to-br from-[#144032] to-[#0F2823] p-5 text-[#F7F3E8] shadow-xl border border-[#D4AF37]/30">
        <div className="flex items-center justify-between">
          <span className="px-2.5 py-0.5 rounded-full bg-[#D4AF37]/20 border border-[#D4AF37]/30 text-[10px] font-bold text-[#D4AF37] uppercase">
            Plan v{currentVersion.versionNumber} · AI Architect
          </span>
          <div className="flex items-center gap-1 text-[11px] font-bold text-emerald-400">
            <Leaf className="w-3.5 h-3.5" />
            <span>Green Score: {currentVersion.greenTripScore}/100</span>
          </div>
        </div>

        <h2 className="font-serif text-2xl font-bold mt-2">Your Kerala Journey</h2>
        <p className="text-xs text-[#C5D8CD] mt-0.5">
          {days[0]?.date} - {days[days.length - 1]?.date} · {days.length} Days
        </p>

        {/* Tags */}
        <div className="flex items-center gap-1.5 mt-3">
          <span className="px-2 py-0.5 rounded-lg bg-white/10 text-[10px] font-medium text-white">
            Relaxed
          </span>
          <span className="px-2 py-0.5 rounded-lg bg-white/10 text-[10px] font-medium text-white">
            Couple
          </span>
          <span className="px-2 py-0.5 rounded-lg bg-white/10 text-[10px] font-medium text-white">
            ₹50k - ₹80k
          </span>
        </div>

        {/* Pricing & CTA */}
        <div className="mt-4 pt-3 border-t border-white/10 flex items-center justify-between">
          <div>
            <p className="text-[10px] text-[#C5D8CD] uppercase font-bold">Estimated Cost</p>
            <p className="font-serif text-2xl font-extrabold text-[#D4AF37]">
              ₹{currentVersion.pricing.total.toLocaleString('en-IN')}
              <span className="text-xs font-normal text-[#C5D8CD] ml-1 font-sans">for 2 guests</span>
            </p>
          </div>
          <button
            onClick={() => setCostBreakdownOpen(true)}
            className="text-[11px] font-bold text-[#D4AF37] underline hover:text-white"
          >
            Cost Breakdown
          </button>
        </div>

        <div className="grid grid-cols-2 gap-2.5 mt-4">
          <button
            onClick={() => setCustomizeModalOpen(true)}
            className="py-2.5 rounded-xl bg-white/10 hover:bg-white/20 border border-white/20 text-xs font-bold text-white transition-all flex items-center justify-center gap-1.5"
          >
            <Sliders className="w-3.5 h-3.5 text-[#D4AF37]" />
            <span>Customize Day</span>
          </button>
          <button
            onClick={handleBookNow}
            className="py-2.5 rounded-xl bg-gradient-to-r from-[#D4AF37] to-[#E5C65C] text-[#0F2823] text-xs font-extrabold shadow-gold hover:opacity-95 transition-all flex items-center justify-center gap-1.5 transform active:scale-95"
          >
            <span>Book Now</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Version Change Notice if regenerated */}
      {currentVersion.versionNumber > 1 && (
        <div className="p-3 rounded-2xl bg-amber-50 border border-amber-200 text-xs text-amber-900 flex items-center gap-2">
          <RefreshCw className="w-4 h-4 text-amber-600 shrink-0" />
          <div>
            <p className="font-bold">Plan Version {currentVersion.versionNumber} Active</p>
            <p className="text-[11px] text-amber-800">{currentVersion.changeReason}</p>
          </div>
        </div>
      )}

      {/* Day Selector Pill Navigation */}
      <div>
        <div className="flex items-center justify-between mb-2 px-1">
          <h3 className="font-serif text-sm font-bold text-[#144032]">Itinerary Days</h3>
          <span className="text-[11px] text-gray-500">{days.length} Days Corridor</span>
        </div>
        <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
          {days.map((d) => {
            const isSelected = d.dayNumber === selectedDayNumber;
            return (
              <button
                key={d.dayNumber}
                onClick={() => setSelectedDayNumber(d.dayNumber)}
                className={`flex-shrink-0 px-3.5 py-2 rounded-2xl text-xs font-bold transition-all text-left ${
                  isSelected
                    ? 'bg-[#144032] text-[#D4AF37] shadow-md border border-[#D4AF37]/30 scale-105'
                    : 'bg-white text-gray-700 border border-[#E2D3B8] hover:border-[#144032]'
                }`}
              >
                <span className="block text-[10px] opacity-70">Day {d.dayNumber}</span>
                <span className="block">{d.destinationName.split(' ')[0]}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Selected Day Hero Card */}
      <div className="rounded-3xl overflow-hidden bg-white border border-[#E2D3B8] shadow-sm">
        <div className="relative h-40">
          <img
            src={activeDay.destinationHero}
            alt={activeDay.destinationName}
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-[#0F2823] via-[#0F2823]/30 to-transparent flex flex-col justify-end p-4">
            <span className="text-[10px] font-bold text-[#D4AF37] uppercase">
              Day {activeDay.dayNumber} · {activeDay.date}
            </span>
            <h3 className="font-serif text-xl font-bold text-white mt-0.5">
              {activeDay.destinationName}
            </h3>
            <p className="text-xs text-[#C5D8CD] italic font-serif mt-0.5">{activeDay.themeTitle}</p>
          </div>
        </div>

        {/* Accommodation Header for the day */}
        {activeDay.accommodation && (
          <div className="p-3 bg-[#FAF5EA] border-b border-[#E2D3B8] flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-lg">🏨</span>
              <div>
                <p className="text-xs font-bold text-[#144032]">{activeDay.accommodation.name}</p>
                <p className="text-[10px] text-gray-500">{activeDay.accommodation.tagline}</p>
              </div>
            </div>
            <span className="text-xs font-bold text-[#C35B3A]">
              ₹{activeDay.accommodation.basePricePerNight.toLocaleString('en-IN')}/nt
            </span>
          </div>
        )}

        {/* Real-time Day Weather Telemetry & Monsoon Shield */}
        {dayWeather && (
          <div className="p-3 bg-[#0F2823] text-[#F7F3E8] border-b border-[#D4AF37]/30 flex items-center justify-between flex-wrap gap-2">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-xl bg-[#144032] border border-[#D4AF37]/40 flex items-center justify-center">
                {dayWeather.rain_probability_percent >= 50 ? (
                  <CloudRain className="w-4 h-4 text-cyan-400" />
                ) : (
                  <Sun className="w-4 h-4 text-amber-400" />
                )}
              </div>
              <div>
                <div className="flex items-center gap-1.5">
                  <span className="text-xs font-bold text-white">
                    {dayWeather.temperature_celsius}°C • {dayWeather.condition}
                  </span>
                  <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-[#144032] text-emerald-400 font-mono font-bold border border-emerald-500/30">
                    {dayWeather.rain_probability_percent}% Rain
                  </span>
                </div>
                <p className="text-[10px] text-[#C5D8CD] italic line-clamp-1">
                  {dayWeather.recommendation || 'Ghat road speeds monitored.'}
                </p>
              </div>
            </div>

            {/* Quick Rain Shift Trigger */}
            <button
              onClick={() => regenerateDay(activeDay.dayNumber, 'RAIN_FRIENDLY')}
              disabled={isGenerating}
              className="px-2.5 py-1 rounded-lg bg-[#144032] hover:bg-[#1A5340] text-[11px] font-bold text-[#D4AF37] border border-[#D4AF37]/40 transition-all flex items-center gap-1 shadow-sm"
              title="Re-architect outdoor activities for sheltered spice masterclasses and heritage museums"
            >
              <Umbrella className="w-3.5 h-3.5 text-blue-400" />
              <span>Shift to Rain-Friendly</span>
            </button>
          </div>
        )}

        {/* Hourly Timeline */}
        <div className="p-4 space-y-4">
          {activeDay.timeline.map((event, idx) => (
            <div key={event.id || idx} className="flex gap-3 relative group">
              {/* Timeline Time Marker */}
              <div className="w-12 text-right">
                <span className="text-xs font-mono font-bold text-[#144032] block">{event.time}</span>
                <span className="text-[10px] text-gray-400 block">{event.durationMins}m</span>
              </div>

              {/* Vertical connector line & icon */}
              <div className="flex flex-col items-center">
                <div
                  className={`w-4 h-4 rounded-full flex items-center justify-center text-[10px] ${
                    event.type === 'EXPERIENCE'
                      ? 'bg-[#D4AF37] text-[#0F2823] shadow-gold'
                      : event.type === 'MEAL'
                      ? 'bg-amber-600 text-white'
                      : event.type === 'TRANSIT'
                      ? 'bg-blue-600 text-white'
                      : 'bg-[#144032] text-white'
                  }`}
                >
                  •
                </div>
                {idx < activeDay.timeline.length - 1 && (
                  <div className="w-0.5 flex-1 bg-gray-200 my-1" />
                )}
              </div>

              {/* Event Details Card */}
              <div className="flex-1 pb-3">
                <div className="flex items-start justify-between">
                  <div>
                    <h4 className="text-xs font-bold text-[#144032]">{event.title}</h4>
                    <p className="text-[11px] text-gray-500 flex items-center gap-1 mt-0.5">
                      <MapPin className="w-3 h-3 text-gray-400" />
                      <span>{event.locationName}</span>
                    </p>
                  </div>
                  {event.cost > 0 && (
                    <span className="text-[11px] font-bold text-[#C35B3A]">
                      ₹{event.cost.toLocaleString('en-IN')}
                    </span>
                  )}
                </div>

                {event.isRainAlternative && (
                  <span className="inline-flex items-center gap-1 mt-1 px-2 py-0.5 rounded bg-blue-50 text-blue-700 text-[10px] font-semibold border border-blue-200">
                    <Umbrella className="w-3 h-3" />
                    Monsoon Indoor Alternative
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* MODAL: CUSTOMIZE / REGENERATE THIS DAY */}
      {customizeModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-end sm:items-center justify-center p-4">
          <div className="w-full max-w-sm bg-[#F7F3E8] rounded-3xl p-5 border border-[#D4AF37]/40 shadow-2xl space-y-4 animate-in slide-in-from-bottom-6">
            <div className="flex items-center justify-between border-b border-gray-200 pb-3">
              <div>
                <h3 className="font-serif text-lg font-bold text-[#144032]">
                  Customize Day {activeDay.dayNumber}
                </h3>
                <p className="text-[11px] text-gray-500">
                  Select AI modifier to re-architect this day
                </p>
              </div>
              <button
                onClick={() => setCustomizeModalOpen(false)}
                className="text-gray-400 hover:text-gray-700 text-lg font-bold"
              >
                ✕
              </button>
            </div>

            <div className="space-y-2">
              <button
                onClick={() => regenerateDay(activeDay.dayNumber, 'RAIN_FRIENDLY')}
                disabled={isGenerating}
                className="w-full p-3 rounded-2xl bg-white border border-[#E2D3B8] hover:border-blue-500 hover:bg-blue-50/50 transition-all text-left flex items-center gap-3"
              >
                <div className="w-9 h-9 rounded-xl bg-blue-100 text-blue-700 flex items-center justify-center">
                  <Umbrella className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs font-bold text-[#144032]">Rain-Friendly / Monsoon Shift</p>
                  <p className="text-[10px] text-gray-500">Swap outdoor treks for covered spice & culture tours</p>
                </div>
              </button>

              <button
                onClick={() => regenerateDay(activeDay.dayNumber, 'MAKE_CHEAPER')}
                disabled={isGenerating}
                className="w-full p-3 rounded-2xl bg-white border border-[#E2D3B8] hover:border-emerald-500 hover:bg-emerald-50/50 transition-all text-left flex items-center gap-3"
              >
                <div className="w-9 h-9 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center">
                  <TrendingDown className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs font-bold text-[#144032]">Make This Day Cheaper</p>
                  <p className="text-[10px] text-gray-500">Select authentic eco-homestays & budget dining</p>
                </div>
              </button>

              <button
                onClick={() => regenerateDay(activeDay.dayNumber, 'ADD_ADVENTURE')}
                disabled={isGenerating}
                className="w-full p-3 rounded-2xl bg-white border border-[#E2D3B8] hover:border-amber-500 hover:bg-amber-50/50 transition-all text-left flex items-center gap-3"
              >
                <div className="w-9 h-9 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center">
                  <Compass className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs font-bold text-[#144032]">Add High Adventure</p>
                  <p className="text-[10px] text-gray-500">4x4 Jeep Safari, peak ridge treks, zip-lining</p>
                </div>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: TRIP COST BREAKDOWN */}
      {costBreakdownOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-end sm:items-center justify-center p-4">
          <div className="w-full max-w-sm bg-[#F7F3E8] rounded-3xl p-5 border border-[#D4AF37]/40 shadow-2xl space-y-4 animate-in slide-in-from-bottom-6">
            <div className="flex items-center justify-between border-b border-gray-200 pb-3">
              <h3 className="font-serif text-lg font-bold text-[#144032]">Trip Cost Breakdown</h3>
              <button
                onClick={() => setCostBreakdownOpen(false)}
                className="text-gray-400 hover:text-gray-700 text-lg font-bold"
              >
                ✕
              </button>
            </div>

            <div className="space-y-2.5 text-xs">
              <div className="flex justify-between py-1 border-b border-gray-100">
                <span className="text-gray-600">Hotels & Stays (5 Nights)</span>
                <span className="font-bold text-[#144032]">₹{currentVersion.pricing.staysTotal.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-gray-100">
                <span className="text-gray-600">Private AC Chauffeur Transport</span>
                <span className="font-bold text-[#144032]">₹{currentVersion.pricing.transportTotal.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-gray-100">
                <span className="text-gray-600">Guided Experiences & Permits</span>
                <span className="font-bold text-[#144032]">₹{currentVersion.pricing.experiencesTotal.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-gray-100">
                <span className="text-gray-600">Curated Meals & Tasting</span>
                <span className="font-bold text-[#144032]">₹{currentVersion.pricing.mealsEstimate.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-gray-100">
                <span className="text-gray-600">GST (5%) & Platform Insurance</span>
                <span className="font-bold text-[#144032]">₹{currentVersion.pricing.taxesAndFees.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between py-1 text-emerald-700 font-semibold">
                <span>KeraLink Special Discount</span>
                <span>-₹{currentVersion.pricing.discount.toLocaleString('en-IN')}</span>
              </div>
              <div className="flex justify-between pt-2 border-t-2 border-[#144032] text-sm font-extrabold text-[#144032]">
                <span>Total Package Price</span>
                <span className="text-[#C35B3A]">₹{currentVersion.pricing.total.toLocaleString('en-IN')}</span>
              </div>
              <p className="text-[10px] text-gray-500 text-center pt-1 font-mono">
                Price per person: ₹{(currentVersion.pricing.total / 2).toLocaleString('en-IN')}
              </p>
            </div>

            <button
              onClick={() => {
                setCostBreakdownOpen(false);
                handleBookNow();
              }}
              className="w-full py-3 rounded-2xl bg-[#144032] text-[#F7F3E8] text-xs font-bold"
            >
              Proceed to Checkout
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
