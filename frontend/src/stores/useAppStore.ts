import { create } from 'zustand';
import {
  User,
  Destination,
  Experience,
  Accommodation,
  TripProfile,
  AIPlan,
  Booking,
  UserRole,
} from '../types/contracts';
import { mockBackend } from '../adapters/mockAdapter';

export type ScreenId =
  | 'LANDING'
  | 'ONBOARDING'
  | 'HOME'
  | 'EXPLORE'
  | 'MAP'
  | 'AI_PLANNER'
  | 'AI_GENERATING'
  | 'ITINERARY'
  | 'CHECKOUT'
  | 'BOOKING_CONFIRMED'
  | 'MY_TRIPS'
  | 'COMPANION'
  | 'SAFETY'
  | 'PROVIDER_PORTAL'
  | 'ADMIN_PORTAL';

export type ViewMode = 'WEB' | 'DEVICE_FRAME';

interface AppState {
  // Navigation & View
  viewMode: ViewMode;
  activeScreen: ScreenId;
  previousScreen?: ScreenId;
  setViewMode: (mode: ViewMode) => void;
  navigateTo: (screen: ScreenId) => void;

  // Auth & RBAC
  currentUser: User | null;
  currentRole: UserRole;
  setCurrentUser: (user: User | null) => void;
  switchRole: (role: UserRole) => Promise<void>;

  // Tourism Data
  destinations: Destination[];
  experiences: Experience[];
  accommodations: Accommodation[];
  selectedCategory: string;
  selectedDestination: Destination | null;
  selectedExperience: Experience | null;
  selectedAccommodation: Accommodation | null;
  setSelectedCategory: (cat: string) => void;
  setSelectedDestination: (dest: Destination | null) => void;
  setSelectedExperience: (exp: Experience | null) => void;
  setSelectedAccommodation: (acc: Accommodation | null) => void;
  loadInitialData: () => Promise<void>;

  // AI Travel Architect
  currentTripProfile: TripProfile | null;
  currentPlan: AIPlan | null;
  isGenerating: boolean;
  selectedDayNumber: number;
  dayCustomizeModalOpen: boolean;
  setTripProfile: (profile: TripProfile) => void;
  setCurrentPlan: (plan: AIPlan | null) => void;
  setSelectedDayNumber: (day: number) => void;
  setDayCustomizeModalOpen: (open: boolean) => void;
  generateTrip: (profile: TripProfile) => Promise<AIPlan>;
  regenerateDay: (
    dayNumber: number,
    modification: 'MAKE_CHEAPER' | 'RAIN_FRIENDLY' | 'ADD_ADVENTURE' | 'MORE_LOCAL' | 'FOOD_FOCUSED'
  ) => Promise<void>;

  // Booking & Payments
  currentBooking: Booking | null;
  myBookings: Booking[];
  setCurrentBooking: (booking: Booking | null) => void;
  createBooking: (guestInfo: { name: string; phone: string; email: string }) => Promise<Booking>;
  confirmPayment: (paymentMethod: string) => Promise<Booking>;

  // Toast / System Notifications
  toastMessage: string | null;
  showToast: (msg: string) => void;
  hideToast: () => void;
}

export const useAppStore = create<AppState>((set, get) => ({
  viewMode: 'DEVICE_FRAME', // Defaults to pixel-perfect mobile board mockup, switchable to full responsive web!
  activeScreen: 'LANDING',
  previousScreen: undefined,
  setViewMode: (mode) => set({ viewMode: mode }),
  navigateTo: (screen) => {
    const current = get().activeScreen;
    set({ activeScreen: screen, previousScreen: current });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  },

  currentUser: null,
  currentRole: 'CUSTOMER',
  setCurrentUser: (user) => set({ currentUser: user }),
  switchRole: async (role) => {
    const updated = await mockBackend.switchRole(role);
    set({ currentUser: updated, currentRole: role });
    if (role.startsWith('PROVIDER')) {
      get().navigateTo('PROVIDER_PORTAL');
    } else if (role === 'ADMIN' || role === 'SUPER_ADMIN') {
      get().navigateTo('ADMIN_PORTAL');
    } else {
      get().navigateTo('HOME');
    }
  },

  destinations: [],
  experiences: [],
  accommodations: [],
  selectedCategory: 'ALL',
  selectedDestination: null,
  selectedExperience: null,
  selectedAccommodation: null,
  setSelectedCategory: (cat) => set({ selectedCategory: cat }),
  setSelectedDestination: (dest) => set({ selectedDestination: dest }),
  setSelectedExperience: (exp) => set({ selectedExperience: exp }),
  setSelectedAccommodation: (acc) => set({ selectedAccommodation: acc }),

  loadInitialData: async () => {
    const [user, dests, exps, accs, bks] = await Promise.all([
      mockBackend.getCurrentUser(),
      mockBackend.getDestinations(),
      mockBackend.getExperiences(),
      mockBackend.getAccommodations(),
      mockBackend.getUserBookings(),
    ]);
    set({
      currentUser: user,
      destinations: dests,
      experiences: exps,
      accommodations: accs,
      myBookings: bks,
    });
  },

  currentTripProfile: null,
  currentPlan: null,
  isGenerating: false,
  selectedDayNumber: 2,
  dayCustomizeModalOpen: false,
  setTripProfile: (profile) => set({ currentTripProfile: profile }),
  setCurrentPlan: (plan) => set({ currentPlan: plan }),
  setSelectedDayNumber: (day) => set({ selectedDayNumber: day }),
  setDayCustomizeModalOpen: (open) => set({ dayCustomizeModalOpen: open }),

  generateTrip: async (profile) => {
    set({ isGenerating: true, activeScreen: 'AI_GENERATING', currentTripProfile: profile });
    // Simulate multi-stage AI reasoning delay
    await new Promise((r) => setTimeout(r, 2600));
    const plan = await mockBackend.generateTripItinerary(profile);
    set({ currentPlan: plan, isGenerating: false, activeScreen: 'ITINERARY', selectedDayNumber: 2 });
    return plan;
  },

  regenerateDay: async (dayNumber, modification) => {
    const plan = get().currentPlan;
    if (!plan) return;
    set({ isGenerating: true });
    await new Promise((r) => setTimeout(r, 1400));
    const updated = await mockBackend.regenerateDay(plan.id, dayNumber, modification);
    set({
      currentPlan: updated,
      isGenerating: false,
      dayCustomizeModalOpen: false,
    });
    get().showToast(`✨ Day ${dayNumber} regenerated: ${updated.currentVersion.changeReason}`);
  },

  currentBooking: null,
  myBookings: [],
  setCurrentBooking: (booking) => set({ currentBooking: booking }),

  createBooking: async (guestInfo) => {
    const plan = get().currentPlan;
    if (!plan) throw new Error('No active trip plan');
    const booking = await mockBackend.createBookingFromPlan(plan, guestInfo);
    set({ currentBooking: booking });
    get().navigateTo('CHECKOUT');
    return booking;
  },

  confirmPayment: async (paymentMethod) => {
    const booking = get().currentBooking;
    if (!booking) throw new Error('No active booking');
    set({ isGenerating: true });
    await new Promise((r) => setTimeout(r, 1500));
    const confirmed = await mockBackend.confirmBookingPayment(booking.id, paymentMethod);
    set({
      currentBooking: confirmed,
      myBookings: [confirmed, ...get().myBookings],
      isGenerating: false,
    });
    get().navigateTo('BOOKING_CONFIRMED');
    return confirmed;
  },

  toastMessage: null,
  showToast: (msg) => {
    set({ toastMessage: msg });
    setTimeout(() => {
      set({ toastMessage: null });
    }, 4500);
  },
  hideToast: () => set({ toastMessage: null }),
}));
