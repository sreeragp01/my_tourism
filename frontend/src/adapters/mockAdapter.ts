import {
  User,
  UserSession,
  AuthResponseData,
  Destination,
  Experience,
  Accommodation,
  TripProfile,
  AIPlan,
  AIPlanVersion,
  ItineraryDay,
  Booking,
  BookingStatus,
  PriceBreakdown,
  CompanionMessage,
  ProviderDashboardMetrics,
  AdminKPIs,
  EmergencyContact,
} from '../types/contracts';
import { KERALA_DESTINATIONS, KERALA_EXPERIENCES, KERALA_ACCOMMODATIONS, KERALA_EMERGENCY_CONTACTS } from '../data/keralaData';

// Generate mock UUID
const uid = () => 'kl-' + Math.random().toString(36).substring(2, 10) + '-' + Date.now().toString(36);

// Initial Current User
let currentUser: User = {
  id: 'usr-sreerag-01',
  email: 'sreerag@keralink.travel',
  phone: '+91 98460 12345',
  firstName: 'Sreerag',
  lastName: 'P',
  avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
  isEmailVerified: true,
  isPhoneVerified: true,
  roles: ['CUSTOMER'],
  createdAt: '2026-01-15T10:00:00Z',
};

// Initial Active Sessions
let activeSessions: UserSession[] = [
  {
    id: 'sess-chrome-win',
    userId: 'usr-sreerag-01',
    deviceId: 'win-chrome-981',
    deviceName: 'Chrome 128 · Windows 11',
    platform: 'WEB',
    ipAddress: '103.28.246.12 (Kochi, India)',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    lastActive: 'Just now',
    expiresAt: '2026-09-20T10:00:00Z',
    isCurrent: true,
  },
  {
    id: 'sess-keralink-android',
    userId: 'usr-sreerag-01',
    deviceId: 'pixel-8-pro',
    deviceName: 'KeraLink App · Pixel 8 Pro',
    platform: 'ANDROID',
    ipAddress: '103.28.246.12 (Kochi, India)',
    userAgent: 'KeraLink Mobile/1.2.0 (Android 15)',
    lastActive: '12 mins ago',
    expiresAt: '2026-09-25T14:30:00Z',
    isCurrent: false,
  },
];

// In-Memory Saved Trips & Plans
const savedPlans = new Map<string, AIPlan>();
const bookingsMap = new Map<string, Booking>();

// Helper to calculate total price
const calculatePricing = (days: ItineraryDay[], travelers: number): PriceBreakdown => {
  let staysTotal = 0;
  let experiencesTotal = 0;

  days.forEach((day) => {
    if (day.accommodation) {
      staysTotal += day.accommodation.basePricePerNight;
    }
    day.timeline.forEach((event) => {
      if (event.type === 'EXPERIENCE' || event.type === 'ACTIVITY') {
        experiencesTotal += event.cost * travelers;
      }
    });
  });

  const transportTotal = days.length * 2800; // Average private AC sedan/SUV per day
  const mealsEstimate = days.length * 1200 * travelers;
  const subtotal = staysTotal + transportTotal + experiencesTotal + mealsEstimate;
  const taxesAndFees = Math.round(subtotal * 0.05); // 5% GST & Platform
  const discount = Math.round(subtotal * 0.04); // KeraLink Special discount
  const total = subtotal + taxesAndFees - discount;

  return {
    staysTotal,
    transportTotal,
    experiencesTotal,
    mealsEstimate,
    taxesAndFees,
    discount,
    total,
  };
};

export class MockKeraLinkAdapter {
  // --------------------------------------------------------------------------
  // Auth & Session Management
  // --------------------------------------------------------------------------
  async getCurrentUser(): Promise<User> {
    return { ...currentUser };
  }

  async switchRole(role: User['roles'][0]): Promise<User> {
    currentUser = {
      ...currentUser,
      roles: [role],
      organizationId: role.startsWith('PROVIDER') ? 'org-munnar-tea' : undefined,
    };
    return { ...currentUser };
  }

  async getActiveSessions(): Promise<UserSession[]> {
    return [...activeSessions];
  }

  async revokeSession(sessionId: string): Promise<boolean> {
    activeSessions = activeSessions.filter((s) => s.id !== sessionId);
    return true;
  }

  async revokeAllSessions(): Promise<boolean> {
    activeSessions = activeSessions.filter((s) => s.isCurrent);
    return true;
  }

  // --------------------------------------------------------------------------
  // Tourism Discovery
  // --------------------------------------------------------------------------
  async getDestinations(): Promise<Destination[]> {
    return [...KERALA_DESTINATIONS];
  }

  async getDestinationBySlug(slug: string): Promise<Destination | undefined> {
    return KERALA_DESTINATIONS.find((d) => d.slug === slug || d.id === slug);
  }

  async getExperiences(category?: string): Promise<Experience[]> {
    if (!category || category === 'ALL') {
      return [...KERALA_EXPERIENCES];
    }
    return KERALA_EXPERIENCES.filter((e) => e.category === category);
  }

  async getAccommodations(destinationId?: string): Promise<Accommodation[]> {
    if (!destinationId) {
      return [...KERALA_ACCOMMODATIONS];
    }
    return KERALA_ACCOMMODATIONS.filter((a) => a.destinationId === destinationId);
  }

  async getEmergencyDirectory(): Promise<EmergencyContact[]> {
    return [...KERALA_EMERGENCY_CONTACTS];
  }

  // --------------------------------------------------------------------------
  // AI Travel Architect: NLP Parser & Trip Generation
  // --------------------------------------------------------------------------
  async parseNaturalLanguagePrompt(prompt: string): Promise<TripProfile> {
    const lower = prompt.toLowerCase();
    
    // Extract duration (e.g. 5 days, 6 days)
    let durationDays = 6;
    const daysMatch = lower.match(/(\d+)\s*(days|day)/);
    if (daysMatch) {
      durationDays = parseInt(daysMatch[1], 10);
    }

    // Extract budget (e.g. 80k, 80000, 50k, 1.5L)
    let budgetLimit = 80000;
    const budgetMatch = lower.match(/(?:budget|₹|rs\.?|inr)?\s*(\d+)(k|lakh|l)?/i);
    if (budgetMatch) {
      const num = parseInt(budgetMatch[1], 10);
      const unit = budgetMatch[2]?.toLowerCase();
      if (unit === 'k') budgetLimit = num * 1000;
      else if (unit === 'l' || unit === 'lakh') budgetLimit = num * 100000;
      else if (num > 1000) budgetLimit = num;
    }

    // Extract interests
    const interests: string[] = [];
    if (lower.includes('nature') || lower.includes('green') || lower.includes('hills') || lower.includes('mountain')) interests.push('Nature');
    if (lower.includes('beach') || lower.includes('sea') || lower.includes('cliff') || lower.includes('coast')) interests.push('Beaches');
    if (lower.includes('food') || lower.includes('culinary') || lower.includes('seafood') || lower.includes('toddy')) interests.push('Food');
    if (lower.includes('culture') || lower.includes('theyyam') || lower.includes('kathakali') || lower.includes('heritage')) interests.push('Culture');
    if (lower.includes('romance') || lower.includes('couple') || lower.includes('wife') || lower.includes('honeymoon')) interests.push('Romance');
    if (lower.includes('adventure') || lower.includes('trek') || lower.includes('rafting') || lower.includes('kayak')) interests.push('Adventure');
    if (lower.includes('backwater') || lower.includes('boat') || lower.includes('houseboat')) interests.push('Backwaters');
    if (lower.includes('peace') || lower.includes('relax') || lower.includes('calm') || lower.includes('wellness')) interests.push('Relaxation');

    if (interests.length === 0) {
      interests.push('Nature', 'Food', 'Backwaters');
    }

    // Extract avoidance
    const avoidances: string[] = [];
    if (lower.includes('no long drive') || lower.includes('less driving') || lower.includes("don't want too much driving")) {
      avoidances.push('Long Drives');
    }
    if (lower.includes('no trek') || lower.includes('less walking')) {
      avoidances.push('Heavy Trekking');
    }

    // Travelers
    let adults = 2;
    if (lower.includes('solo') || lower.includes('myself')) adults = 1;
    else if (lower.includes('family') || lower.includes('parents')) adults = 3;
    else if (lower.includes('friends') || lower.includes('group')) adults = 4;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() + 14); // 2 weeks from today
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + durationDays - 1);

    return {
      id: uid(),
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
      durationDays,
      adults,
      children: 0,
      infants: 0,
      startingLocation: 'Kochi (COK)',
      endingLocation: 'Kochi / Trivandrum',
      budgetLimit,
      travelStyle: budgetLimit > 100000 ? 'LUXURY' : budgetLimit > 60000 ? 'PREMIUM' : 'COMFORT',
      pace: lower.includes('packed') ? 'PACKED' : 'RELAXED',
      transportPreference: 'SEDAN',
      interests,
      avoidances,
      rawPrompt: prompt,
    };
  }

  async generateTripItinerary(profile: TripProfile): Promise<AIPlan> {
    const days: ItineraryDay[] = [];
    const travelers = profile.adults + profile.children;

    // Build realistic 6-day Kerala corridor: Kochi -> Munnar -> Thekkady -> Alleppey -> Varkala -> Departure
    // Day 1: Kochi Arrival & Colonial Heritage
    days.push({
      dayNumber: 1,
      date: profile.startDate,
      destinationId: 'kochi',
      destinationName: 'Fort Kochi',
      destinationHero: 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80',
      themeTitle: 'Gateway to Malabar & Colonial Spice Coast',
      accommodation: KERALA_ACCOMMODATIONS[0],
      timeline: [
        { id: uid(), time: '11:00', type: 'TRANSIT', title: 'Airport Pickup in Private AC Sedan', durationMins: 60, cost: 0, locationName: 'Cochin Int Airport (COK)' },
        { id: uid(), time: '13:00', type: 'MEAL', title: 'Welcome Coastal Malabar Lunch at Seagull', durationMins: 75, cost: 650, locationName: 'Fort Kochi Waterfront' },
        { id: uid(), time: '15:30', type: 'ACTIVITY', title: 'Historic Walk: Chinese Fishing Nets & Jew Town', durationMins: 90, cost: 200, locationName: 'Mattancherry & Fort Kochi' },
        { id: uid(), time: '18:30', type: 'EXPERIENCE', title: 'Sacred Kathakali & Greenroom Mudra Experience', durationMins: 120, cost: 1800, locationName: 'Kerala Kathakali Centre', experienceId: 'exp-theyyam-ritual' },
        { id: uid(), time: '21:00', type: 'MEAL', title: 'Fresh Catch Seafood Dinner by the Sea', durationMins: 60, cost: 950, locationName: 'Old Harbour Restaurant' },
      ],
      transfers: [{ fromDestination: 'Kochi Airport', toDestination: 'Fort Kochi', distanceKm: 42, durationMinutes: 65, mode: 'SEDAN', scenicHighlights: ['Marine Drive Harbour View', 'Willingdon Island Island Bridge'] }],
      dayEstimatedCost: 11200,
    });

    // Day 2: Munnar Mountain Escapade
    days.push({
      dayNumber: 2,
      date: new Date(new Date(profile.startDate).getTime() + 86400000).toISOString().split('T')[0],
      destinationId: 'munnar',
      destinationName: 'Munnar Hills',
      destinationHero: 'https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=800&q=80',
      themeTitle: 'Ascent to the Emerald Mist & Cloud Forests',
      accommodation: KERALA_ACCOMMODATIONS[0], // Fragrant Nature Munnar
      timeline: [
        { id: uid(), time: '08:00', type: 'MEAL', title: 'Appam & Vegetable Stew Breakfast', durationMins: 45, cost: 350, locationName: 'Hotel Dining' },
        { id: uid(), time: '09:00', type: 'TRANSIT', title: 'Scenic Ghat Road Ascent with Cheeyappara Waterfall Stop', durationMins: 195, cost: 0, locationName: 'NH85 Mountain Highway' },
        { id: uid(), time: '13:00', type: 'MEAL', title: 'Plantation Lunch at Farmstead Kitchen', durationMins: 60, cost: 500, locationName: 'Munnar Valley' },
        { id: uid(), time: '14:30', type: 'EXPERIENCE', title: 'Heritage Tea Estate Walk & Tasting with Master Planter', durationMins: 150, cost: 1200, locationName: 'Lockhart Estate', experienceId: 'exp-tea-plantation' },
        { id: uid(), time: '18:30', type: 'LEISURE', title: 'Sunset Valley Mist View from Private Jacuzzi / Balcony', durationMins: 60, cost: 0, locationName: 'Fragrant Nature Resort' },
        { id: uid(), time: '20:00', type: 'MEAL', title: 'Candlelight Hearthside Dinner', durationMins: 90, cost: 1100, locationName: 'The Glasshouse Restaurant' },
      ],
      transfers: [{ fromDestination: 'Kochi', toDestination: 'Munnar', distanceKm: 128, durationMinutes: 210, mode: 'SEDAN', scenicHighlights: ['Cheeyappara & Valara Cascades', 'Pine Forests', 'Rolling Tea Slopes'] }],
      dayEstimatedCost: 14800,
    });

    // Day 3: High-Altitude Wildlife & Viewpoints
    days.push({
      dayNumber: 3,
      date: new Date(new Date(profile.startDate).getTime() + 86400000 * 2).toISOString().split('T')[0],
      destinationId: 'munnar',
      destinationName: 'Munnar Peaks',
      destinationHero: 'https://images.unsplash.com/photo-1616489953149-808602b937e2?auto=format&fit=crop&w=800&q=80',
      themeTitle: 'Nilgiri Tahr Sanctuaries & Mountain Echoes',
      accommodation: KERALA_ACCOMMODATIONS[0],
      timeline: [
        { id: uid(), time: '07:30', type: 'ACTIVITY', title: 'Morning Safari at Eravikulam National Park (Rajamalai)', durationMins: 150, cost: 650, locationName: 'Eravikulam Sanctuary' },
        { id: uid(), time: '11:00', type: 'ACTIVITY', title: 'Mattupetty Dam Speedboat & Kundala Lake Reflection', durationMins: 90, cost: 500, locationName: 'Kundala Dam' },
        { id: uid(), time: '13:00', type: 'MEAL', title: 'Traditional Banana Leaf Thali Lunch', durationMins: 60, cost: 400, locationName: 'Rapsy Restaurant' },
        { id: uid(), time: '15:30', type: 'EXPERIENCE', title: 'Organic Spice Garden Tour & Aromatic Herbal Sampling', durationMins: 90, cost: 450, locationName: 'Highland Spice Gardens' },
        { id: uid(), time: '18:30', type: 'LEISURE', title: 'Sunset at Top Station Clouds Viewpoint', durationMins: 75, cost: 0, locationName: 'Top Station' },
        { id: uid(), time: '20:30', type: 'MEAL', title: 'Kerala Malabar Parotta & Duck Roast Dinner', durationMins: 60, cost: 850, locationName: 'Munnar Heritage Club' },
      ],
      dayEstimatedCost: 13500,
    });

    // Day 4: Backwaters of Alleppey & Private Houseboat
    days.push({
      dayNumber: 4,
      date: new Date(new Date(profile.startDate).getTime() + 86400000 * 3).toISOString().split('T')[0],
      destinationId: 'alleppey',
      destinationName: 'Alleppey Backwaters',
      destinationHero: 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80',
      themeTitle: 'Venetian Lagoons & Private Thatched Houseboat',
      accommodation: KERALA_ACCOMMODATIONS[1], // Luxury Houseboat
      timeline: [
        { id: uid(), time: '08:30', type: 'TRANSIT', title: 'Descend Ghats Towards Arabian Coast Backwaters', durationMins: 210, cost: 0, locationName: 'Munnar → Alleppey Jetty' },
        { id: uid(), time: '12:30', type: 'STAY_CHECKIN', title: 'Board Exclusive 1-BHK Air-Conditioned Luxury Kettuvallam', durationMins: 30, cost: 0, locationName: 'Punnamada Jetty' },
        { id: uid(), time: '13:00', type: 'MEAL', title: 'On-Board Fresh Pearl Spot (Karimeen) & Red Rice Lunch', durationMins: 75, cost: 0, locationName: 'Private Houseboat Dining' },
        { id: uid(), time: '16:00', type: 'EXPERIENCE', title: 'Silent Sunset Canoe & Kayak Through Village Canals', durationMins: 120, cost: 1500, locationName: 'Kainakary Village', experienceId: 'exp-sunset-kayak' },
        { id: uid(), time: '18:30', type: 'LEISURE', title: 'Anchor at Vembanad Lake for Golden Sunset & Stargazing', durationMins: 90, cost: 0, locationName: 'Vembanad Lake' },
        { id: uid(), time: '20:30', type: 'MEAL', title: 'Candlelight Chef-Curated Dinner Floating Under Palm Canopy', durationMins: 60, cost: 0, locationName: 'Private Houseboat Deck' },
      ],
      transfers: [{ fromDestination: 'Munnar', toDestination: 'Alleppey', distanceKm: 165, durationMinutes: 240, mode: 'SEDAN', scenicHighlights: ['Rubber Plantations', 'Paddy Polders Below Sea Level'] }],
      dayEstimatedCost: 17400,
    });

    // Day 5: Red Cliffs of Varkala
    days.push({
      dayNumber: 5,
      date: new Date(new Date(profile.startDate).getTime() + 86400000 * 4).toISOString().split('T')[0],
      destinationId: 'varkala',
      destinationName: 'Varkala Beach & Cliffs',
      destinationHero: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=800&q=80',
      themeTitle: 'Laterite Clifftops & Bohemian Sunset Sanctuaries',
      accommodation: KERALA_ACCOMMODATIONS[3], // Cliffehouse Varkala
      timeline: [
        { id: uid(), time: '08:30', type: 'MEAL', title: 'Houseboat Deck Breakfast: Fresh Tropical Fruits & Idli', durationMins: 45, cost: 0, locationName: 'Houseboat' },
        { id: uid(), time: '09:30', type: 'TRANSIT', title: 'Coastal Drive Along Arabian Sea to North Cliff Varkala', durationMins: 130, cost: 0, locationName: 'Alleppey → Varkala' },
        { id: uid(), time: '12:30', type: 'MEAL', title: 'Woodfired Seafood Pizza & Coconut Smoothies at Cafe del Mar', durationMins: 60, cost: 750, locationName: 'North Cliff Walkway' },
        { id: uid(), time: '15:00', type: 'ACTIVITY', title: 'Natural Mineral Spring Dip & Papanasam Holy Beach Stroll', durationMins: 90, cost: 0, locationName: 'Papanasam Beach' },
        { id: uid(), time: '18:00', type: 'LEISURE', title: 'Sunset Clifftop Meditation & Arabian Sea Panorama', durationMins: 60, cost: 0, locationName: 'North Cliff Viewpoint' },
        { id: uid(), time: '20:00', type: 'MEAL', title: 'Candlelight Clifftop Grill & Acoustic Live Music', durationMins: 90, cost: 1200, locationName: 'Darjeeling Cafe / Cliffehouse' },
      ],
      transfers: [{ fromDestination: 'Alleppey', toDestination: 'Varkala', distanceKm: 110, durationMinutes: 150, mode: 'SEDAN', scenicHighlights: ['Coastal Highway NH66', 'Kollam Ashtamudi Lake Gateway'] }],
      dayEstimatedCost: 11500,
    });

    // Day 6: Departure with Heartfelt Memories
    days.push({
      dayNumber: 6,
      date: new Date(new Date(profile.startDate).getTime() + 86400000 * 5).toISOString().split('T')[0],
      destinationId: 'varkala',
      destinationName: 'Trivandrum / Kochi',
      destinationHero: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=800&q=80',
      themeTitle: 'Spices, Souvenirs & Gentle Departure',
      timeline: [
        { id: uid(), time: '08:00', type: 'LEISURE', title: 'Sunrise Yoga on the Clifftop Deck', durationMins: 60, cost: 0, locationName: 'Cliffehouse Yoga Deck' },
        { id: uid(), time: '09:30', type: 'MEAL', title: 'Artisanal Breakfast with Spiced French Toast & Filter Coffee', durationMins: 45, cost: 450, locationName: 'Ocean View Verandah' },
        { id: uid(), time: '11:00', type: 'ACTIVITY', title: 'Last-minute Artisanal Shopping: Banana Chips & Spices', durationMins: 60, cost: 500, locationName: 'Varkala Promenade' },
        { id: uid(), time: '13:00', type: 'TRANSIT', title: 'Private Transfer to Trivandrum (TRV) / Cochin Airport', durationMins: 75, cost: 0, locationName: 'TRV Int Airport' },
      ],
      transfers: [{ fromDestination: 'Varkala', toDestination: 'Trivandrum Airport (TRV)', distanceKm: 45, durationMinutes: 70, mode: 'SEDAN', scenicHighlights: ['Anjengo Fort & Coconut Groves'] }],
      dayEstimatedCost: 4500,
    });

    const pricing = calculatePricing(days, travelers);

    const initialVersion: AIPlanVersion = {
      id: uid(),
      planId: '',
      versionNumber: 1,
      changeReason: 'AI Travel Architect Initial Synthesis',
      itineraryDays: days,
      pricing,
      totalDistanceKm: 485,
      totalTravelHours: 11.2,
      greenTripScore: 88,
      createdAt: new Date().toISOString(),
    };

    const planId = uid();
    initialVersion.planId = planId;

    const newPlan: AIPlan = {
      id: planId,
      tripProfileId: profile.id,
      currentVersionId: initialVersion.id,
      currentVersion: initialVersion,
      allVersions: [initialVersion],
      status: 'FINALIZED',
    };

    savedPlans.set(planId, newPlan);
    return newPlan;
  }

  async regenerateDay(
    planId: string,
    dayNumber: number,
    modification: 'MAKE_CHEAPER' | 'RAIN_FRIENDLY' | 'ADD_ADVENTURE' | 'MORE_LOCAL' | 'FOOD_FOCUSED'
  ): Promise<AIPlan> {
    const existingPlan = savedPlans.get(planId);
    if (!existingPlan) {
      throw new Error(`Plan ${planId} not found`);
    }

    const currentVersion = existingPlan.currentVersion;
    const clonedDays: ItineraryDay[] = JSON.parse(JSON.stringify(currentVersion.itineraryDays));
    const targetDayIndex = clonedDays.findIndex((d) => d.dayNumber === dayNumber);

    if (targetDayIndex === -1) {
      throw new Error(`Day ${dayNumber} not found in itinerary`);
    }

    let changeReason = `Modified Day ${dayNumber}`;

    if (modification === 'RAIN_FRIENDLY') {
      changeReason = `Monsoon Adaptation for Day ${dayNumber}: Swapped outdoor activities for sheltered spice masterclass and Kathakali`;
      clonedDays[targetDayIndex].timeline = [
        { id: uid(), time: '09:00', type: 'MEAL', title: 'Warm Kerala Kadala Curry & Puttu Breakfast', durationMins: 45, cost: 300, locationName: 'Resort Dining' },
        { id: uid(), time: '10:30', type: 'EXPERIENCE', title: 'Indoor Covered Tea Factory & Cupping Masterclass', durationMins: 120, cost: 1200, locationName: 'Lockhart Historic Tea Museum', isRainAlternative: true },
        { id: uid(), time: '13:30', type: 'MEAL', title: 'Traditional Claypot Fish Curry Meals', durationMins: 60, cost: 450, locationName: 'Hillside Heritage Kitchen' },
        { id: uid(), time: '15:30', type: 'EXPERIENCE', title: 'Ayurvedic Abhyanga Herbal Massage & Steam Therapy', durationMins: 90, cost: 2200, locationName: 'Ayur Heritage Spa', isRainAlternative: true },
        { id: uid(), time: '18:30', type: 'EXPERIENCE', title: 'Indoor Kalaripayattu Martial Arts Demonstration', durationMins: 60, cost: 800, locationName: 'Munnar Cultural Centre', isRainAlternative: true },
        { id: uid(), time: '20:30', type: 'MEAL', title: 'Chef Signature Kerala Stew by the Fireplace', durationMins: 60, cost: 950, locationName: 'Cozy Fireside Lounge' },
      ];
    } else if (modification === 'MAKE_CHEAPER') {
      changeReason = `Budget Optimization for Day ${dayNumber}: Selected eco-homestay stay and authentic local street trails`;
      clonedDays[targetDayIndex].accommodation = {
        ...KERALA_ACCOMMODATIONS[0],
        name: 'Munnar Valley Eco Heritage Homestay',
        basePricePerNight: 3500,
        type: 'HERITAGE_HOMESTAY',
      };
      clonedDays[targetDayIndex].timeline.forEach((t) => {
        t.cost = Math.round(t.cost * 0.6);
      });
    } else if (modification === 'ADD_ADVENTURE') {
      changeReason = `Adventure Booster for Day ${dayNumber}: Added high-altitude trekking and off-road 4x4 trails`;
      clonedDays[targetDayIndex].timeline = [
        { id: uid(), time: '06:30', type: 'ACTIVITY', title: 'Sunrise Mountain Ridge Trek to Meesapulimala Base', durationMins: 210, cost: 1400, locationName: 'Western Ghats Ridge' },
        { id: uid(), time: '11:00', type: 'MEAL', title: 'Trailhead Packed Breakfast & Electrolyte Refreshment', durationMins: 45, cost: 250, locationName: 'Basecamp' },
        { id: uid(), time: '13:00', type: 'EXPERIENCE', title: '4x4 Off-Road Jeep Safari Across Rugged Tea Peaks', durationMins: 150, cost: 1800, locationName: 'Kolukkumalai High Estate' },
        { id: uid(), time: '17:30', type: 'ACTIVITY', title: 'Zip-line Over Emerald Mountain Valley', durationMins: 45, cost: 850, locationName: 'Adventure Valley Munnar' },
        { id: uid(), time: '19:30', type: 'MEAL', title: 'Campfire Barbeque Under the Stars', durationMins: 90, cost: 950, locationName: 'Highland Camp' },
      ];
    }

    const updatedPricing = calculatePricing(clonedDays, 2);

    const newVersion: AIPlanVersion = {
      id: uid(),
      planId,
      versionNumber: currentVersion.versionNumber + 1,
      changeReason,
      itineraryDays: clonedDays,
      pricing: updatedPricing,
      totalDistanceKm: currentVersion.totalDistanceKm,
      totalTravelHours: currentVersion.totalTravelHours,
      greenTripScore: modification === 'MAKE_CHEAPER' ? 92 : 88,
      createdAt: new Date().toISOString(),
    };

    const updatedPlan: AIPlan = {
      ...existingPlan,
      currentVersionId: newVersion.id,
      currentVersion: newVersion,
      allVersions: [newVersion, ...existingPlan.allVersions],
    };

    savedPlans.set(planId, updatedPlan);
    return updatedPlan;
  }

  // --------------------------------------------------------------------------
  // Transactional Booking & Payment Flow
  // --------------------------------------------------------------------------
  async createBookingFromPlan(
    plan: AIPlan,
    guestInfo: { name: string; phone: string; email: string }
  ): Promise<Booking> {
    const bookingId = uid();
    const reference = 'KL' + new Date().getFullYear().toString().slice(-2) + (Math.floor(10000000 + Math.random() * 90000000)).toString();

    const holdExpires = new Date();
    holdExpires.setMinutes(holdExpires.getMinutes() + 15); // 15 min lock

    const newBooking: Booking = {
      id: bookingId,
      bookingReference: reference,
      userId: currentUser.id,
      planVersionId: plan.currentVersion.id,
      tripTitle: `${plan.currentVersion.itineraryDays.length} Days Romantic Kerala Nature Escape`,
      startDate: plan.currentVersion.itineraryDays[0]?.date || '2026-06-20',
      endDate: plan.currentVersion.itineraryDays[plan.currentVersion.itineraryDays.length - 1]?.date || '2026-06-25',
      travelersCount: 2,
      primaryGuestName: guestInfo.name,
      primaryGuestPhone: guestInfo.phone,
      primaryGuestEmail: guestInfo.email,
      items: [
        { id: uid(), type: 'ROOM', title: 'Fragrant Nature Munnar (3 Nights)', date: '2026-06-20', units: 1, unitPrice: 28500, subtotal: 28500, providerOrgId: 'org-fragrant-nature' },
        { id: uid(), type: 'ROOM', title: 'Lakes & Lagoons Luxury Houseboat (1 Night)', date: '2026-06-23', units: 1, unitPrice: 14000, subtotal: 14000, providerOrgId: 'org-alleppey-houseboats' },
        { id: uid(), type: 'ROOM', title: 'Cliffehouse Varkala Ocean Suite (1 Night)', date: '2026-06-24', units: 1, unitPrice: 6500, subtotal: 6500, providerOrgId: 'org-varkala-villas' },
        { id: uid(), type: 'TRANSPORT', title: 'Dedicated Chauffeur AC Sedan (6 Days)', date: '2026-06-20', units: 6, unitPrice: 2650, subtotal: 15900, providerOrgId: 'org-kerala-transport' },
        { id: uid(), type: 'EXPERIENCE', title: 'Heritage Tea Estate & Backwater Canoe Experiences', date: '2026-06-21', units: 2, unitPrice: 1800, subtotal: 3600, providerOrgId: 'org-munnar-tea' },
      ],
      pricing: plan.currentVersion.pricing,
      status: 'PENDING_PAYMENT',
      holdExpiresAt: holdExpires.toISOString(),
      idempotencyKey: 'IDEMP-' + uid(),
      greenTripScore: plan.currentVersion.greenTripScore,
      createdAt: new Date().toISOString(),
    };

    bookingsMap.set(bookingId, newBooking);
    return newBooking;
  }

  async confirmBookingPayment(bookingId: string, paymentMethod: string): Promise<Booking> {
    const booking = bookingsMap.get(bookingId);
    if (!booking) throw new Error('Booking not found');

    booking.status = 'CONFIRMED';
    booking.confirmedAt = new Date().toISOString();
    booking.qrCodeDataUrl = `https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=KERALINK-${booking.bookingReference}`;

    bookingsMap.set(bookingId, booking);
    return { ...booking };
  }

  async getUserBookings(): Promise<Booking[]> {
    return Array.from(bookingsMap.values());
  }

  // --------------------------------------------------------------------------
  // Live Trip Companion Chat
  // --------------------------------------------------------------------------
  async sendCompanionMessage(message: string): Promise<CompanionMessage> {
    const lower = message.toLowerCase();
    const timestamp = new Date().toISOString();

    if (lower.includes('rain') || lower.includes('monsoon') || lower.includes('weather')) {
      return {
        id: uid(),
        sender: 'AI_COMPANION',
        text: `🌧️ Munnar has light monsoon showers right now (21°C). I recommend visiting the **Lockhart Historic Tea Museum** or booking a cozy **Ayurvedic Herbal Therapy** at Fragrant Nature Spa instead of open cliff trekking.`,
        timestamp,
        suggestedQuickReplies: ['View indoor alternatives', 'Reschedule outdoor trek', 'Check tomorrow weather'],
        actionCard: {
          type: 'RAIN_ALTERNATIVE',
          title: 'Monsoon-Friendly Activity Found',
          description: 'Lockhart Tea Museum & Indoor Cupping (2.4 km away)',
          ctaLabel: 'Apply Rain Schedule',
        },
      };
    }

    if (lower.includes('food') || lower.includes('restaurant') || lower.includes('eat') || lower.includes('dinner')) {
      return {
        id: uid(),
        sender: 'AI_COMPANION',
        text: `🍛 You're only 1.2 km away from **Rapsy Restaurant** in Munnar Town, legendary for hot Malabar Parottas, beef fry, and authentic cardamom tea. Alternatively, **The Glasshouse** inside your resort offers a candlelit hearthside dinner.`,
        timestamp,
        suggestedQuickReplies: ['Get Directions to Rapsy', 'Reserve Resort Table', 'Show vegetarian places'],
        actionCard: {
          type: 'RESTAURANT_SUGGESTION',
          title: 'Top Local Restaurant: Rapsy',
          description: '4.8 ★ · Authentic Malabar Specialities · 1.2 km',
          ctaLabel: 'Navigate (10 min walk)',
        },
      };
    }

    if (lower.includes('delay') || lower.includes('driver') || lower.includes('traffic')) {
      return {
        id: uid(),
        sender: 'AI_COMPANION',
        text: `🚗 I've alerted your chauffeur, Rajesh. He is currently 8 minutes away navigating light mist near Mattupetty junction. Your tea tasting slot has been automatically pushed by 30 minutes to ensure zero rush.`,
        timestamp,
        suggestedQuickReplies: ['Call Driver Rajesh', 'Share live location', 'Adjust afternoon plan'],
        actionCard: {
          type: 'SCHEDULE_CHANGE',
          title: 'Schedule Adjusted by 30 mins',
          description: 'Tea plantation walk moved to 15:00',
          ctaLabel: 'View Updated Timeline',
        },
      };
    }

    return {
      id: uid(),
      sender: 'AI_COMPANION',
      text: `Namaskaram! 🌴 I am your live KeraLink Companion for your Kerala journey. You are on **Day 2 (Munnar)**. Next up is your **Heritage Tea Estate Walk** at 14:30. How can I assist you right now?`,
      timestamp,
      suggestedQuickReplies: ["What's near me?", "It's raining, what can we do?", 'Find a good restaurant', 'Make today easier'],
    };
  }

  // --------------------------------------------------------------------------
  // Provider Dashboard Metrics
  // --------------------------------------------------------------------------
  async getProviderMetrics(): Promise<ProviderDashboardMetrics> {
    return {
      todayBookingsCount: 4,
      todayRevenue: 48500,
      monthRevenue: 642000,
      activeGuests: 18,
      occupancyRatePercent: 88,
      averageRating: 4.92,
      recentBookings: [
        { id: 'bkg-1', guestName: 'Sreerag P', productName: 'Fragrant Nature Suite', dates: '20 - 23 Jun', amount: 28500, status: 'CONFIRMED' },
        { id: 'bkg-2', guestName: 'Aarav Sharma', productName: 'Heritage Tea Estate Tour', dates: '21 Jun', amount: 2400, status: 'CONFIRMED' },
        { id: 'bkg-3', guestName: 'Meera Nambiar', productName: 'Tropic Green Room', dates: '24 - 26 Jun', amount: 19000, status: 'PENDING_PAYMENT' },
      ],
    };
  }

  // --------------------------------------------------------------------------
  // Admin Global KPIs
  // --------------------------------------------------------------------------
  async getAdminKPIs(): Promise<AdminKPIs> {
    return {
      totalUsers: 18420,
      totalProviders: 642,
      totalBookings: 4821,
      grossMerchandiseValue: 28450000, // ₹2.84 Cr
      activeTripsCount: 1280,
      aiTripsCreated: 7320,
      aiToBookingConversionRate: 8.4,
      pendingProviderVerifications: 5,
    };
  }
}

export const mockBackend = new MockKeraLinkAdapter();
