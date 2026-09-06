import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import {
  ShieldCheck,
  CreditCard,
  Smartphone,
  Building,
  Wallet,
  Clock,
  ArrowRight,
  CheckCircle2,
  Lock,
} from 'lucide-react';
import { PaymentMethodType } from '../../types/contracts';

export const BookingCheckout: React.FC = () => {
  const { currentBooking, confirmPayment, isGenerating, navigateTo } = useAppStore();
  const [selectedMethod, setSelectedMethod] = React.useState<PaymentMethodType>('UPI');
  const [secondsRemaining, setSecondsRemaining] = React.useState(15 * 60);

  // 15-minute inventory hold countdown timer
  React.useEffect(() => {
    const timer = setInterval(() => {
      setSecondsRemaining((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formatTimer = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  if (!currentBooking) {
    return (
      <div className="p-8 text-center space-y-4">
        <p className="text-sm text-gray-500">No active checkout session found.</p>
        <button
          onClick={() => navigateTo('HOME')}
          className="px-4 py-2 rounded-xl bg-[#144032] text-white text-xs font-bold"
        >
          Return Home
        </button>
      </div>
    );
  }

  const paymentMethods: { type: PaymentMethodType; label: string; desc: string; icon: React.ReactNode }[] = [
    { type: 'UPI', label: 'UPI Instant', desc: 'Google Pay, PhonePe, Paytm, BHIM', icon: <Smartphone className="w-5 h-5 text-emerald-600" /> },
    { type: 'CREDIT_CARD', label: 'Credit / Debit Card', desc: 'Visa, MasterCard, RuPay, Amex', icon: <CreditCard className="w-5 h-5 text-blue-600" /> },
    { type: 'NET_BANKING', label: 'Net Banking', desc: 'All Indian major banks', icon: <Building className="w-5 h-5 text-purple-600" /> },
    { type: 'WALLET', label: 'Wallets', desc: 'Amazon Pay, Mobikwik', icon: <Wallet className="w-5 h-5 text-amber-600" /> },
    { type: 'PAY_LATER', label: 'Pay Later / EMI', desc: 'No-cost EMI on select cards', icon: <Clock className="w-5 h-5 text-gray-600" /> },
  ];

  const handlePay = () => {
    confirmPayment(selectedMethod);
  };

  return (
    <div className="p-4 space-y-4 pb-12 text-[#1C231E]">
      {/* Top Header */}
      <div className="pt-1">
        <span className="text-[10px] font-bold text-[#6A8F71] uppercase tracking-wider">
          Secure Checkout · 256-Bit SSL
        </span>
        <h2 className="font-serif text-2xl font-bold text-[#144032]">Review & Confirm</h2>
      </div>

      {/* 15-Min Inventory Lock Timer Banner */}
      <div className="p-3 rounded-2xl bg-[#E7EFEA] border border-[#C5D8CD] flex items-center justify-between text-xs">
        <div className="flex items-center gap-2">
          <Clock className="w-4 h-4 text-[#144032] animate-pulse" />
          <span className="text-[#144032] font-semibold">Inventory Held for You</span>
        </div>
        <span className="font-mono font-bold text-[#C35B3A] bg-white px-2 py-0.5 rounded-lg border border-[#E2D3B8]">
          {formatTimer(secondsRemaining)}
        </span>
      </div>

      {/* Trip Details Card */}
      <div className="p-4 rounded-3xl bg-white border border-[#E2D3B8] shadow-sm space-y-2">
        <div className="flex items-center justify-between">
          <h3 className="font-serif text-base font-bold text-[#144032]">{currentBooking.tripTitle}</h3>
          <span className="text-xs font-bold text-[#C35B3A]">
            {currentBooking.travelersCount} Guests
          </span>
        </div>
        <p className="text-xs text-gray-500">
          {currentBooking.startDate} to {currentBooking.endDate} · 6 Days Corridor
        </p>

        <div className="pt-3 border-t border-gray-100">
          <p className="text-[11px] font-bold text-gray-700">Primary Guest</p>
          <p className="text-xs font-semibold text-[#144032]">{currentBooking.primaryGuestName}</p>
          <p className="text-[11px] text-gray-500">{currentBooking.primaryGuestPhone} · {currentBooking.primaryGuestEmail}</p>
        </div>
      </div>

      {/* Payment Method Selector */}
      <div className="space-y-2.5">
        <h3 className="font-serif text-sm font-bold text-[#144032] px-1">Select Payment Method</h3>
        <div className="space-y-2">
          {paymentMethods.map((pm) => {
            const isSelected = selectedMethod === pm.type;
            return (
              <div
                key={pm.type}
                onClick={() => setSelectedMethod(pm.type)}
                className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                  isSelected
                    ? 'bg-white border-[#144032] ring-2 ring-[#144032]/20 shadow-sm'
                    : 'bg-white border-[#E2D3B8] hover:border-gray-400'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-gray-50 border border-gray-100 flex items-center justify-center">
                    {pm.icon}
                  </div>
                  <div>
                    <p className="text-xs font-bold text-[#144032]">{pm.label}</p>
                    <p className="text-[10px] text-gray-500">{pm.desc}</p>
                  </div>
                </div>
                <div
                  className={`w-4 h-4 rounded-full border flex items-center justify-center ${
                    isSelected ? 'border-[#144032] bg-[#144032]' : 'border-gray-300'
                  }`}
                >
                  {isSelected && <div className="w-1.5 h-1.5 rounded-full bg-white" />}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Bottom Payment Button */}
      <div className="pt-4 space-y-2">
        <button
          onClick={handlePay}
          disabled={isGenerating}
          className="w-full py-3.5 rounded-2xl bg-[#144032] text-[#F7F3E8] font-bold text-sm shadow-md hover:bg-[#10352A] transition-all flex items-center justify-center gap-2 transform active:scale-95 disabled:opacity-50"
        >
          <Lock className="w-4 h-4 text-[#D4AF37]" />
          <span>Pay ₹{currentBooking.pricing.total.toLocaleString('en-IN')}</span>
          <ArrowRight className="w-4 h-4" />
        </button>

        <p className="text-[10px] text-gray-400 text-center flex items-center justify-center gap-1">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
          <span>100% Refundable cancellation up to 48 hours prior</span>
        </p>
      </div>
    </div>
  );
};
