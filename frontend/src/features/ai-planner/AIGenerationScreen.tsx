import React from 'react';
import { Sparkles, Check, Loader2 } from 'lucide-react';

export const AIGenerationScreen: React.FC = () => {
  const [progressIndex, setProgressIndex] = React.useState(0);

  const steps = [
    'Analyzing traveler preferences & group constraints',
    'Filtering candidate corridors & heritage attractions',
    'Optimizing road transit times across Western Ghats',
    'Checking live monsoon forecasts & weather safety',
    'Verifying boutique room inventory & experience slots',
    'Calculating transparent pricing & Green Trip Score',
  ];

  React.useEffect(() => {
    const timer = setInterval(() => {
      setProgressIndex((prev) => (prev < steps.length - 1 ? prev + 1 : prev));
    }, 450);
    return () => clearInterval(timer);
  }, [steps.length]);

  return (
    <div className="min-h-full bg-gradient-to-b from-[#0F2823] via-[#144032] to-[#0A1D19] text-[#F7F3E8] p-6 flex flex-col justify-between items-center text-center">
      {/* Top AI Indicator */}
      <div className="pt-4">
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#D4AF37]/20 border border-[#D4AF37]/30 text-xs font-bold text-[#D4AF37]">
          <Sparkles className="w-3.5 h-3.5" />
          <span>KeraLink AI Travel Engine</span>
        </div>
        <h2 className="font-serif text-3xl font-extrabold text-[#F7F3E8] mt-3">
          AI is crafting <br />
          <span className="italic text-[#D4AF37]">your journey ✨</span>
        </h2>
      </div>

      {/* Center Botanical Landscape Visual */}
      <div className="my-6 relative">
        <div className="relative w-64 h-48 rounded-3xl overflow-hidden border-2 border-[#D4AF37]/40 shadow-2xl">
          <img
            src="https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=600&q=80"
            alt="Kerala Hills"
            className="w-full h-full object-cover animate-pulse"
            style={{ animationDuration: '3s' }}
          />
          <div className="absolute inset-0 bg-gradient-to-t from-[#0F2823]/80 via-transparent to-transparent flex items-end justify-center p-3">
            <span className="text-[11px] text-[#C5D8CD] font-medium">Munnar · Alleppey · Varkala</span>
          </div>
        </div>

        {/* Ambient Pulsing Radar */}
        <div className="absolute -inset-4 rounded-3xl border border-[#D4AF37]/20 animate-ping pointer-events-none" style={{ animationDuration: '3s' }} />
      </div>

      {/* Real-Time Processing Checklist */}
      <div className="w-full max-w-xs space-y-2 text-left bg-[#0A1D19]/60 p-4 rounded-2xl border border-white/10 backdrop-blur-md">
        {steps.map((text, idx) => {
          const isDone = idx <= progressIndex;
          const isCurrent = idx === progressIndex;

          return (
            <div
              key={text}
              className={`flex items-center gap-2 text-xs transition-all ${
                isDone ? 'text-[#F7F3E8] font-medium' : 'text-gray-500 opacity-40'
              }`}
            >
              {isDone ? (
                <div className="w-4 h-4 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center">
                  <Check className="w-3 h-3 stroke-[3]" />
                </div>
              ) : isCurrent ? (
                <Loader2 className="w-4 h-4 text-[#D4AF37] animate-spin" />
              ) : (
                <div className="w-4 h-4 rounded-full border border-gray-600" />
              )}
              <span className="text-[11px] truncate">{text}</span>
            </div>
          );
        })}
      </div>

      {/* Bottom Progress Bar */}
      <div className="w-full max-w-xs pt-4">
        <div className="h-1.5 w-full bg-white/10 rounded-full overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-[#D4AF37] to-emerald-400 transition-all duration-300"
            style={{ width: `${Math.min(100, ((progressIndex + 1) / steps.length) * 100)}%` }}
          />
        </div>
        <p className="text-[10px] text-gray-400 mt-2 font-mono">
          Finalizing deterministic constraints... {Math.round(((progressIndex + 1) / steps.length) * 100)}%
        </p>
      </div>
    </div>
  );
};
