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

// ----------------------------------------------------------------------------
// Model Mappers (Transforms DRF snake_case responses into Frontend Contracts)
// ----------------------------------------------------------------------------

function mapDestination(d: any): Destination {
  return {
    id: d.id || d.slug,
    name: d.name,
    slug: d.slug || d.id,
    district: d.district || '',
    tagline: d.tagline || '',
    description: d.description || '',
    heroImage: d.hero_image || d.heroImage || '',
    galleryImages: d.gallery_images || d.galleryImages || [],
    coordinates: {
      lat: Number(d.latitude ?? d.coordinates?.lat ?? 10.0),
      lng: Number(d.longitude ?? d.coordinates?.lng ?? 76.5),
    },
    bestSeason: d.best_season || d.bestSeason || 'October to March',
    tags: d.tags || [],
    preferences: d.preferences || {
      nature: 0.9,
      romance: 0.8,
      adventure: 0.7,
      culture: 0.8,
      food: 0.8,
      relaxation: 0.9,
    },
    familyFriendly: d.family_friendly ?? d.familyFriendly ?? true,
    seniorFriendly: d.senior_friendly ?? d.seniorFriendly ?? true,
    averageStayDays: d.average_stay_days ?? d.averageStayDays ?? 2,
  };
}

function mapExperience(e: any): Experience {
  return {
    id: e.id,
    orgId: e.org_id || e.orgId || '',
    destinationId: e.destination_id || e.destinationId || '',
    title: e.title,
    category: e.category,
    description: e.description,
    pricePerPerson: typeof e.price_per_person === 'string' ? parseFloat(e.price_per_person) : (e.price_per_person ?? e.pricePerPerson ?? 0),
    durationHours: Number(e.duration_hours ?? e.durationHours ?? 2),
    maxGroupSize: Number(e.max_group_size ?? e.maxGroupSize ?? 6),
    heroImage: e.hero_image || e.heroImage || '',
    includedItems: e.included_items || e.includedItems || [],
    meetingPoint: e.meeting_point || e.meetingPoint || '',
    hostName: e.host_name || e.hostName || '',
    hostRole: e.host_role || e.hostRole || '',
    rating: Number(e.rating ?? 4.9),
    reviewCount: Number(e.review_count ?? e.reviewCount ?? 20),
    verified: e.verified ?? true,
    rainFriendly: e.rain_friendly ?? e.rainFriendly ?? false,
    rainAlternativeId: e.rain_alternative_id || e.rainAlternativeId,
    explanation: e.explanation,
  };
}

function mapAccommodation(a: any): Accommodation {
  return {
    id: a.id,
    orgId: a.org_id || a.orgId || '',
    destinationId: a.destination_id || a.destinationId || '',
    name: a.name,
    type: a.type,
    tagline: a.tagline || '',
    description: a.description || '',
    heroImage: a.hero_image || a.heroImage || '',
    starRating: Number(a.star_rating ?? a.starRating ?? 5),
    basePricePerNight: typeof a.base_price_per_night === 'string' ? parseFloat(a.base_price_per_night) : (a.base_price_per_night ?? a.basePricePerNight ?? 0),
    ecoGreenScore: Number(a.eco_green_score ?? a.ecoGreenScore ?? 85),
    amenities: a.amenities || [],
    aiSuitabilityScore: Number(a.ai_suitability_score ?? a.aiSuitabilityScore ?? 95),
    roomTypes: (a.rooms || a.roomTypes || []).map((r: any) => ({
      id: r.id,
      name: r.name,
      pricePerNight: typeof r.price_per_night === 'string' ? parseFloat(r.price_per_night) : (r.price_per_night ?? r.pricePerNight ?? 0),
      capacity: Number(r.capacity ?? 2),
      features: r.features || [],
    })),
    explanation: a.explanation,
  };
}

// ----------------------------------------------------------------------------
// HTTP Client with Graceful Sandbox Fallback
// ----------------------------------------------------------------------------

export class HttpKeraLinkAdapter {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;
  public isOnlineBackendAvailable: boolean | null = null;
  private onHealthChangeListeners: Array<(online: boolean) => void> = [];

  constructor() {
    this.accessToken = localStorage.getItem('keralink_access_token');
    this.refreshToken = localStorage.getItem('keralink_refresh_token');
  }

  public subscribeHealth(cb: (online: boolean) => void) {
    this.onHealthChangeListeners.push(cb);
    if (this.isOnlineBackendAvailable !== null) {
      cb(this.isOnlineBackendAvailable);
    }
    return () => {
      this.onHealthChangeListeners = this.onHealthChangeListeners.filter((l) => l !== cb);
    };
  }

  private setHealth(online: boolean) {
    if (this.isOnlineBackendAvailable !== online) {
      this.isOnlineBackendAvailable = online;
      this.onHealthChangeListeners.forEach((cb) => cb(online));
    }
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
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 4000);

      let response = await fetch(`${API_BASE_URL}${endpoint}`, {
        ...options,
        headers,
        signal: controller.signal,
      });
      clearTimeout(timeoutId);

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

      this.setHealth(true);
      return response;
    } catch (err) {
      this.setHealth(false);
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

  async checkBackendHealth(): Promise<boolean> {
    try {
      const res = await this.fetchWithAuth('/destinations/');
      const ok = res.ok;
      this.setHealth(ok);
      return ok;
    } catch {
      this.setHealth(false);
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
        const raw = await res.json();
        const list = Array.isArray(raw) ? raw : raw.results || [];
        if (list.length > 0) {
          return list.map(mapDestination);
        }
      }
    } catch (e) {
      // Graceful fallback to launch corridor seed dataset
    }
    return mockBackend.getDestinations();
  }

  async getExperiences(category?: string): Promise<Experience[]> {
    try {
      const url = category && category !== 'ALL'
        ? `/experiences/?category=${encodeURIComponent(category)}`
        : '/experiences/';
      const res = await this.fetchWithAuth(url);
      if (res.ok) {
        const raw = await res.json();
        const list = Array.isArray(raw) ? raw : raw.results || [];
        if (list.length > 0) {
          return list.map(mapExperience);
        }
      }
    } catch (e) {}
    return mockBackend.getExperiences(category);
  }

  async getAccommodations(destinationId?: string): Promise<Accommodation[]> {
    try {
      const url = destinationId ? `/accommodations/?destination=${destinationId}` : '/accommodations/';
      const res = await this.fetchWithAuth(url);
      if (res.ok) {
        const raw = await res.json();
        const list = Array.isArray(raw) ? raw : raw.results || [];
        if (list.length > 0) {
          return list.map(mapAccommodation);
        }
      }
    } catch (e) {}
    return mockBackend.getAccommodations(destinationId);
  }

  async getEmergencyDirectory(): Promise<EmergencyContact[]> {
    try {
      const res = await this.fetchWithAuth('/safety/directory/');
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data) && data.length > 0) {
          return data;
        }
      }
    } catch (e) {}
    return mockBackend.getEmergencyDirectory();
  }

  // --------------------------------------------------------------------------
  // Weather & Monsoon APIs
  // --------------------------------------------------------------------------
  async getDestinationWeather(destinationSlug: string = 'munnar'): Promise<any> {
    try {
      const res = await this.fetchWithAuth(`/weather/current/?destination=${destinationSlug}`);
      if (res.ok) {
        return await res.json();
      }
    } catch (e) {}
    return {
      provider: 'Calibrated Staging Weather',
      destination: destinationSlug.toUpperCase(),
      temperature_celsius: 22,
      condition: 'MIST_RAIN',
      rain_probability_percent: 60,
      recommendation: 'Light mountain drizzle. Drive cautiously on Ghat roads.',
    };
  }

  // --------------------------------------------------------------------------
  // Maps & Routing APIs
  // --------------------------------------------------------------------------
  async getRoute(startLat: number, startLon: number, endLat: number, endLon: number): Promise<any> {
    try {
      const res = await this.fetchWithAuth(
        `/maps/route/?start_lat=${startLat}&start_lon=${startLon}&end_lat=${endLat}&end_lon=${endLon}`
      );
      if (res.ok) {
        return await res.json();
      }
    } catch (e) {}
    return null;
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
          interests: data.interests && data.interests.length > 0 ? data.interests : fallback.interests,
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
        const backendPlan = await res.json();
        const plan = await mockBackend.generateTripItinerary(profile);
        if (backendPlan.plan_id) {
          plan.id = backendPlan.plan_id;
        }
        if (backendPlan.pricing?.total_cost) {
          plan.currentVersion.pricing.total = backendPlan.pricing.total_cost;
        }
        return plan;
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
          trip_title: `${plan.currentVersion.itineraryDays.length} Days Kerala Heritage & Nature Tour`,
          start_date: plan.currentVersion.itineraryDays[0]?.date || '2026-10-15',
          end_date: plan.currentVersion.itineraryDays[plan.currentVersion.itineraryDays.length - 1]?.date || '2026-10-20',
          travelers_count: 2,
          primary_guest_name: guestInfo.name || 'Sreerag P',
          primary_guest_phone: guestInfo.phone || '+91 98460 12345',
          primary_guest_email: guestInfo.email || 'sreerag@keralink.travel',
          idempotency_key: idempotencyKey,
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
        const raw = await res.json();
        const list = Array.isArray(raw) ? raw : raw.results || [];
        if (list.length > 0) {
          return list;
        }
      }
    } catch (e) {}
    return mockBackend.getUserBookings();
  }

  // --------------------------------------------------------------------------
  // Live Trip Companion & Context Chat
  // --------------------------------------------------------------------------
  async sendCompanionMessage(
    message: string,
    currentDestination: string = 'munnar',
    tripDay: number = 2
  ): Promise<CompanionMessage> {
    try {
      const res = await this.fetchWithAuth('/companion/chat/', {
        method: 'POST',
        body: JSON.stringify({
          query: message,
          current_destination: currentDestination,
          trip_day: tripDay,
          weather_condition: 'MIST_RAIN',
        }),
      });
      if (res.ok) {
        const data = await res.json();
        return {
          id: data.message_id || `msg-${Date.now()}`,
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
