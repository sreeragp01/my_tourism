import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { LandingHero } from '../discovery/LandingHero';
import { HomeDiscover } from '../home/HomeDiscover';
import { ExploreKerala } from '../discovery/ExploreKerala';
import { KeralaMapView } from '../discovery/KeralaMapView';
import { AIPlannerFlow } from '../ai-planner/AIPlannerFlow';
import { AIGenerationScreen } from '../ai-planner/AIGenerationScreen';
import { ItineraryDetailsView } from '../itinerary/ItineraryDetailsView';
import { BookingCheckout } from '../bookings/BookingCheckout';
import { BookingConfirmation } from '../bookings/BookingConfirmation';
import { LiveCompanionView } from '../companion/LiveCompanionView';
import { SafetyEmergencyHub } from '../safety/SafetyEmergencyHub';
import { MyTripsView } from '../trips/MyTripsView';
import { ProviderPortalView } from '../provider/ProviderPortalView';
import { AdminPortalView } from '../admin/AdminPortalView';
import { Sparkles, Compass, MapPin, ShieldCheck, Briefcase } from 'lucide-react';

export const WebPlatformLayout: React.FC = () => {
  const { activeScreen, navigateTo } = useAppStore();

  const renderActiveScreen = () => {
    switch (activeScreen) {
      case 'LANDING':
        return <LandingHero />;
      case 'ONBOARDING':
      case 'HOME':
        return <HomeDiscover />;
      case 'EXPLORE':
        return <ExploreKerala />;
      case 'MAP':
        return <KeralaMapView />;
      case 'AI_PLANNER':
        return <AIPlannerFlow />;
      case 'AI_GENERATING':
        return <AIGenerationScreen />;
      case 'ITINERARY':
        return <ItineraryDetailsView />;
      case 'CHECKOUT':
        return <BookingCheckout />;
      case 'BOOKING_CONFIRMED':
        return <BookingConfirmation />;
      case 'COMPANION':
        return <LiveCompanionView />;
      case 'SAFETY':
        return <SafetyEmergencyHub />;
      case 'MY_TRIPS':
        return <MyTripsView />;
      case 'PROVIDER_PORTAL':
        return <ProviderPortalView />;
      case 'ADMIN_PORTAL':
        return <AdminPortalView />;
      default:
        return <HomeDiscover />;
    }
  };

  return (
    <div className="min-h-screen bg-[#F7F3E8] text-[#1C231E]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Breadcrumb Navigation Ribbon */}
        <div className="flex items-center justify-between mb-6 pb-3 border-b border-[#E2D3B8]">
          <div className="flex items-center gap-2 text-xs font-semibold text-[#6A8F71]">
            <span
              onClick={() => navigateTo('LANDING')}
              className="cursor-pointer hover:text-[#144032]"
            >
              KeraLink
            </span>
            <span>/</span>
            <span className="text-[#144032] font-bold capitalize">{activeScreen.toLowerCase().replace('_', ' ')}</span>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => navigateTo('AI_PLANNER')}
              className="px-3.5 py-1.5 rounded-xl bg-[#144032] text-[#D4AF37] text-xs font-bold shadow-sm flex items-center gap-1.5 hover:bg-[#10352A]"
            >
              <Sparkles className="w-3.5 h-3.5" />
              <span>AI Trip Architect</span>
            </button>
            <button
              onClick={() => navigateTo('MAP')}
              className="px-3.5 py-1.5 rounded-xl bg-white border border-[#E2D3B8] text-[#144032] text-xs font-bold hover:border-[#144032] flex items-center gap-1.5"
            >
              <MapPin className="w-3.5 h-3.5 text-[#C35B3A]" />
              <span>Corridor Map</span>
            </button>
          </div>
        </div>

        {/* Main Content Area */}
        <div className="bg-white rounded-3xl border border-[#E2D3B8] shadow-sm overflow-hidden min-h-[750px] max-w-2xl mx-auto">
          {renderActiveScreen()}
        </div>
      </div>
    </div>
  );
};
