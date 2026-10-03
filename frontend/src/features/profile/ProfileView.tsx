import React, { useState, useEffect } from 'react';
import { useAppStore } from '../../stores/useAppStore';
import {
  User,
  Shield,
  Phone,
  Mail,
  Heart,
  Compass,
  Download,
  CheckCircle2,
  AlertTriangle,
  Award,
  Leaf,
  Zap,
  Globe,
  Edit3,
  Save,
  X,
  LogOut,
  ChevronRight,
  ExternalLink,
  Loader2,
} from 'lucide-react';

export const ProfileView: React.FC = () => {
  const { currentUser, navigateTo, showToast, updateUserProfile } = useAppStore();

  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [firstName, setFirstName] = useState(currentUser?.firstName || 'Sreerag');
  const [lastName, setLastName] = useState(currentUser?.lastName || 'P.');
  const [phone, setPhone] = useState(currentUser?.phone || '+91 98765 43210');
  const [email] = useState(currentUser?.email || 'sreerag@keralink.travel');

  // ICE (In Case of Emergency) details
  const [iceName, setIceName] = useState(currentUser?.profile?.emergencyContactName || 'Ananya S. (Sister)');
  const [icePhone, setIcePhone] = useState(currentUser?.profile?.emergencyContactPhone || '+91 94471 23456');
  const [bloodGroup, setBloodGroup] = useState(currentUser?.profile?.bloodGroup || 'O+ Positive');
  const [medicalNotes, setMedicalNotes] = useState(currentUser?.profile?.medicalNotes || 'No major allergies. Carries mild asthma inhaler.');

  // AI Planner Personalization
  const [dietaryPref, setDietaryPref] = useState(currentUser?.profile?.dietaryPreference || 'Traditional Kerala Sadya (Veg)');
  const [travelPace, setTravelPace] = useState(currentUser?.profile?.travelPace || 'Balanced (2-3 stops/day)');
  const [accessibility, setAccessibility] = useState(currentUser?.profile?.accessibilityRequired ?? false);

  // Offline Ghat Corridors
  const [offlinePackages, setOfflinePackages] = useState(
    currentUser?.profile?.offlinePackages && currentUser.profile.offlinePackages.length > 0
      ? currentUser.profile.offlinePackages
      : [
          {
            id: 'pkg_munnar',
            name: 'Munnar & Lockhart Valley Corridor',
            size: '42 MB',
            isDownloaded: true,
            includes: 'Ghat topo route, offline SOS checkpoints, nearest CHC clinics',
          },
          {
            id: 'pkg_wayanad',
            name: 'Wayanad Ghat & Forest Pass',
            size: '38 MB',
            isDownloaded: false,
            includes: 'Thamarassery Churam hairpin map, wildlife sanctuary emergency contacts',
          },
        ]
  );

  const [selectedLanguage, setSelectedLanguage] = useState('English (EN)');

  useEffect(() => {
    if (currentUser) {
      setFirstName(currentUser.firstName || 'Sreerag');
      setLastName(currentUser.lastName || 'P.');
      setPhone(currentUser.phone || '+91 98765 43210');
      if (currentUser.profile) {
        setIceName(currentUser.profile.emergencyContactName || 'Ananya S. (Sister)');
        setIcePhone(currentUser.profile.emergencyContactPhone || '+91 94471 23456');
        setBloodGroup(currentUser.profile.bloodGroup || 'O+ Positive');
        setMedicalNotes(currentUser.profile.medicalNotes || 'No major allergies. Carries mild asthma inhaler.');
        setDietaryPref(currentUser.profile.dietaryPreference || 'Traditional Kerala Sadya (Veg)');
        setTravelPace(currentUser.profile.travelPace || 'Balanced (2-3 stops/day)');
        setAccessibility(currentUser.profile.accessibilityRequired ?? false);
        if (currentUser.profile.offlinePackages && currentUser.profile.offlinePackages.length > 0) {
          setOfflinePackages(currentUser.profile.offlinePackages);
        }
      }
    }
  }, [currentUser]);

  const dietaryOptions = [
    'Traditional Kerala Sadya (Veg)',
    'Coastal Seafood Lover',
    'Non-Vegetarian',
    'Jain / Pure Veg',
  ];

  const paceOptions = [
    'Relaxed (1-2 stops/day)',
    'Balanced (2-3 stops/day)',
    'Action-Packed (4+ stops/day)',
  ];

  const handleSaveProfile = async () => {
    setIsSaving(true);
    try {
      await updateUserProfile({
        firstName,
        lastName,
        phone,
        emergencyContactName: iceName,
        emergencyContactPhone: icePhone,
        bloodGroup,
        medicalNotes,
        dietaryPreference: dietaryPref,
        travelPace,
        accessibilityRequired: accessibility,
        offlinePackages,
      });
      setIsEditing(false);
      showToast('✨ Traveler profile and ICE emergency details saved to KeraLink cloud!');
    } catch (_) {
      showToast('⚠️ Could not save profile changes. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDietaryChange = async (opt: string) => {
    setDietaryPref(opt);
    try {
      await updateUserProfile({ dietaryPreference: opt });
      showToast(`🍛 AI Travel Architect preference set to ${opt}`);
    } catch (_) {}
  };

  const handlePaceChange = async (opt: string) => {
    setTravelPace(opt);
    try {
      await updateUserProfile({ travelPace: opt });
      showToast(`⏱️ Travel pace updated to ${opt}`);
    } catch (_) {}
  };

  const togglePackage = async (pkgId: string) => {
    const updated = offlinePackages.map((p) => {
      if (p.id === pkgId) {
        return { ...p, isDownloaded: !p.isDownloaded };
      }
      return p;
    });
    setOfflinePackages(updated);
    const target = updated.find((p) => p.id === pkgId);
    showToast(
      target?.isDownloaded
        ? `📶 Downloaded ${target.name} for offline ghat navigation`
        : `🗑️ Removed ${target?.name} from offline cache`
    );
    try {
      await updateUserProfile({ offlinePackages: updated });
    } catch (_) {}
  };

  return (
    <div className="min-h-full bg-[#07161B] text-[#F0F7F6] pb-16">
      {/* Top Banner Header */}
      <div className="relative overflow-hidden bg-gradient-to-r from-[#0D2B35] via-[#133B49] to-[#07161B] border-b border-[#1D4A5A] px-4 py-8 sm:px-8">
        <div className="max-w-5xl mx-auto flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="flex items-center gap-5">
            {/* Avatar with golden glowing ring */}
            <div className="relative group">
              <div className="w-20 h-20 sm:w-24 sm:h-24 rounded-full p-1 bg-gradient-to-tr from-[#E5A93C] via-[#1ABC9C] to-[#E5A93C] shadow-lg shadow-[#E5A93C]/20">
                <img
                  src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80"
                  alt="Traveler Avatar"
                  className="w-full h-full rounded-full object-cover"
                />
              </div>
              <button
                onClick={() => setIsEditing(!isEditing)}
                className="absolute bottom-0 right-0 p-1.5 bg-[#0D2B35] border border-[#E5A93C] rounded-full text-[#E5A93C] hover:bg-[#E5A93C] hover:text-[#07161B] transition-colors"
                title="Edit Profile"
              >
                <Edit3 className="w-3.5 h-3.5" />
              </button>
            </div>

            <div>
              <div className="flex flex-wrap items-center gap-2 mb-1">
                <h1 className="text-2xl sm:text-3xl font-bold font-serif text-[#F0F7F6]">
                  {firstName} {lastName}
                </h1>
                <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-[#1ABC9C]/20 text-[#1ABC9C] border border-[#1ABC9C]/40">
                  <CheckCircle2 className="w-3 h-3" />
                  Verified Traveler
                </span>
                <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-[#E5A93C]/20 text-[#E5A93C] border border-[#E5A93C]/40">
                  🌿 Backwater Guardian
                </span>
              </div>
              <p className="text-xs sm:text-sm text-[#8BA3AB] flex items-center gap-3 flex-wrap">
                <span className="flex items-center gap-1">
                  <Mail className="w-3.5 h-3.5 text-[#E5A93C]" /> {email}
                </span>
                <span className="flex items-center gap-1">
                  <Phone className="w-3.5 h-3.5 text-[#1ABC9C]" /> {phone}
                </span>
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => setIsEditing(!isEditing)}
              className="px-4 py-2 rounded-xl text-xs font-bold border border-[#E5A93C]/40 bg-[#0D2B35] text-[#E5A93C] hover:bg-[#E5A93C] hover:text-[#07161B] transition-all flex items-center gap-1.5"
            >
              {isEditing ? <X className="w-4 h-4" /> : <Edit3 className="w-4 h-4" />}
              {isEditing ? 'Cancel Edit' : 'Edit Profile'}
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-4 sm:px-8 mt-6 space-y-6">
        {/* Quick Metrics Ribbon */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4">
          <div className="p-4 rounded-2xl bg-[#0D2B35] border border-[#1D4A5A] flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#1ABC9C]/20 text-[#1ABC9C] flex items-center justify-center shrink-0">
              <Leaf className="w-5 h-5" />
            </div>
            <div>
              <p className="text-[11px] text-[#8BA3AB] font-medium">Eco Score</p>
              <p className="text-lg font-bold text-[#1ABC9C]">92%</p>
            </div>
          </div>

          <div className="p-4 rounded-2xl bg-[#0D2B35] border border-[#1D4A5A] flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#E5A93C]/20 text-[#E5A93C] flex items-center justify-center shrink-0">
              <Compass className="w-5 h-5" />
            </div>
            <div>
              <p className="text-[11px] text-[#8BA3AB] font-medium">Trips Done</p>
              <p className="text-lg font-bold text-[#E5A93C]">3 Escapes</p>
            </div>
          </div>

          <div className="p-4 rounded-2xl bg-[#0D2B35] border border-[#1D4A5A] flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-rose-500/20 text-rose-400 flex items-center justify-center shrink-0">
              <Shield className="w-5 h-5" />
            </div>
            <div>
              <p className="text-[11px] text-[#8BA3AB] font-medium">ICE Safety</p>
              <p className="text-lg font-bold text-rose-400">Verified</p>
            </div>
          </div>

          <div className="p-4 rounded-2xl bg-[#0D2B35] border border-[#1D4A5A] flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-500/20 text-amber-300 flex items-center justify-center shrink-0">
              <Zap className="w-5 h-5" />
            </div>
            <div>
              <p className="text-[11px] text-[#8BA3AB] font-medium">EV Clean Miles</p>
              <p className="text-lg font-bold text-amber-300">142 mi</p>
            </div>
          </div>
        </div>

        {/* Edit Modal/Drawer if open */}
        {isEditing && (
          <div className="p-6 rounded-2xl bg-[#0D2B35] border border-[#E5A93C]/50 shadow-2xl animate-in fade-in slide-in-from-top-4 space-y-4">
            <div className="flex items-center justify-between border-b border-[#1D4A5A] pb-3">
              <h3 className="text-sm font-bold uppercase tracking-wider text-[#E5A93C] flex items-center gap-2">
                <Edit3 className="w-4 h-4" /> Edit Profile & Emergency Details
              </h3>
              <button
                onClick={() => setIsEditing(false)}
                className="text-gray-400 hover:text-white"
              >
                ✕
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-[#8BA3AB] mb-1">First Name</label>
                <input
                  type="text"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#133B49] border border-[#1D4A5A] text-sm text-[#F0F7F6] focus:border-[#E5A93C] outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#8BA3AB] mb-1">Last Name</label>
                <input
                  type="text"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#133B49] border border-[#1D4A5A] text-sm text-[#F0F7F6] focus:border-[#E5A93C] outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#8BA3AB] mb-1">Phone Number</label>
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#133B49] border border-[#1D4A5A] text-sm text-[#F0F7F6] focus:border-[#E5A93C] outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#8BA3AB] mb-1">Blood Group</label>
                <input
                  type="text"
                  value={bloodGroup}
                  onChange={(e) => setBloodGroup(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#133B49] border border-[#1D4A5A] text-sm text-[#F0F7F6] focus:border-[#E5A93C] outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#8BA3AB] mb-1">ICE Contact Name</label>
                <input
                  type="text"
                  value={iceName}
                  onChange={(e) => setIceName(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#133B49] border border-[#1D4A5A] text-sm text-[#F0F7F6] focus:border-[#E5A93C] outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#8BA3AB] mb-1">ICE Contact Phone</label>
                <input
                  type="text"
                  value={icePhone}
                  onChange={(e) => setIcePhone(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#133B49] border border-[#1D4A5A] text-sm text-[#F0F7F6] focus:border-[#E5A93C] outline-none"
                />
              </div>
            </div>

            <div className="flex justify-end gap-3 pt-2">
              <button
                onClick={() => setIsEditing(false)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-[#8BA3AB] hover:text-white"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveProfile}
                disabled={isSaving}
                className="px-5 py-2 rounded-xl text-xs font-bold bg-[#E5A93C] text-[#07161B] hover:bg-[#d89d31] flex items-center gap-1.5 shadow-lg disabled:opacity-50"
              >
                {isSaving ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Save className="w-3.5 h-3.5" />}
                {isSaving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </div>
        )}

        {/* Section 1: In Case of Emergency (ICE) Safety Card */}
        <div className="p-6 rounded-2xl bg-[#0D2B35] border border-rose-500/40 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="p-2 rounded-xl bg-rose-500/20 text-rose-400">
                <Shield className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-base font-bold text-[#F0F7F6]">Emergency & Safety Hub (ICE)</h2>
                <p className="text-xs text-[#8BA3AB]">
                  Directly dispatched to Kerala Tourist Police (112) during trek or corridor distress
                </p>
              </div>
            </div>
            <span className="px-3 py-1 rounded-xl text-xs font-bold bg-rose-500/20 text-rose-400 border border-rose-500/40">
              {bloodGroup}
            </span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
            <div className="p-4 rounded-xl bg-[#133B49]/80 border border-[#1D4A5A]">
              <p className="text-[11px] uppercase tracking-wider text-[#8BA3AB] font-bold">Next of Kin Contact</p>
              <p className="text-sm font-bold text-[#F0F7F6] mt-1">{iceName}</p>
              <p className="text-xs font-mono text-[#1ABC9C] mt-0.5">{icePhone}</p>
            </div>

            <div className="p-4 rounded-xl bg-[#133B49]/80 border border-[#1D4A5A]">
              <p className="text-[11px] uppercase tracking-wider text-[#8BA3AB] font-bold">Medical Notes & Allergies</p>
              <p className="text-xs text-[#C5D8CD] mt-1.5 leading-relaxed">{medicalNotes}</p>
            </div>
          </div>

          <div className="pt-2 flex flex-wrap items-center justify-between gap-3 border-t border-[#1D4A5A]">
            <span className="text-xs text-[#8BA3AB]">
              Live GPS beacon & corridor dispatch ready 24/7 across all 14 districts.
            </span>
            <button
              onClick={() => navigateTo('SAFETY')}
              className="px-4 py-2 rounded-xl text-xs font-bold bg-rose-500 text-white hover:bg-rose-600 transition-all flex items-center gap-1.5 shadow-lg shadow-rose-950/50"
            >
              <AlertTriangle className="w-3.5 h-3.5" />
              Open Kerala Safety Center
            </button>
          </div>
        </div>

        {/* Section 2: AI Travel Architect Personalization */}
        <div className="p-6 rounded-2xl bg-[#0D2B35] border border-[#1D4A5A] space-y-5">
          <div className="flex items-center gap-2">
            <div className="p-2 rounded-xl bg-[#E5A93C]/20 text-[#E5A93C]">
              <Zap className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-[#F0F7F6]">AI Travel Architect Personalization</h2>
              <p className="text-xs text-[#8BA3AB]">
                Stored preferences automatically tailor Day-by-Day Munnar, Kochi, and Wayanad itineraries
              </p>
            </div>
          </div>

          {/* Dietary options */}
          <div>
            <label className="block text-xs font-semibold text-[#8BA3AB] mb-2 uppercase tracking-wider">
              Dietary Profile
            </label>
            <div className="flex flex-wrap gap-2">
              {dietaryOptions.map((opt) => {
                const isSelected = dietaryPref === opt;
                return (
                  <button
                    key={opt}
                    onClick={() => handleDietaryChange(opt)}
                    className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all ${
                      isSelected
                        ? 'bg-[#E5A93C] text-[#07161B] font-bold shadow-md shadow-[#E5A93C]/30'
                        : 'bg-[#133B49] text-[#C5D8CD] border border-[#1D4A5A] hover:border-[#E5A93C]/50'
                    }`}
                  >
                    {opt}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Travel Pace */}
          <div>
            <label className="block text-xs font-semibold text-[#8BA3AB] mb-2 uppercase tracking-wider">
              Travel Rhythm & Pace
            </label>
            <div className="flex flex-wrap gap-2">
              {paceOptions.map((opt) => {
                const isSelected = travelPace === opt;
                return (
                  <button
                    key={opt}
                    onClick={() => handlePaceChange(opt)}
                    className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all ${
                      isSelected
                        ? 'bg-[#E5A93C] text-[#07161B] font-bold shadow-md shadow-[#E5A93C]/30'
                        : 'bg-[#133B49] text-[#C5D8CD] border border-[#1D4A5A] hover:border-[#E5A93C]/50'
                    }`}
                  >
                    {opt}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Accessibility toggle */}
          <div className="flex items-center justify-between pt-2 border-t border-[#1D4A5A]">
            <div>
              <p className="text-xs font-bold text-[#F0F7F6]">Wheelchair / Senior Citizen Accessibility</p>
              <p className="text-[11px] text-[#8BA3AB]">Filter for ramp access resorts and smooth ghat boardwalks</p>
            </div>
            <button
              onClick={() => {
                setAccessibility(!accessibility);
                showToast(
                  !accessibility
                    ? '♿ Accessibility filter enabled for AI Planner'
                    : 'Accessibility filter disabled'
                );
              }}
              className={`w-11 h-6 rounded-full transition-colors relative p-0.5 ${
                accessibility ? 'bg-[#1ABC9C]' : 'bg-[#133B49] border border-[#1D4A5A]'
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full bg-white transition-transform ${
                  accessibility ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>
        </div>

        {/* Section 3: Eco-Passport & Badges */}
        <div className="p-6 rounded-2xl bg-[#0D2B35] border border-[#1D4A5A] space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="p-2 rounded-xl bg-[#1ABC9C]/20 text-[#1ABC9C]">
                <Award className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-base font-bold text-[#F0F7F6]">Eco-Tourism Passport & Badges</h2>
                <p className="text-xs text-[#8BA3AB]">Recognized sustainability milestones across Kerala</p>
              </div>
            </div>
            <span className="text-xs font-bold text-[#1ABC9C]">58.4 kg CO₂ Offset</span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-1">
            <div className="p-4 rounded-xl bg-[#133B49] border border-[#1D4A5A] flex items-start gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#E5A93C]/20 text-[#E5A93C] flex items-center justify-center shrink-0">
                ⛰️
              </div>
              <div>
                <p className="text-xs font-bold text-[#F0F7F6]">Munnar Mist Explorer</p>
                <p className="text-[11px] text-[#8BA3AB] mt-0.5">High-altitude tea trails of Lockhart Valley</p>
                <span className="text-[10px] text-[#E5A93C] font-semibold mt-1 block">Earned Aug 2026</span>
              </div>
            </div>

            <div className="p-4 rounded-xl bg-[#133B49] border border-[#1D4A5A] flex items-start gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#1ABC9C]/20 text-[#1ABC9C] flex items-center justify-center shrink-0">
                🛶
              </div>
              <div>
                <p className="text-xs font-bold text-[#F0F7F6]">Backwater Guardian</p>
                <p className="text-[11px] text-[#8BA3AB] mt-0.5">Zero-plastic solar houseboat in Kumarakom</p>
                <span className="text-[10px] text-[#1ABC9C] font-semibold mt-1 block">Earned Sep 2026</span>
              </div>
            </div>

            <div className="p-4 rounded-xl bg-[#133B49] border border-[#1D4A5A] flex items-start gap-3">
              <div className="w-10 h-10 rounded-xl bg-amber-500/20 text-amber-300 flex items-center justify-center shrink-0">
                🌿
              </div>
              <div>
                <p className="text-xs font-bold text-[#F0F7F6]">Spice Route Trekker</p>
                <p className="text-[11px] text-[#8BA3AB] mt-0.5">Organic cardamom farmers in Thekkady</p>
                <span className="text-[10px] text-amber-300 font-semibold mt-1 block">Earned Sep 2026</span>
              </div>
            </div>
          </div>
        </div>

        {/* Section 4: Offline Ghat Corridors */}
        <div className="p-6 rounded-2xl bg-[#0D2B35] border border-[#1D4A5A] space-y-4">
          <div className="flex items-center gap-2">
            <div className="p-2 rounded-xl bg-[#E5A93C]/20 text-[#E5A93C]">
              <Download className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-[#F0F7F6]">Offline Ghat Corridor Packages</h2>
              <p className="text-xs text-[#8BA3AB]">
                Guarantees interactive maps, emergency clinic contacts, and routing during mountain dead-zones
              </p>
            </div>
          </div>

          <div className="space-y-3 pt-1">
            {offlinePackages.map((pkg) => (
              <div
                key={pkg.id}
                className="p-4 rounded-xl bg-[#133B49] border border-[#1D4A5A] flex items-center justify-between gap-4"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-bold text-[#F0F7F6]">{pkg.name}</p>
                    <span className="text-[10px] px-2 py-0.5 rounded font-mono bg-[#0D2B35] text-[#8BA3AB]">
                      {pkg.size}
                    </span>
                  </div>
                  <p className="text-xs text-[#8BA3AB] mt-0.5">{pkg.includes}</p>
                </div>

                <button
                  onClick={() => togglePackage(pkg.id)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all ${
                    pkg.isDownloaded
                      ? 'bg-[#1ABC9C]/20 text-[#1ABC9C] border border-[#1ABC9C]/40 hover:bg-rose-500/20 hover:text-rose-400 hover:border-rose-500/40'
                      : 'bg-[#E5A93C] text-[#07161B] hover:bg-[#d89d31]'
                  }`}
                >
                  {pkg.isDownloaded ? (
                    <>
                      <CheckCircle2 className="w-3.5 h-3.5" /> Downloaded
                    </>
                  ) : (
                    <>
                      <Download className="w-3.5 h-3.5" /> Download
                    </>
                  )}
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Section 5: Preferences, Language & Security */}
        <div className="p-6 rounded-2xl bg-[#0D2B35] border border-[#1D4A5A] space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Globe className="w-4 h-4 text-[#E5A93C]" />
              <span className="text-sm font-bold text-[#F0F7F6]">App Display Language</span>
            </div>
            <select
              value={selectedLanguage}
              onChange={(e) => {
                setSelectedLanguage(e.target.value);
                showToast(`🌐 Language switched to ${e.target.value}`);
              }}
              className="px-3 py-1.5 rounded-xl bg-[#133B49] border border-[#1D4A5A] text-xs font-bold text-[#E5A93C] outline-none"
            >
              <option value="English (EN)">English (EN)</option>
              <option value="Malayalam (മലയാളം)">Malayalam (മലയാളം)</option>
              <option value="Hindi (हिंदी)">Hindi (हिंदी)</option>
            </select>
          </div>
        </div>
      </div>
    </div>
  );
};
