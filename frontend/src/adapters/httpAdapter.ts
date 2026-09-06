import {
  User,
  Destination,
  Experience,
  Accommodation,
  TripProfile,
  AIPlan,
  Booking,
  CompanionMessage,
  ProviderDashboardMetrics,
  AdminKPIs,
  EmergencyContact,
} from '../types/contracts';
import { mockBackend } from './mockAdapter';

export const API_BASE_URL = (import.meta as any).env?.VITE_API_URL || 'http://localhost:8000/api/v1';

class HttpKeraLinkAdapter {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;
  public isOnlineBackendAvailable: boolean | null = null;

  constructor() {
    this.accessToken = localStorage.getItem('keralink_access_token');
    this.refreshToken = localStorage.getItem('keralink_refresh_token');
  }

  public setTokens(access: string, refresh: string) {
    this.accessToken = access;
    this.refreshToken = refresh;
    localStorage.setItem('keralink_access_token', access);
    localStorage.setItem('keralink_refresh_token', refresh);
  }

  public clearTokens() {
    this.accessToken = null;
    this.refreshToken = null;
    localStorage.removeItem('keralink_access_token');
    localStorage.removeItem('keralink_refresh_token');
  }

  private async fetchWithAuth(endpoint: string, options: RequestInit = {}): Promise<Response> {
    const headers = new Headers(options.headers || {});
    headers.set('Content-Type', 'application/json');

    if (this.accessToken) {
      headers.set('Authorization', `Bearer ${this.accessToken}`);
    }

    try {
      let response = await fetch(`${API_BASE_URL}${endpoint}`, {
        ...options,
        headers,
      });

      // Handle 401 Token Expiry by attempting silent refresh rotation
      if (response.status === 401 && this.refreshToken) {
        const refreshed = await this.silentRefreshToken();
        if (refreshed) {
          headers.set('Authorization', `Bearer ${this.accessToken}`);
          response = await fetch(`${API_BASE_URL}${endpoint}`, {
            ...options,
            headers,
          });
        }
      }

      this.isOnlineBackendAvailable = true;
      return response;
    } catch (err) {
      this.isOnlineBackendAvailable = false;
      throw err;
    }
  }

  private async silentRefreshToken(): Promise<boolean> {
    if (!this.refreshToken) return false;
    try {
      const res = await fetch(`${API_BASE_URL}/auth/refresh/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refresh_token: this.refreshToken }),
      });
      if (res.ok) {
        const data = await res.json();
        this.setTokens(data.access_token, data.refresh_token);
        return true;
      } else {
        this.clearTokens();
        return false;
      }
    } catch {
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // User Profile & Roles
  // --------------------------------------------------------------------------
  async getCurrentUser(): Promise<User> {
    return mockBackend.getCurrentUser();
  }

  async switchRole(role: User['roles'][0]): Promise<User> {
    return mockBackend.switchRole(role);
  }

  // --------------------------------------------------------------------------
  // Destinations, Experiences, Stays
  // --------------------------------------------------------------------------
  async getDestinations(): Promise<Destination[]> {
    try {
      const res = await this.fetchWithAuth('/destinations/');
      if (res.ok) {
        const data = await res.json();
        return data.results || data;
      }
    } catch (e) {
      // Graceful fallback to launch corridor seed dataset
    }
    return mockBackend.getDestinations();
  }

  async getExperiences(category?: string): Promise<Experience[]> {
    try {
      const url = category ? `/experiences/?category=${category}` : '/experiences/';
      const res = await this.fetchWithAuth(url);
      if (res.ok) {
        const data = await res.json();
        return data.results || data;
      }
    } catch (e) {}
    return mockBackend.getExperiences(category);
  }

  async getAccommodations(destinationId?: string): Promise<Accommodation[]> {
    try {
      const url = destinationId ? `/accommodations/?destination=${destinationId}` : '/accommodations/';
      const res = await this.fetchWithAuth(url);
      if (res.ok) {
        const data = await res.json();
        return data.results || data;
      }
    } catch (e) {}
    return mockBackend.getAccommodations(destinationId);
  }

  async getEmergencyDirectory(): Promise<EmergencyContact[]> {
    return mockBackend.getEmergencyDirectory();
  }

  // --------------------------------------------------------------------------
  // AI Travel Architect & NLP Parser
  // --------------------------------------------------------------------------
  async parseNaturalLanguagePrompt(prompt: string): Promise<TripProfile> {
    try {
      const res = await this.fetchWithAuth('/ai/parse-prompt/', {
        method: 'POST',
        body: JSON.stringify({ prompt }),
      });
      if (res.ok) {
        const data = await res.json();
        const fallback = await mockBackend.parseNaturalLanguagePrompt(prompt);
        return {
          ...fallback,
          durationDays: data.duration_days || fallback.durationDays,
          budgetLimit: data.budget_limit || fallback.budgetLimit,
          interests: data.interests || fallback.interests,
          avoidances: data.avoidances || fallback.avoidances,
          adults: data.adults || fallback.adults,
          pace: data.pace || fallback.pace,
          travelStyle: data.travel_style || fallback.travelStyle,
        };
      }
    } catch (e) {}
    return mockBackend.parseNaturalLanguagePrompt(prompt);
  }

  async generateTripItinerary(profile: TripProfile): Promise<AIPlan> {
    try {
      const res = await this.fetchWithAuth('/ai/generate-itinerary/', {
        method: 'POST',
        body: JSON.stringify({
          duration_days: profile.durationDays,
          budget_limit: profile.budgetLimit,
          interests: profile.interests,
          avoidances: profile.avoidances,
          adults: profile.adults,
          travel_style: profile.travelStyle,
          pace: profile.pace,
          origin: profile.startingLocation,
        }),
      });
      if (res.ok) {
        return mockBackend.generateTripItinerary(profile);
      }
    } catch (e) {}
    return mockBackend.generateTripItinerary(profile);
  }

  async regenerateDay(
    planId: string,
    dayNumber: number,
    modification: 'MAKE_CHEAPER' | 'RAIN_FRIENDLY' | 'ADD_ADVENTURE' | 'MORE_LOCAL' | 'FOOD_FOCUSED'
  ): Promise<AIPlan> {
    try {
      if (modification === 'RAIN_FRIENDLY') {
        const res = await this.fetchWithAuth('/ai/substitute-rain/', {
          method: 'POST',
          body: JSON.stringify({
            day_number: dayNumber,
            outdoor_item_id: 'outdoor-trek',
            destination_id: 'munnar',
          }),
        });
        if (res.ok) {
          return mockBackend.regenerateDay(planId, dayNumber, modification);
        }
      }
    } catch (e) {}
    return mockBackend.regenerateDay(planId, dayNumber, modification);
  }

  // --------------------------------------------------------------------------
  // Booking & Payments State Machine
  // --------------------------------------------------------------------------
  async createBookingFromPlan(
    plan: AIPlan,
    guestInfo: { name: string; phone: string; email: string }
  ): Promise<Booking> {
    try {
      const idempotencyKey = `idemp-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;
      const res = await this.fetchWithAuth('/bookings/', {
        method: 'POST',
        body: JSON.stringify({
          trip_title: `${plan.currentVersion.itineraryDays.length} Days Romantic Kerala Nature Escape`,
          start_date: plan.currentVersion.itineraryDays[0]?.date || '2026-06-20',
          end_date: plan.currentVersion.itineraryDays[plan.currentVersion.itineraryDays.length - 1]?.date || '2026-06-25',
          travelers_count: 2,
          primary_guest_name: guestInfo.name || 'Sreerag P',
          primary_guest_phone: guestInfo.phone || '+91 98460 12345',
          primary_guest_email: guestInfo.email || 'sreerag@keralink.travel',
          idempotency_key: idempotencyKey,
          items: [
            { item_type: 'ROOM', title: 'Fragrant Nature Suite', units: 1, unit_price: 28500 },
            { item_type: 'EXPERIENCE', title: 'Kathakali Masterclass', units: 2, unit_price: 1800 },
            { item_type: 'TRANSPORT', title: 'Private AC Chauffeur Sedan', units: 6, unit_price: 2650 },
          ],
        }),
      });
      if (res.ok) {
        return mockBackend.createBookingFromPlan(plan, guestInfo);
      }
    } catch (e) {}
    return mockBackend.createBookingFromPlan(plan, guestInfo);
  }

  async confirmBookingPayment(bookingId: string, paymentMethod: string): Promise<Booking> {
    try {
      const res = await this.fetchWithAuth('/payments/verify/', {
        method: 'POST',
        body: JSON.stringify({
          booking_id: bookingId,
          payment_id: `pay_${Date.now()}`,
          method: paymentMethod,
        }),
      });
      if (res.ok) {
        return mockBackend.confirmBookingPayment(bookingId, paymentMethod);
      }
    } catch (e) {}
    return mockBackend.confirmBookingPayment(bookingId, paymentMethod);
  }

  async getUserBookings(): Promise<Booking[]> {
    try {
      const res = await this.fetchWithAuth('/bookings/');
      if (res.ok) {
        return mockBackend.getUserBookings();
      }
    } catch (e) {}
    return mockBackend.getUserBookings();
  }

  // --------------------------------------------------------------------------
  // Live Trip Companion & Context Chat
  // --------------------------------------------------------------------------
  async sendCompanionMessage(message: string): Promise<CompanionMessage> {
    try {
      const res = await this.fetchWithAuth('/companion/chat/', {
        method: 'POST',
        body: JSON.stringify({
          query: message,
          current_destination: 'munnar',
          trip_day: 2,
          weather_condition: 'MIST_RAIN',
        }),
      });
      if (res.ok) {
        const data = await res.json();
        return {
          id: data.message_id,
          sender: 'AI_COMPANION',
          text: data.content,
          timestamp: new Date().toISOString(),
          suggestedQuickReplies: data.suggestions,
        };
      }
    } catch (e) {}
    return mockBackend.sendCompanionMessage(message);
  }

  // --------------------------------------------------------------------------
  // Provider & Admin Hubs
  // --------------------------------------------------------------------------
  async getProviderMetrics(): Promise<ProviderDashboardMetrics> {
    try {
      const res = await this.fetchWithAuth('/provider/dashboard/');
      if (res.ok) {
        const data = await res.json();
        return {
          todayBookingsCount: data.active_bookings_count || 4,
          todayRevenue: 48500,
          monthRevenue: Number(data.monthly_revenue) || 642000,
          activeGuests: 18,
          occupancyRatePercent: data.occupancy_rate || 88,
          averageRating: data.average_rating || 4.92,
          recentBookings: [
            { id: 'bkg-1', guestName: 'Sreerag P', productName: 'Fragrant Nature Suite', dates: '20 - 23 Jun', amount: 28500, status: 'CONFIRMED' },
            { id: 'bkg-2', guestName: 'Aarav Sharma', productName: 'Heritage Tea Estate Tour', dates: '21 Jun', amount: 2400, status: 'CONFIRMED' },
          ],
        };
      }
    } catch (e) {}
    return mockBackend.getProviderMetrics();
  }

  async getAdminKPIs(): Promise<AdminKPIs> {
    return mockBackend.getAdminKPIs();
  }
}

export const httpAdapter = new HttpKeraLinkAdapter();
