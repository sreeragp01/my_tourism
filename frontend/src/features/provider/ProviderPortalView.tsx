import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { httpAdapter } from '../../adapters/httpAdapter';
import { ProviderDashboardMetrics } from '../../types/contracts';
import {
  Building2,
  DollarSign,
  Users,
  Star,
  Calendar,
  Package,
  PlusCircle,
  TrendingUp,
  CheckCircle2,
  Clock,
  ArrowLeft,
} from 'lucide-react';

export const ProviderPortalView: React.FC = () => {
  const { navigateTo, currentUser, showToast } = useAppStore();
  const [metrics, setMetrics] = React.useState<ProviderDashboardMetrics | null>(null);
  const [activeTab, setActiveTab] = React.useState<'OVERVIEW' | 'PRODUCTS' | 'CALENDAR'>('OVERVIEW');

  React.useEffect(() => {
    httpAdapter.getProviderMetrics().then(setMetrics);
  }, []);

  return (
    <div className="p-4 space-y-4 pb-12 text-[#1C231E]">
      {/* Top Provider Header */}
      <div className="flex items-center justify-between pt-1">
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigateTo('HOME')}
            className="p-1.5 rounded-xl bg-white border border-[#E2D3B8] text-[#144032]"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <div>
            <span className="text-[10px] font-bold text-[#D4AF37] uppercase tracking-wider">
              Tourism Provider Ecosystem
            </span>
            <h2 className="font-serif text-xl font-bold text-[#144032]">
              Lockhart Heritage Estate
            </h2>
          </div>
        </div>
        <span className="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold border border-emerald-300">
          Verified Provider
        </span>
      </div>

      {/* Tabs */}
      <div className="flex rounded-2xl bg-[#E9DDC5]/70 p-1 border border-[#E2D3B8]">
        {(['OVERVIEW', 'PRODUCTS', 'CALENDAR'] as const).map((t) => (
          <button
            key={t}
            onClick={() => setActiveTab(t)}
            className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === t ? 'bg-[#144032] text-[#F7F3E8] shadow-md' : 'text-[#144032]'
            }`}
          >
            {t === 'OVERVIEW' ? 'Overview' : t === 'PRODUCTS' ? 'My Products' : 'Live Calendar'}
          </button>
        ))}
      </div>

      {/* TAB 1: OVERVIEW METRICS */}
      {activeTab === 'OVERVIEW' && (
        <div className="space-y-4 animate-in fade-in">
          {/* Revenue KPI Grid */}
          <div className="grid grid-cols-2 gap-2.5">
            <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm">
              <span className="text-[10px] font-bold text-gray-400 uppercase">Today's Revenue</span>
              <p className="font-serif text-xl font-extrabold text-[#144032] mt-0.5">
                ₹{metrics?.todayRevenue.toLocaleString('en-IN')}
              </p>
              <p className="text-[10px] text-emerald-600 font-bold mt-1">+14% vs yesterday</p>
            </div>

            <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm">
              <span className="text-[10px] font-bold text-gray-400 uppercase">Monthly Earnings</span>
              <p className="font-serif text-xl font-extrabold text-[#C35B3A] mt-0.5">
                ₹{metrics?.monthRevenue.toLocaleString('en-IN')}
              </p>
              <p className="text-[10px] text-[#D4AF37] font-bold mt-1">Settled on 1st</p>
            </div>

            <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm">
              <span className="text-[10px] font-bold text-gray-400 uppercase">Occupancy Rate</span>
              <p className="font-serif text-xl font-extrabold text-[#144032] mt-0.5">
                {metrics?.occupancyRatePercent}%
              </p>
              <p className="text-[10px] text-gray-500 mt-1">{metrics?.activeGuests} Active Guests</p>
            </div>

            <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm">
              <span className="text-[10px] font-bold text-gray-400 uppercase">Guest Rating</span>
              <p className="font-serif text-xl font-extrabold text-[#144032] mt-0.5 flex items-center gap-1">
                <Star className="w-4 h-4 fill-[#D4AF37] text-[#D4AF37]" />
                <span>{metrics?.averageRating}</span>
              </p>
              <p className="text-[10px] text-gray-500 mt-1">142 Verified Reviews</p>
            </div>
          </div>

          {/* Recent Bookings Queue */}
          <div className="space-y-2">
            <h3 className="font-serif text-sm font-bold text-[#144032] px-1">Upcoming Guest Arrivals</h3>
            <div className="space-y-2">
              {metrics?.recentBookings.map((b) => (
                <div
                  key={b.id}
                  className="p-3 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm flex items-center justify-between"
                >
                  <div>
                    <h4 className="text-xs font-bold text-[#144032]">{b.guestName}</h4>
                    <p className="text-[10px] text-gray-500">{b.productName} · {b.dates}</p>
                  </div>
                  <div className="text-right">
                    <span className="text-xs font-extrabold text-[#C35B3A] block">
                      ₹{b.amount.toLocaleString('en-IN')}
                    </span>
                    <span className="text-[9px] font-bold text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded border border-emerald-200">
                      {b.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: PRODUCTS */}
      {activeTab === 'PRODUCTS' && (
        <div className="space-y-3 animate-in fade-in">
          <div className="flex items-center justify-between">
            <h3 className="font-serif text-sm font-bold text-[#144032]">Active Listings</h3>
            <button
              onClick={() => showToast('Listing creation modal opened')}
              className="px-3 py-1.5 rounded-xl bg-[#144032] text-[#D4AF37] text-xs font-bold flex items-center gap-1 shadow-sm"
            >
              <PlusCircle className="w-3.5 h-3.5" />
              <span>Add Product</span>
            </button>
          </div>

          <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-bold text-[#6A8F71] uppercase">Experience</span>
              <span className="text-xs font-bold text-emerald-600">Published · Live</span>
            </div>
            <h4 className="text-xs font-bold text-[#144032]">
              Heritage Tea Estate Walk & Tasting with Master Planter
            </h4>
            <div className="flex items-center justify-between text-xs pt-1 border-t border-gray-100">
              <span className="text-gray-500">Slot Capacity: 8 people / slot</span>
              <span className="font-bold text-[#C35B3A]">₹1,200 / person</span>
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: CALENDAR & SLOTS */}
      {activeTab === 'CALENDAR' && (
        <div className="p-4 rounded-3xl bg-white border border-[#E2D3B8] shadow-sm space-y-3 animate-in fade-in">
          <div className="flex items-center justify-between">
            <h3 className="font-serif text-sm font-bold text-[#144032]">Live Slot Management</h3>
            <span className="text-[10px] text-gray-500 font-mono">June 2026</span>
          </div>

          <div className="space-y-2 text-xs">
            <div className="p-2.5 rounded-xl bg-[#FAF5EA] border border-[#E2D3B8] flex items-center justify-between">
              <div>
                <p className="font-bold text-[#144032]">Morning Slot (09:00 - 11:30)</p>
                <p className="text-[10px] text-gray-500">6 of 8 seats booked</p>
              </div>
              <span className="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold">
                Available
              </span>
            </div>

            <div className="p-2.5 rounded-xl bg-[#FAF5EA] border border-[#E2D3B8] flex items-center justify-between">
              <div>
                <p className="font-bold text-[#144032]">Afternoon Slot (14:30 - 17:00)</p>
                <p className="text-[10px] text-gray-500">8 of 8 seats booked</p>
              </div>
              <span className="px-2 py-0.5 rounded-full bg-rose-100 text-rose-800 text-[10px] font-bold">
                Sold Out
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
