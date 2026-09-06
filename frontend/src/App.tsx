import React from 'react';
import { useAppStore } from './stores/useAppStore';
import { Navbar } from './components/common/Navbar';
import { DeviceFrame } from './components/layout/DeviceFrame';
import { WebPlatformLayout } from './features/web/WebPlatformLayout';
import { LandingHero } from './features/discovery/LandingHero';
import { OnboardingFlow } from './features/discovery/OnboardingFlow';
import { HomeDiscover } from './features/home/HomeDiscover';
import { ExploreKerala } from './features/discovery/ExploreKerala';
import { KeralaMapView } from './features/discovery/KeralaMapView';
import { AIPlannerFlow } from './features/ai-planner/AIPlannerFlow';
import { AIGenerationScreen } from './features/ai-planner/AIGenerationScreen';
import { ItineraryDetailsView } from './features/itinerary/ItineraryDetailsView';
import { BookingCheckout } from './features/bookings/BookingCheckout';
import { BookingConfirmation } from './features/bookings/BookingConfirmation';
import { LiveCompanionView } from './features/companion/LiveCompanionView';
import { SafetyEmergencyHub } from './features/safety/SafetyEmergencyHub';
import { MyTripsView } from './features/trips/MyTripsView';
import { ProviderPortalView } from './features/provider/ProviderPortalView';
import { AdminPortalView } from './features/admin/AdminPortalView';
import { ExperienceModal } from './components/common/ExperienceModal';
import { AccommodationModal } from './components/common/AccommodationModal';
import { DestinationModal } from './components/common/DestinationModal';
import { CheckCircle2, AlertCircle } from 'lucide-react';

export function App() {
  const {
    viewMode,
    activeScreen,
    loadInitialData,
    toastMessage,
    hideToast,
  } = useAppStore();

  React.useEffect(() => {
    loadInitialData();
  }, [loadInitialData]);

  const renderActiveScreen = () => {
    switch (activeScreen) {
      case 'LANDING':
        return <LandingHero />;
      case 'ONBOARDING':
        return <OnboardingFlow />;
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
    <div className="min-h-screen flex flex-col bg-[#0A1D19] font-sans selection:bg-[#144032] selection:text-[#D4AF37]">
      {/* Top Universal Navbar */}
      <Navbar />

      {/* Main Presentation View */}
      <main className="flex-1">
        {viewMode === 'DEVICE_FRAME' ? (
          <DeviceFrame>{renderActiveScreen()}</DeviceFrame>
        ) : (
          <WebPlatformLayout />
        )}
      </main>

      {/* Global Interactive Modals */}
      <ExperienceModal />
      <AccommodationModal />
      <DestinationModal />

      {/* Toast Notification Alert */}
      {toastMessage && (
        <div className="fixed bottom-6 right-6 z-50 animate-in slide-in-from-bottom-5">
          <div className="bg-[#0F2823] text-[#F7F3E8] border border-[#D4AF37]/50 px-4 py-3 rounded-2xl shadow-2xl flex items-center gap-3">
            <CheckCircle2 className="w-5 h-5 text-[#D4AF37] shrink-0" />
            <p className="text-xs font-semibold">{toastMessage}</p>
            <button
              onClick={hideToast}
              className="text-gray-400 hover:text-white text-sm font-bold ml-2"
            >
              ✕
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
