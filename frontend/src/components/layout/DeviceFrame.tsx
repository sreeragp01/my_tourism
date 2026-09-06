import React from 'react';
import { useAppStore, ScreenId } from '../../stores/useAppStore';
import { BottomNav } from './BottomNav';
import { Wifi, BatteryMedium, Signal } from 'lucide-react';

interface DeviceFrameProps {
  children: React.ReactNode;
}

export const DeviceFrame: React.FC<DeviceFrameProps> = ({ children }) => {
  const { activeScreen, navigateTo } = useAppStore();

  const screenFlows: { label: string; screen: ScreenId; badge?: string }[] = [
    { label: '0. Landing', screen: 'LANDING' },
    { label: '1. Onboarding', screen: 'ONBOARDING' },
    { label: '2. Home & Discover', screen: 'HOME' },
    { label: '2b. Explore Kerala', screen: 'EXPLORE' },
    { label: '2c. Map View', screen: 'MAP' },
    { label: '3. AI Trip Planner', screen: 'AI_PLANNER', badge: 'Flagship' },
    { label: '4. Itinerary Timeline', screen: 'ITINERARY' },
    { label: '5. Bookings & Pay', screen: 'CHECKOUT' },
    { label: '6. Live Companion', screen: 'COMPANION' },
    { label: '6b. Safety Center', screen: 'SAFETY' },
    { label: '7. My Trips Pass', screen: 'MY_TRIPS' },
  ];

  const hideBottomNav = activeScreen === 'LANDING' || activeScreen === 'ONBOARDING' || activeScreen === 'AI_GENERATING';

  return (
    <div className="min-h-screen bg-[#0A1D19] py-8 px-4 flex flex-col items-center justify-start bg-leaf-pattern">
      {/* Screen Flow Quick Selector Toolbar */}
      <div className="max-w-4xl w-full mb-6 bg-[#0F2823]/90 backdrop-blur-md border border-[#D4AF37]/30 rounded-2xl p-3 shadow-xl">
        <div className="flex items-center justify-between mb-2 px-1">
          <div className="flex items-center gap-2">
            <span className="text-xs font-bold uppercase tracking-wider text-[#D4AF37]">
              Design Board Flow Jump
            </span>
            <span className="text-[11px] text-[#C5D8CD] hidden sm:inline">
              (Directly navigate to any screen from the UI design spec)
            </span>
          </div>
          <span className="text-xs px-2 py-0.5 rounded-full bg-[#144032] text-[#D4AF37] border border-[#D4AF37]/30 font-mono font-bold">
            Screen: {activeScreen}
          </span>
        </div>
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-none">
          {screenFlows.map((flow) => {
            const isActive = activeScreen === flow.screen;
            return (
              <button
                key={flow.screen}
                onClick={() => navigateTo(flow.screen)}
                className={`whitespace-nowrap px-3 py-1.5 rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 ${
                  isActive
                    ? 'bg-[#D4AF37] text-[#0F2823] shadow-gold font-bold scale-105'
                    : 'bg-[#144032]/80 text-[#E7EFEA] hover:bg-[#1A5340] border border-white/5'
                }`}
              >
                <span>{flow.label}</span>
                {flow.badge && (
                  <span className={`text-[9px] px-1 py-0.2 rounded font-bold uppercase ${
                    isActive ? 'bg-[#0F2823] text-[#D4AF37]' : 'bg-[#D4AF37]/20 text-[#D4AF37]'
                  }`}>
                    {flow.badge}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Modern High-End Smartphone Frame */}
      <div className="relative w-full max-w-[420px] h-[870px] bg-[#F7F3E8] rounded-[52px] border-[10px] border-[#1C231E] ring-4 ring-[#D4AF37]/40 shadow-2xl overflow-hidden flex flex-col">
        {/* Dynamic Island / Top Notch & Mobile Status Bar */}
        <div className="bg-[#0F2823] text-[#F7F3E8] px-7 pt-3 pb-2 flex items-center justify-between z-50 select-none">
          <span className="text-xs font-semibold tracking-tight font-sans">9:41</span>
          
          {/* Dynamic Island Notch */}
          <div className="w-24 h-4 bg-[#051611] rounded-full flex items-center justify-center gap-2 px-2 border border-white/10">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span className="text-[9px] text-[#D4AF37] font-serif font-bold">KeraLink</span>
          </div>

          <div className="flex items-center gap-1.5 text-xs text-[#C5D8CD]">
            <Signal className="w-3.5 h-3.5" />
            <Wifi className="w-3.5 h-3.5" />
            <BatteryMedium className="w-4 h-4" />
          </div>
        </div>

        {/* Scrollable Screen Content Container */}
        <div className="flex-1 overflow-y-auto bg-[#F7F3E8] relative flex flex-col">
          {children}
        </div>

        {/* Persistent Bottom Nav (When not on Landing/Onboarding) */}
        {!hideBottomNav && <BottomNav />}
      </div>
    </div>
  );
};
