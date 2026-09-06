import React from 'react';
import { useAppStore, ScreenId } from '../../stores/useAppStore';
import { Home, Compass, Sparkles, Briefcase, User as UserIcon } from 'lucide-react';

export const BottomNav: React.FC = () => {
  const { activeScreen, navigateTo } = useAppStore();

  const tabs: { screen: ScreenId; label: string; icon: React.ReactNode }[] = [
    { screen: 'HOME', label: 'Home', icon: <Home className="w-5 h-5" /> },
    { screen: 'EXPLORE', label: 'Explore', icon: <Compass className="w-5 h-5" /> },
    { screen: 'AI_PLANNER', label: 'AI Planner', icon: <Sparkles className="w-5 h-5" /> },
    { screen: 'MY_TRIPS', label: 'Trips', icon: <Briefcase className="w-5 h-5" /> },
    { screen: 'COMPANION', label: 'Companion', icon: <UserIcon className="w-5 h-5" /> },
  ];

  return (
    <div className="sticky bottom-0 left-0 right-0 z-40 bg-[#0F2823]/95 backdrop-blur-md border-t border-[#D4AF37]/25 px-3 py-2 flex items-center justify-around shadow-2xl">
      {tabs.map((tab) => {
        const isActive = activeScreen === tab.screen;
        return (
          <button
            key={tab.screen}
            onClick={() => navigateTo(tab.screen)}
            className={`flex flex-col items-center gap-1 transition-all relative py-1 px-3 rounded-xl ${
              isActive
                ? 'text-[#D4AF37] font-semibold scale-105'
                : 'text-[#C5D8CD]/70 hover:text-[#F7F3E8]'
            }`}
          >
            {tab.icon}
            <span className="text-[10px] tracking-tight">{tab.label}</span>
            {isActive && (
              <span className="absolute bottom-0 w-1.5 h-1.5 bg-[#D4AF37] rounded-full shadow-gold animate-pulse" />
            )}
          </button>
        );
      })}
    </div>
  );
};
