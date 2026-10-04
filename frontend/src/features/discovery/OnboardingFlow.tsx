import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { Sparkles, Heart, Compass, ShieldCheck, ArrowRight, CheckCircle2 } from 'lucide-react';

export const OnboardingFlow: React.FC = () => {
  const { navigateTo } = useAppStore();
  const [step, setStep] = React.useState(1);

  return (
    <div className="relative min-h-full bg-[#F7F3E8] text-[#1C231E] p-6 flex flex-col justify-between">
      {/* Top Header: Step Indicator & Skip */}
      <div className="flex items-center justify-between pt-2">
        <div className="flex items-center gap-1.5">
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className={`h-1.5 rounded-full transition-all duration-300 ${
                i === step ? 'w-8 bg-[#144032]' : 'w-2 bg-[#144032]/20'
              }`}
            />
          ))}
        </div>
        <button
          onClick={() => navigateTo('HOME')}
          className="text-xs font-semibold text-[#6A8F71] hover:text-[#144032] uppercase tracking-wider"
        >
          Skip
        </button>
      </div>

      {/* Step 1: Experience Kerala Like Never Before */}
      {step === 1 && (
        <div className="my-auto text-center space-y-6 animate-in fade-in">
          <div className="relative mx-auto w-64 h-64 rounded-full overflow-hidden border-4 border-[#D4AF37]/30 shadow-2xl">
            <img
              src="https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=600&q=80"
              alt="Kerala Sunset"
              className="w-full h-full object-cover"
            />
          </div>
          <div>
            <h2 className="font-serif text-3xl font-extrabold text-[#144032] leading-tight">
              Experience Kerala <br />
              <span className="italic text-[#C35B3A]">like never before</span>
            </h2>
            <p className="text-sm text-[#4D7054] mt-3 max-w-xs mx-auto leading-relaxed">
              Personalized trips crafted by AI based on your dreams, budget, and authentic local experiences.
            </p>
          </div>
        </div>
      )}

      {/* Step 2: Tell Us About Your Journey */}
      {step === 2 && (
        <div className="my-auto space-y-6 animate-in fade-in">
          <div className="text-center">
            <h2 className="font-serif text-3xl font-extrabold text-[#144032]">
              Tell us about <br />
              <span className="italic text-[#C35B3A]">your journey</span>
            </h2>
            <p className="text-xs text-[#4D7054] mt-2">
              We’ll design the perfect bespoke trip for you in seconds.
            </p>
          </div>

          <div className="space-y-3 max-w-xs mx-auto">
            <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#144032]/10 text-[#144032] flex items-center justify-center">
                <Heart className="w-5 h-5 text-[#C35B3A]" />
              </div>
              <div>
                <p className="text-xs font-bold text-[#144032]">Your Preferences</p>
                <p className="text-[11px] text-gray-500">Nature, food, culture, romantic</p>
              </div>
            </div>

            <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#D4AF37]/20 text-[#0F2823] flex items-center justify-center font-bold">
                ₹
              </div>
              <div>
                <p className="text-xs font-bold text-[#144032]">Your Budget</p>
                <p className="text-[11px] text-gray-500">From ₹20k to ₹1.5L+ luxury</p>
              </div>
            </div>

            <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#6A8F71]/20 text-[#144032] flex items-center justify-center">
                <Compass className="w-5 h-5 text-[#144032]" />
              </div>
              <div>
                <p className="text-xs font-bold text-[#144032]">Your Travel Style</p>
                <p className="text-[11px] text-gray-500">Relaxed pace, no rushed drives</p>
              </div>
            </div>

            <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-rose-100 text-rose-600 flex items-center justify-center">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <div>
                <p className="text-xs font-bold text-[#144032]">Your Comfort</p>
                <p className="text-[11px] text-gray-500">Verified eco-stays & native hosts</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Step 3: AI Creates Your Perfect Itinerary */}
      {step === 3 && (
        <div className="my-auto text-center space-y-6 animate-in fade-in">
          {/* Animated AI Nodal Sphere */}
          <div className="relative mx-auto w-56 h-56 flex items-center justify-center">
            <div className="absolute inset-0 rounded-full border-2 border-dashed border-[#D4AF37] animate-spin" style={{ animationDuration: '20s' }} />
            <div className="absolute inset-4 rounded-full bg-gradient-to-tr from-[#144032] to-[#1A5340] shadow-2xl flex flex-col items-center justify-center text-[#F7F3E8] p-4">
              <Sparkles className="w-10 h-10 text-[#D4AF37] animate-bounce" />
              <span className="font-serif text-2xl font-bold mt-2">AI</span>
              <span className="text-[10px] text-[#C5D8CD] tracking-widest uppercase font-semibold">Architect</span>
            </div>
            {/* Satellites */}
            <div className="absolute top-0 px-2 py-1 rounded-full bg-white shadow-md text-[10px] font-bold text-[#144032] border border-[#D4AF37]/40">
              🌿 Nature
            </div>
            <div className="absolute bottom-2 px-2 py-1 rounded-full bg-white shadow-md text-[10px] font-bold text-[#144032] border border-[#D4AF37]/40">
              🛶 Backwaters
            </div>
            <div className="absolute right-0 px-2 py-1 rounded-full bg-white shadow-md text-[10px] font-bold text-[#144032] border border-[#D4AF37]/40">
              🍛 Food
            </div>
          </div>

          <div>
            <h2 className="font-serif text-3xl font-extrabold text-[#144032]">
              AI creates your <br />
              <span className="italic text-[#C35B3A]">perfect itinerary</span>
            </h2>
            <p className="text-xs text-[#4D7054] mt-2 max-w-xs mx-auto">
              Smart deterministic planning: optimal routes, weather-aware alternatives, and realistic hourly timelines.
            </p>
          </div>
        </div>
      )}

      {/* Step 4: Customize, Book & Enjoy Kerala */}
      {step === 4 && (
        <div className="my-auto text-center space-y-6 animate-in fade-in">
          <div className="relative mx-auto w-64 h-52 rounded-3xl overflow-hidden border-2 border-[#D4AF37]/40 shadow-xl">
            <img
              src="https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=600&q=80"
              alt="Munnar Tea Hills"
              className="w-full h-full object-cover"
            />
          </div>
          <div>
            <h2 className="font-serif text-3xl font-extrabold text-[#144032]">
              Customize, book <br />
              <span className="italic text-[#C35B3A]">& enjoy Kerala</span>
            </h2>
            <p className="text-xs text-[#4D7054] mt-2 max-w-xs mx-auto">
              Everything in one place: before, during, and after your trip with our 24/7 Live AI Companion.
            </p>
          </div>
        </div>
      )}

      {/* Bottom Button Action */}
      <div className="pt-4">
        {step < 4 ? (
          <button
            onClick={() => setStep(step + 1)}
            className="w-full py-3.5 rounded-2xl bg-[#144032] text-[#F7F3E8] font-bold text-sm shadow-md hover:bg-[#10352A] transition-all flex items-center justify-center gap-2"
          >
            <span>{step === 1 ? 'Get Started' : 'Next'}</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        ) : (
          <button
            onClick={() => navigateTo('HOME')}
            className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-[#D4AF37] to-[#E5C65C] text-[#0F2823] font-bold text-sm shadow-gold hover:opacity-95 transition-all flex items-center justify-center gap-2"
          >
            <CheckCircle2 className="w-4 h-4 text-[#0F2823]" />
            <span>Let's Go</span>
          </button>
        )}
      </div>
    </div>
  );
};
