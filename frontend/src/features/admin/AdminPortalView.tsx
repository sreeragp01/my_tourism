import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { mockBackend } from '../../adapters/mockAdapter';
import { AdminKPIs } from '../../types/contracts';
import {
  ShieldAlert,
  Users,
  Building2,
  Briefcase,
  TrendingUp,
  Sparkles,
  CheckCircle2,
  XCircle,
  ArrowLeft,
  FileCheck,
} from 'lucide-react';

export const AdminPortalView: React.FC = () => {
  const { navigateTo, showToast } = useAppStore();
  const [kpis, setKpis] = React.useState<AdminKPIs | null>(null);
  const [pendingQueue, setPendingQueue] = React.useState([
    { id: 'req-1', name: 'Kumarakom Canoe Guild', district: 'Kottayam', type: 'EXPERIENCE_HOST', docs: 'Verified Govt Boat License' },
    { id: 'req-2', name: 'Marari Beachfront Eco Homestay', district: 'Alappuzha', type: 'HOMESTAY', docs: 'Kerala Tourism Class-A Certificate' },
  ]);

  React.useEffect(() => {
    mockBackend.getAdminKPIs().then(setKpis);
  }, []);

  const handleApprove = (id: string, name: string) => {
    setPendingQueue(pendingQueue.filter((p) => p.id !== id));
    showToast(`✅ Provider "${name}" approved & verified!`);
  };

  return (
    <div className="p-4 space-y-4 pb-12 text-[#1C231E]">
      {/* Top Admin Header */}
      <div className="flex items-center justify-between pt-1">
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigateTo('HOME')}
            className="p-1.5 rounded-xl bg-white border border-[#E2D3B8] text-[#144032]"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <div>
            <span className="text-[10px] font-bold text-rose-600 uppercase tracking-wider">
              Central Command · Super Admin
            </span>
            <h2 className="font-serif text-xl font-bold text-[#144032]">
              KeraLink Platform Control
            </h2>
          </div>
        </div>
      </div>

      {/* Global Platform KPIs */}
      <div className="grid grid-cols-2 gap-2.5">
        <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm">
          <span className="text-[10px] font-bold text-gray-400 uppercase">Gross Platform GMV</span>
          <p className="font-serif text-xl font-extrabold text-[#144032] mt-0.5">
            ₹2.84 Cr
          </p>
          <p className="text-[10px] text-emerald-600 font-bold mt-1">+28% YoY</p>
        </div>

        <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm">
          <span className="text-[10px] font-bold text-gray-400 uppercase">Total Bookings</span>
          <p className="font-serif text-xl font-extrabold text-[#C35B3A] mt-0.5">
            {kpis?.totalBookings.toLocaleString('en-IN')}
          </p>
          <p className="text-[10px] text-[#D4AF37] font-bold mt-1">1,280 Active Today</p>
        </div>

        <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm">
          <span className="text-[10px] font-bold text-gray-400 uppercase">Registered Tourists</span>
          <p className="font-serif text-xl font-extrabold text-[#144032] mt-0.5">
            {kpis?.totalUsers.toLocaleString('en-IN')}
          </p>
          <p className="text-[10px] text-gray-500 mt-1">642 Verified Providers</p>
        </div>

        <div className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm">
          <span className="text-[10px] font-bold text-gray-400 uppercase">AI Conversion</span>
          <p className="font-serif text-xl font-extrabold text-emerald-700 mt-0.5 flex items-center gap-1">
            <Sparkles className="w-4 h-4 text-[#D4AF37]" />
            <span>{kpis?.aiToBookingConversionRate}%</span>
          </p>
          <p className="text-[10px] text-gray-500 mt-1">{kpis?.aiTripsCreated.toLocaleString()} Plans Generated</p>
        </div>
      </div>

      {/* Provider Verification Queue */}
      <div className="space-y-3">
        <div className="flex items-center justify-between px-1">
          <h3 className="font-serif text-sm font-bold text-[#144032]">
            Provider Verification Queue ({pendingQueue.length})
          </h3>
          <span className="text-[10px] text-gray-500 font-mono font-bold">Priority: High</span>
        </div>

        {pendingQueue.length === 0 ? (
          <div className="p-4 text-center rounded-2xl bg-white border border-[#E2D3B8] text-xs text-gray-500">
            All provider verification requests have been cleared.
          </div>
        ) : (
          pendingQueue.map((req) => (
            <div
              key={req.id}
              className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm space-y-2"
            >
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-bold text-[#6A8F71] uppercase">{req.type}</span>
                <span className="text-[10px] text-gray-500 font-mono">{req.district}</span>
              </div>
              <h4 className="text-xs font-bold text-[#144032]">{req.name}</h4>
              <p className="text-[11px] text-gray-600 flex items-center gap-1 font-mono">
                <FileCheck className="w-3.5 h-3.5 text-emerald-600" />
                <span>{req.docs}</span>
              </p>

              <div className="grid grid-cols-2 gap-2 pt-2 border-t border-gray-100">
                <button
                  onClick={() => handleApprove(req.id, req.name)}
                  className="py-1.5 rounded-xl bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 transition-colors flex items-center justify-center gap-1 shadow-xs"
                >
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span>Verify & Publish</span>
                </button>
                <button
                  onClick={() => {
                    setPendingQueue(pendingQueue.filter((p) => p.id !== req.id));
                    showToast('Provider application rejected / flagged for audit');
                  }}
                  className="py-1.5 rounded-xl bg-gray-100 text-gray-700 text-xs font-semibold hover:bg-gray-200 transition-colors"
                >
                  Reject / Request Info
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Immutable Audit Log Stream */}
      <div className="p-4 rounded-3xl bg-white border border-[#E2D3B8] shadow-sm space-y-2 text-xs">
        <h3 className="font-serif text-sm font-bold text-[#144032]">Immutable Security Audit Log</h3>
        <div className="space-y-1.5 font-mono text-[10px] text-gray-600">
          <p className="p-1.5 rounded bg-gray-50 border border-gray-100">
            [15:42:01] AUTH_ROTATE: Session sess-chrome-win rotated refresh token hash.
          </p>
          <p className="p-1.5 rounded bg-gray-50 border border-gray-100">
            [15:40:12] INVENTORY_HOLD: Booking KL24062012345 locked Fragrant Nature Suite for 15 mins.
          </p>
          <p className="p-1.5 rounded bg-gray-50 border border-gray-100">
            [15:38:45] RAZORPAY_WEBHOOK: Verified HMAC signature for ₹68,450. Status: CONFIRMED.
          </p>
        </div>
      </div>
    </div>
  );
};
