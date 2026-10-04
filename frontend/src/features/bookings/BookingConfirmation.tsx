import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { CheckCircle2, QrCode, Download, Share2, Compass, Leaf, ArrowRight } from 'lucide-react';
import confetti from 'canvas-confetti';

export const BookingConfirmation: React.FC = () => {
  const { currentBooking, navigateTo } = useAppStore();

  React.useEffect(() => {
    // Launch celebratory confetti burst
    try {
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 },
        colors: ['#D4AF37', '#144032', '#C35B3A', '#6A8F71'],
      });
    } catch (e) {
      // ignore
    }
  }, []);

  if (!currentBooking) {
    return (
      <div className="p-8 text-center space-y-4">
        <p className="text-sm text-gray-500">No confirmed booking found.</p>
        <button
          onClick={() => navigateTo('HOME')}
          className="px-4 py-2 rounded-xl bg-[#144032] text-white text-xs font-bold"
        >
          Return Home
        </button>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-5 pb-12 text-[#1C231E] text-center">
      {/* Top Confirmed Badge */}
      <div className="pt-2">
        <div className="w-16 h-16 mx-auto rounded-full bg-emerald-100 border-2 border-emerald-500 text-emerald-700 flex items-center justify-center shadow-lg animate-bounce">
          <CheckCircle2 className="w-8 h-8" />
        </div>
        <h2 className="font-serif text-3xl font-extrabold text-[#144032] mt-3">
          Booking Confirmed! 🎉
        </h2>
        <p className="text-xs text-[#6A8F71] font-medium mt-1">
          Your God's Own Country journey is all set.
        </p>
      </div>

      {/* Center Scenic Digital Boarding Ticket Pass */}
      <div className="rounded-3xl bg-white border-2 border-[#D4AF37]/40 shadow-xl overflow-hidden text-left relative">
        {/* Top Image Banner */}
        <div className="relative h-32">
          <img
            src="https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=600&q=80"
            alt="Kerala Houseboat"
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent flex items-end p-3">
            <span className="text-xs font-bold text-white font-serif">{currentBooking.tripTitle}</span>
          </div>
        </div>

        {/* Perforated ticket notched border */}
        <div className="p-4 space-y-3 bg-[#FAF5EA]">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-[10px] text-gray-500 uppercase font-bold">Booking Reference</p>
              <p className="font-mono text-base font-extrabold text-[#144032] tracking-wider">
                {currentBooking.bookingReference}
              </p>
            </div>
            <div className="text-right">
              <p className="text-[10px] text-gray-500 uppercase font-bold">Total Paid</p>
              <p className="font-serif text-base font-extrabold text-[#C35B3A]">
                ₹{currentBooking.pricing.total.toLocaleString('en-IN')}
              </p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2 text-xs border-t border-b border-[#E2D3B8] py-2">
            <div>
              <p className="text-[10px] text-gray-400">Primary Guest</p>
              <p className="font-bold text-gray-800 truncate">{currentBooking.primaryGuestName}</p>
            </div>
            <div>
              <p className="text-[10px] text-gray-400">Travel Dates</p>
              <p className="font-bold text-gray-800">{currentBooking.startDate}</p>
            </div>
          </div>

          {/* QR Code Section */}
          <div className="flex items-center gap-3 pt-1">
            <div className="w-20 h-20 bg-white p-1 rounded-xl border border-gray-300 shadow-inner flex items-center justify-center">
              <img
                src={currentBooking.qrCodeDataUrl}
                alt="QR Code"
                className="w-full h-full object-contain"
              />
            </div>
            <div className="text-xs space-y-1 flex-1">
              <p className="text-[11px] font-bold text-[#144032]">Digital Itinerary Pass</p>
              <p className="text-[10px] text-gray-500 leading-tight">
                Scan at hotel check-ins and private houseboat boarding.
              </p>
              <div className="flex items-center gap-1 text-[10px] font-bold text-emerald-700">
                <Leaf className="w-3 h-3" />
                <span>Green Score: {currentBooking.greenTripScore}/100</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <p className="text-xs text-gray-500">
        A confirmation voucher & tax invoice has been emailed to{' '}
        <span className="font-bold text-gray-700">{currentBooking.primaryGuestEmail}</span>.
      </p>

      {/* Action Buttons */}
      <div className="space-y-2 pt-2">
        <button
          onClick={() => navigateTo('COMPANION')}
          className="w-full py-3 rounded-2xl bg-[#144032] text-[#F7F3E8] text-xs font-bold shadow-md hover:bg-[#10352A] transition-all flex items-center justify-center gap-2"
        >
          <Compass className="w-4 h-4 text-[#D4AF37]" />
          <span>Launch Live Trip Companion</span>
        </button>

        <button
          onClick={() => navigateTo('HOME')}
          className="w-full py-2.5 rounded-2xl bg-white border border-[#E2D3B8] text-xs font-bold text-gray-700 hover:border-[#144032]"
        >
          Return to Home
        </button>
      </div>
    </div>
  );
};
