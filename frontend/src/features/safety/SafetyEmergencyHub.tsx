import React from 'react';
import { useAppStore } from '../../stores/useAppStore';
import { KERALA_EMERGENCY_CONTACTS } from '../../data/keralaData';
import { ShieldCheck, PhoneCall, AlertTriangle, Hospital, Shield, ArrowLeft } from 'lucide-react';

export const SafetyEmergencyHub: React.FC = () => {
  const { navigateTo } = useAppStore();

  return (
    <div className="p-4 space-y-4 pb-12 text-[#1C231E]">
      {/* Top Header */}
      <div className="flex items-center gap-2 pt-1">
        <button
          onClick={() => navigateTo('HOME')}
          className="p-1.5 rounded-xl bg-white border border-[#E2D3B8] text-[#144032]"
        >
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <span className="text-[10px] font-bold text-rose-600 uppercase tracking-wider">
            24x7 Verified Directory
          </span>
          <h2 className="font-serif text-2xl font-bold text-[#144032]">
            Safety & Emergency Hub
          </h2>
        </div>
      </div>

      {/* SOS Immediate Emergency Banner */}
      <div className="p-4 rounded-3xl bg-gradient-to-br from-rose-900 to-rose-950 text-white shadow-xl border border-rose-500/30 space-y-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-rose-300 font-bold text-xs">
            <AlertTriangle className="w-4 h-4 text-rose-400 animate-pulse" />
            <span>Emergency Police & Rescue</span>
          </div>
          <span className="text-[10px] px-2 py-0.5 rounded-full bg-rose-800 text-rose-200">
            Toll Free
          </span>
        </div>
        <p className="font-serif text-3xl font-extrabold text-white tracking-widest">
          112
        </p>
        <p className="text-[11px] text-rose-200">
          Statewide immediate dispatch for Police, Medical & Fire rescue services across all 14 Kerala districts.
        </p>
      </div>

      {/* Verified Tourist Helplines */}
      <div className="space-y-3">
        <h3 className="font-serif text-sm font-bold text-[#144032] px-1">
          Government Tourist Helplines
        </h3>

        {KERALA_EMERGENCY_CONTACTS.map((c) => (
          <div
            key={c.name}
            className="p-3.5 rounded-2xl bg-white border border-[#E2D3B8] shadow-sm flex items-center justify-between hover:border-[#144032] transition-all"
          >
            <div className="space-y-0.5">
              <span className="text-[9px] font-bold text-[#6A8F71] uppercase">
                {c.category.replace('_', ' ')}
              </span>
              <h4 className="text-xs font-bold text-[#144032]">{c.name}</h4>
              <p className="text-[10px] text-gray-500">{c.availableHours}</p>
            </div>
            <a
              href={`tel:${c.phone.replace(/[^0-9+]/g, '')}`}
              className="px-3 py-2 rounded-xl bg-emerald-50 text-emerald-700 border border-emerald-300 text-xs font-bold flex items-center gap-1.5 hover:bg-emerald-100 transition-colors shadow-xs"
            >
              <PhoneCall className="w-3.5 h-3.5" />
              <span>{c.phone}</span>
            </a>
          </div>
        ))}
      </div>

      {/* Monsoon Travel Road Advisory */}
      <div className="p-4 rounded-3xl bg-[#FAF5EA] border border-[#D4AF37]/40 space-y-2">
        <div className="flex items-center gap-2 text-xs font-bold text-[#144032]">
          <Shield className="w-4 h-4 text-[#D4AF37]" />
          <span>Active Monsoon Safety Advisory</span>
        </div>
        <p className="text-[11px] text-gray-600 leading-relaxed">
          Ghat roads between Kochi and Munnar (NH85) are clear and operational. During heavy rains, drive speeds are monitored by KeraLink AI to recommend safe scenic halts.
        </p>
      </div>
    </div>
  );
};
