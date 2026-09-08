import React from 'react';
import { useAppStore, ScreenId } from '../../stores/useAppStore';
import { UserRole } from '../../types/contracts';
import {
  Compass,
  Sparkles,
  Smartphone,
  Monitor,
  ShieldCheck,
  Building2,
  Lock,
  Menu,
  X,
  PhoneCall,
} from 'lucide-react';

export const Navbar: React.FC = () => {
  const {
    viewMode,
    setViewMode,
    activeScreen,
    navigateTo,
    currentUser,
    currentRole,
    switchRole,
    isBackendOnline,
    checkBackendHealth,
  } = useAppStore();

  const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false);
  const [roleDropdownOpen, setRoleDropdownOpen] = React.useState(false);

  React.useEffect(() => {
    checkBackendHealth();
  }, [checkBackendHealth]);

  const navItems: { label: string; screen: ScreenId; icon: React.ReactNode }[] = [
    { label: 'Discover', screen: 'HOME', icon: <Compass className="w-4 h-4" /> },
    { label: 'Explore Kerala', screen: 'EXPLORE', icon: <Compass className="w-4 h-4" /> },
    { label: 'Tourism Map', screen: 'MAP', icon: <Compass className="w-4 h-4" /> },
    { label: 'AI Trip Architect', screen: 'AI_PLANNER', icon: <Sparkles className="w-4 h-4 text-gold-DEFAULT" /> },
    { label: 'Live Companion', screen: 'COMPANION', icon: <Sparkles className="w-4 h-4 text-emerald-400" /> },
    { label: 'Safety & Help', screen: 'SAFETY', icon: <ShieldCheck className="w-4 h-4 text-rose-400" /> },
  ];

  const roles: { role: UserRole; label: string; icon: React.ReactNode }[] = [
    { role: 'CUSTOMER', label: 'Tourist / Traveler', icon: <Compass className="w-4 h-4 text-sage-light" /> },
    { role: 'PROVIDER_OWNER', label: 'Tourism Provider (Resorts & Guides)', icon: <Building2 className="w-4 h-4 text-gold-DEFAULT" /> },
    { role: 'SUPER_ADMIN', label: 'Platform Super Admin', icon: <Lock className="w-4 h-4 text-terracotta-light" /> },
  ];

  return (
    <header className="sticky top-0 z-50 bg-[#0F2823]/95 backdrop-blur-md border-b border-[#D4AF37]/20 text-[#F7F3E8] transition-all">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Brand Logo & Tagline */}
        <div
          onClick={() => navigateTo('LANDING')}
          className="flex items-center gap-3 cursor-pointer group"
        >
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#144032] to-[#1A5340] border border-[#D4AF37]/40 flex items-center justify-center shadow-gold group-hover:scale-105 transition-transform">
            <span className="text-xl">🌴</span>
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-serif text-2xl font-bold tracking-tight text-[#F7F3E8]">KeraLink</span>
              <span className="px-1.5 py-0.5 rounded text-[10px] uppercase font-bold tracking-wider bg-[#D4AF37]/20 text-[#D4AF37] border border-[#D4AF37]/30">
                AI 2.0
              </span>
            </div>
            <p className="text-[11px] text-[#C5D8CD] tracking-wider uppercase font-medium hidden sm:block">
              Your Kerala. Your Way.
            </p>
          </div>
        </div>

        {/* Desktop Navigation Links */}
        <nav className="hidden lg:flex items-center gap-1">
          {navItems.map((item) => {
            const isActive = activeScreen === item.screen;
            return (
              <button
                key={item.screen}
                onClick={() => navigateTo(item.screen)}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-all flex items-center gap-1.5 ${
                  isActive
                    ? 'bg-[#144032] text-[#D4AF37] border border-[#D4AF37]/30 shadow-sm'
                    : 'text-[#E7EFEA] hover:bg-[#144032]/60 hover:text-white'
                }`}
              >
                {item.icon}
                {item.label}
              </button>
            );
          })}
        </nav>

        {/* Action Controls: Presentation Mode, Role Switcher & Live API Status */}
        <div className="flex items-center gap-2.5">
          {/* Live Backend Connection Indicator */}
          <button
            onClick={() => checkBackendHealth()}
            title="Django Backend API Status (Click to ping http://localhost:8000)"
            className={`hidden sm:flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold border transition-all ${
              isBackendOnline === true
                ? 'bg-emerald-950/70 text-emerald-300 border-emerald-500/40 shadow-sm shadow-emerald-950'
                : isBackendOnline === false
                ? 'bg-amber-950/60 text-amber-300 border-amber-500/40'
                : 'bg-[#144032] text-[#C5D8CD] border-[#D4AF37]/20'
            }`}
          >
            <span
              className={`w-2 h-2 rounded-full ${
                isBackendOnline === true
                  ? 'bg-emerald-400 animate-pulse'
                  : isBackendOnline === false
                  ? 'bg-amber-400'
                  : 'bg-gray-400'
              }`}
            />
            <span>
              {isBackendOnline === true
                ? 'API: Online'
                : isBackendOnline === false
                ? 'API: Sandbox'
                : 'API: Connecting...'}
            </span>
          </button>

          {/* View Mode Toggle Switcher */}
          <div className="bg-[#144032] border border-[#D4AF37]/30 rounded-lg p-0.5 flex items-center shadow-inner">
            <button
              onClick={() => setViewMode('DEVICE_FRAME')}
              title="Switch to Mobile App Prototype Frame (Matches Design Board)"
              className={`flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-semibold transition-all ${
                viewMode === 'DEVICE_FRAME'
                  ? 'bg-[#D4AF37] text-[#0F2823] shadow'
                  : 'text-[#C5D8CD] hover:text-white'
              }`}
            >
              <Smartphone className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Mobile Prototype</span>
            </button>
            <button
              onClick={() => setViewMode('WEB')}
              title="Switch to Full Responsive Web Platform"
              className={`flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-semibold transition-all ${
                viewMode === 'WEB'
                  ? 'bg-[#D4AF37] text-[#0F2823] shadow'
                  : 'text-[#C5D8CD] hover:text-white'
              }`}
            >
              <Monitor className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Web Platform</span>
            </button>
          </div>

          {/* Persona / RBAC Switcher Dropdown */}
          <div className="relative">
            <button
              onClick={() => setRoleDropdownOpen(!roleDropdownOpen)}
              className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[#144032] border border-[#D4AF37]/30 text-xs font-semibold hover:border-[#D4AF37] transition-all"
            >
              <div className="w-5 h-5 rounded-full bg-[#D4AF37]/20 flex items-center justify-center text-xs text-[#D4AF37]">
                {currentRole === 'CUSTOMER' ? '👤' : currentRole.startsWith('PROVIDER') ? '🏨' : '⚡'}
              </div>
              <span className="hidden md:inline text-[#F7F3E8]">
                {currentRole === 'CUSTOMER'
                  ? 'Tourist'
                  : currentRole.startsWith('PROVIDER')
                  ? 'Provider Portal'
                  : 'Admin'}
              </span>
            </button>

            {roleDropdownOpen && (
              <div className="absolute right-0 mt-2 w-64 bg-[#0F2823] border border-[#D4AF37]/40 rounded-xl shadow-2xl p-2 z-50 animate-in fade-in zoom-in-95">
                <div className="px-3 py-2 border-b border-white/10 mb-1">
                  <p className="text-[11px] font-bold uppercase tracking-wider text-[#D4AF37]">Switch Persona / RBAC</p>
                  <p className="text-xs text-[#C5D8CD]">Simulate multi-tenant platform roles</p>
                </div>
                {roles.map((r) => (
                  <button
                    key={r.role}
                    onClick={() => {
                      switchRole(r.role);
                      setRoleDropdownOpen(false);
                    }}
                    className={`w-full text-left px-3 py-2 rounded-lg text-xs font-medium flex items-center gap-2 transition-all ${
                      currentRole === r.role
                        ? 'bg-[#144032] text-[#D4AF37] border border-[#D4AF37]/30'
                        : 'text-[#E7EFEA] hover:bg-[#144032]/60'
                    }`}
                  >
                    {r.icon}
                    {r.label}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Mobile menu hamburger toggle */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="lg:hidden p-1.5 rounded-lg text-[#E7EFEA] hover:bg-[#144032]"
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </div>

      {/* Mobile navigation drawer */}
      {mobileMenuOpen && (
        <div className="lg:hidden bg-[#0F2823] border-b border-[#D4AF37]/20 px-4 py-3 space-y-2">
          {navItems.map((item) => (
            <button
              key={item.screen}
              onClick={() => {
                navigateTo(item.screen);
                setMobileMenuOpen(false);
              }}
              className="w-full text-left px-3 py-2 rounded-lg text-sm font-medium text-[#E7EFEA] hover:bg-[#144032] flex items-center gap-2"
            >
              {item.icon}
              {item.label}
            </button>
          ))}
        </div>
      )}
    </header>
  );
};
