import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { Briefcase, Calendar, MapPin, QrCode, Leaf, ArrowRight, Sparkles } from 'lucide-react';

export const MyTripsView: React.FC = () => {
  const { myBookings, currentPlan, navigateTo, setCurrentBooking } = useAppStore();
  const [tab, setTab] = React.useState<'UPCOMING' | 'COMPLETED'>('UPCOMING');

  const upcomingTrips = myBookings.length > 0 ? myBookings : [
    {
      id: 'demo-bkg-1',
      bookingReference: 'KL24062012345',
      tripTitle: '6 Days Romantic Kerala Nature Escape',
      startDate: '2026-06-20',
      endDate: '2026-06-25',
      travelersCount: 2,
      pricing: { total: 68450 } as any,
      status: 'CONFIRMED' as any,
      greenTripScore: 88,
      qrCodeDataUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=KERALINK-KL24062012345',
      userId: 'usr-sreerag-01',
      primaryGuestName: 'Sreerag P',
      primaryGuestPhone: '+91 98460 12345',
      primaryGuestEmail: 'sreerag@keralink.travel',
      items: [],
      idempotencyKey: 'IDEMP-1',
      createdAt: '2026-06-01T10:00:00Z',
    },
    {
      id: 'demo-bkg-2',
      bookingReference: 'KL24081098234',
      tripTitle: '4 Days Wayanad Mist & Cave Adventure',
      startDate: '2026-08-10',
      endDate: '2026-08-14',
      travelersCount: 2,
      pricing: { total: 32000 } as any,
      status: 'CONFIRMED' as any,
      greenTripScore: 94,
      qrCodeDataUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=KERALINK-KL24081098234',
      userId: 'usr-sreerag-01',
      primaryGuestName: 'Sreerag P',
      primaryGuestPhone: '+91 98460 12345',
      primaryGuestEmail: 'sreerag@keralink.travel',
      items: [],
      idempotencyKey: 'IDEMP-2',
      createdAt: '2026-06-01T10:00:00Z',
    }
  ];

  return (
    <div className="p-4 space-y-4 pb-12 text-[#1C231E]">
      {/* Top Header */}
      <div className="flex items-center justify-between pt-1">
        <div>
          <span className="text-[10px] font-bold text-[#6A8F71] uppercase tracking-wider">
            Travel Passports
          </span>
          <h2 className="font-serif text-2xl font-bold text-[#144032]">My Trips</h2>
        </div>
        <button
          onClick={() => navigateTo('AI_PLANNER')}
          className="px-3 py-1.5 rounded-xl bg-[#144032] text-[#D4AF37] text-xs font-bold shadow-sm flex items-center gap-1"
        >
          <Sparkles className="w-3.5 h-3.5" />
          <span>New AI Trip</span>
        </button>
      </div>

      {/* Tabs */}
      <div className="flex rounded-2xl bg-[#E9DDC5]/70 p-1 border border-[#E2D3B8]">
        <button
          onClick={() => setTab('UPCOMING')}
          className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
            tab === 'UPCOMING' ? 'bg-[#144032] text-[#F7F3E8] shadow-md' : 'text-[#144032]'
          }`}
        >
          Upcoming ({upcomingTrips.length})
        </button>
        <button
          onClick={() => setTab('COMPLETED')}
          className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
            tab === 'COMPLETED' ? 'bg-[#144032] text-[#F7F3E8] shadow-md' : 'text-[#144032]'
          }`}
        >
          Completed (1)
        </button>
      </div>

      {/* Trip Cards Stream */}
      {tab === 'UPCOMING' && (
        <div className="space-y-4 animate-in fade-in">
          {upcomingTrips.map((trip) => (
            <div
              key={trip.id}
              className="bg-white rounded-3xl overflow-hidden border border-[#E2D3B8] shadow-sm hover:shadow-md transition-all group"
            >
              <div className="relative h-32 overflow-hidden">
                <img
                  src="https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=600&q=80"
                  alt="Trip Hero"
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
                <div className="absolute top-3 left-3 px-2.5 py-0.5 rounded-full bg-emerald-700 text-white text-[10px] font-bold">
                  Confirmed
                </div>
                <div className="absolute top-3 right-3 px-2 py-0.5 rounded-full bg-black/60 backdrop-blur-md text-[#D4AF37] font-mono text-[10px] font-bold">
                  {trip.bookingReference}
                </div>
              </div>

              <div className="p-4 space-y-3">
                <div>
                  <h3 className="font-serif text-base font-bold text-[#144032]">{trip.tripTitle}</h3>
                  <p className="text-xs text-gray-500 flex items-center gap-1.5 mt-1">
                    <Calendar className="w-3.5 h-3.5 text-gray-400" />
                    <span>{trip.startDate} - {trip.endDate}</span>
                    <span>·</span>
                    <span>{trip.travelersCount} Guests</span>
                  </p>
                </div>

                <div className="flex items-center justify-between pt-2 border-t border-gray-100">
                  <div className="flex items-center gap-1 text-[11px] font-bold text-emerald-700">
                    <Leaf className="w-3.5 h-3.5" />
                    <span>Green Score: {trip.greenTripScore}/100</span>
                  </div>
                  <span className="font-serif text-sm font-bold text-[#C35B3A]">
                    ₹{trip.pricing.total.toLocaleString('en-IN')}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-2 pt-1">
                  <button
                    onClick={() => {
                      setCurrentBooking(trip as any);
                      navigateTo('BOOKING_CONFIRMED');
                    }}
                    className="py-2 rounded-xl bg-[#FAF5EA] border border-[#D4AF37]/50 text-[#144032] text-xs font-bold flex items-center justify-center gap-1.5 hover:bg-[#E9DDC5]"
                  >
                    <QrCode className="w-3.5 h-3.5 text-[#D4AF37]" />
                    <span>QR Pass</span>
                  </button>
                  <button
                    onClick={() => navigateTo('COMPANION')}
                    className="py-2 rounded-xl bg-[#144032] text-white text-xs font-bold flex items-center justify-center gap-1.5 hover:bg-[#10352A]"
                  >
                    <span>Trip Assistant</span>
                    <ArrowRight className="w-3 h-3" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {tab === 'COMPLETED' && (
        <div className="p-6 text-center space-y-2 bg-white rounded-3xl border border-[#E2D3B8]">
          <span className="text-3xl">🌴</span>
          <h4 className="font-serif text-base font-bold text-[#144032]">Fort Kochi Art & Food Trail</h4>
          <p className="text-xs text-gray-500">Completed in March 2026 · 4.9 ★ Rating given</p>
          <button
            onClick={() => navigateTo('AI_PLANNER')}
            className="mt-2 px-4 py-2 rounded-xl bg-[#144032] text-white text-xs font-bold"
          >
            Re-book This Trip
          </button>
        </div>
      )}
    </div>
  );
};
