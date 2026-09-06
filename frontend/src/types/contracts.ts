// ============================================================================
// KERALINK PRODUCTION CONTRACTS (Phase 0: Engineering Contract Freeze)
// ============================================================================

export type UUID = string;
export type ISODateString = string; // e.g. "2026-06-20"
export type ISODateTimeString = string; // e.g. "2026-06-20T08:30:00Z"

// ----------------------------------------------------------------------------
// 1. Core API Standard Response Envelope
// ----------------------------------------------------------------------------
export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  meta?: {
    page?: number;
    total?: number;
    timestamp?: ISODateTimeString;
  };
}

export interface ApiError {
  success: false;
  error: {
    code: string;
    message: string;
    details?: Record<string, string[]>;
  };
}

// ----------------------------------------------------------------------------
// 2. Authentication, Token Rotation & Sessions
// ----------------------------------------------------------------------------
export type UserRole =
  | 'CUSTOMER'
  | 'PROVIDER_OWNER'
  | 'PROVIDER_MANAGER'
  | 'PROVIDER_STAFF'
  | 'GUIDE'
  | 'DRIVER'
  | 'SUPPORT_AGENT'
  | 'CONTENT_MANAGER'
  | 'FINANCE_MANAGER'
  | 'MODERATOR'
  | 'ADMIN'
  | 'SUPER_ADMIN';

export interface User {
  id: UUID;
  email: string;
  phone?: string;
  firstName: string;
  lastName: string;
  avatarUrl?: string;
  isEmailVerified: boolean;
  isPhoneVerified: boolean;
  roles: UserRole[];
  organizationId?: UUID;
  createdAt: ISODateTimeString;
}

export interface UserSession {
  id: UUID;
  userId: UUID;
  deviceId: string;
  deviceName: string;
  platform: 'WEB' | 'ANDROID' | 'IOS';
  ipAddress: string;
  userAgent: string;
  lastActive: ISODateTimeString;
  expiresAt: ISODateTimeString;
  isCurrent: boolean;
}

export interface AuthTokens {
  accessToken: string; // 15 mins in-memory
  refreshTokenExpiresAt: ISODateTimeString;
}

export interface AuthResponseData {
  user: User;
  tokens: AuthTokens;
  activeSession: UserSession;
}

// ----------------------------------------------------------------------------
// 3. Multi-Tenant Organizations & RBAC
// ----------------------------------------------------------------------------
export type OrgType = 'RESORT_HOTEL' | 'HOMESTAY' | 'TOUR_OPERATOR' | 'GUIDE_COLLECTIVE' | 'TRANSPORT_UNION' | 'EXPERIENCE_HOST';
export type OrgStatus = 'DRAFT' | 'SUBMITTED' | 'UNDER_REVIEW' | 'CHANGES_REQUIRED' | 'APPROVED' | 'SUSPENDED';

export interface Organization {
  id: UUID;
  name: string;
  slug: string;
  type: OrgType;
  status: OrgStatus;
  district: string;
  rating: number;
  totalReviews: number;
  verifiedBadge: boolean;
  contactEmail: string;
  contactPhone: string;
  createdAt: ISODateTimeString;
}

// ----------------------------------------------------------------------------
// 4. Tourism Knowledge Graph & Geography
// ----------------------------------------------------------------------------
export interface GeoCoordinates {
  lat: number;
  lng: number;
}

export interface PreferenceVector {
  nature: number;      // 0.0 - 1.0
  romance: number;
  adventure: number;
  culture: number;
  food: number;
  relaxation: number;
}

export interface Destination {
  id: string;
  name: string;
  slug: string;
  district: string;
  tagline: string;
  description: string;
  heroImage: string;
  galleryImages: string[];
  coordinates: GeoCoordinates;
  bestSeason: string;
  tags: string[];
  preferences: PreferenceVector;
  familyFriendly: boolean;
  seniorFriendly: boolean;
  averageStayDays: number;
}

export interface Attraction {
  id: string;
  destinationId: string;
  name: string;
  category: 'NATURE' | 'BEACH' | 'HERITAGE' | 'WATERFALL' | 'WILDLIFE' | 'CULTURE' | 'VIEWPOINT';
  description: string;
  image: string;
  coordinates: GeoCoordinates;
  openingTime: string; // e.g. "06:00"
  closingTime: string; // e.g. "18:00"
  entryFee: number;
  typicalDurationMins: number;
  rainFriendly: boolean;
  crowdProfile: 'LOW' | 'MODERATE' | 'HIGH';
}

// ----------------------------------------------------------------------------
// 5. Experiences, Accommodations & Explainable Scoring
// ----------------------------------------------------------------------------
export interface RecommendationExplanation {
  score: number; // 0 - 100
  reasons: string[];
  isTopPick?: boolean;
}

export type ExperienceCategory = 'CULTURE' | 'FOOD' | 'NATURE' | 'WATER' | 'ADVENTURE' | 'WELLNESS';

export interface Experience {
  id: string;
  orgId: UUID;
  destinationId: string;
  title: string;
  category: ExperienceCategory;
  description: string;
  pricePerPerson: number;
  durationHours: number;
  maxGroupSize: number;
  heroImage: string;
  includedItems: string[];
  meetingPoint: string;
  hostName: string;
  hostRole: string;
  rating: number;
  reviewCount: number;
  verified: boolean;
  rainFriendly: boolean;
  rainAlternativeId?: string;
  explanation?: RecommendationExplanation;
}

export interface ExperienceSlot {
  id: string;
  experienceId: string;
  date: ISODateString;
  startTime: string; // "09:00"
  endTime: string;   // "11:30"
  totalCapacity: number;
  availableCapacity: number;
}

export type StayType = 'BOUTIQUE_RESORT' | 'LUXURY_HOUSEBOAT' | 'HERITAGE_HOMESTAY' | 'ECO_LODGE' | 'CLIFF_VILLA';

export interface Accommodation {
  id: string;
  orgId: UUID;
  destinationId: string;
  name: string;
  type: StayType;
  tagline: string;
  description: string;
  heroImage: string;
  starRating: number;
  basePricePerNight: number;
  ecoGreenScore: number; // 0 - 100
  amenities: string[];
  aiSuitabilityScore: number;
  explanation?: RecommendationExplanation;
  roomTypes: {
    id: string;
    name: string;
    pricePerNight: number;
    capacity: number;
    features: string[];
  }[];
}

// ----------------------------------------------------------------------------
// 6. Transactional Inventory & Locks
// ----------------------------------------------------------------------------
export type HoldStatus = 'ACTIVE' | 'CONSUMED' | 'EXPIRED' | 'RELEASED';

export interface InventoryHold {
  id: UUID;
  bookingId: UUID;
  inventoryType: 'ROOM' | 'EXPERIENCE';
  inventoryId: string;
  quantity: number;
  expiresAt: ISODateTimeString; // 15 mins window
  status: HoldStatus;
}

// ----------------------------------------------------------------------------
// 7. AI Travel Architect & Plan Versioning
// ----------------------------------------------------------------------------
export type TravelStyle = 'BUDGET' | 'COMFORT' | 'PREMIUM' | 'LUXURY';
export type TravelPace = 'RELAXED' | 'BALANCED' | 'PACKED';
export type TransportMode = 'SEDAN' | 'SUV' | 'ELECTRIC_VEHICLE' | 'TEMPO_TRAVELLER' | 'SELF_DRIVE';

export interface TripProfile {
  id: UUID;
  startDate: ISODateString;
  endDate: ISODateString;
  durationDays: number;
  adults: number;
  children: number;
  infants: number;
  startingLocation: string;
  endingLocation?: string;
  budgetLimit: number;
  travelStyle: TravelStyle;
  pace: TravelPace;
  transportPreference: TransportMode;
  interests: string[];
  avoidances?: string[];
  rawPrompt?: string;
}

export interface TimelineEvent {
  id: string;
  time: string; // "09:00"
  type: 'ACTIVITY' | 'EXPERIENCE' | 'MEAL' | 'STAY_CHECKIN' | 'LEISURE' | 'TRANSIT';
  title: string;
  subtitle?: string;
  durationMins: number;
  cost: number;
  locationName: string;
  coordinates?: GeoCoordinates;
  isRainAlternative?: boolean;
  experienceId?: string;
}

export interface TravelSegment {
  fromDestination: string;
  toDestination: string;
  distanceKm: number;
  durationMinutes: number;
  mode: TransportMode;
  scenicHighlights: string[];
}

export interface ItineraryDay {
  dayNumber: number;
  date: ISODateString;
  destinationId: string;
  destinationName: string;
  destinationHero: string;
  themeTitle: string;
  accommodation?: Accommodation;
  timeline: TimelineEvent[];
  transfers?: TravelSegment[];
  dayEstimatedCost: number;
}

export interface PriceBreakdown {
  staysTotal: number;
  transportTotal: number;
  experiencesTotal: number;
  mealsEstimate: number;
  taxesAndFees: number;
  discount: number;
  total: number;
}

export interface AIPlanVersion {
  id: UUID;
  planId: UUID;
  versionNumber: number;
  changeReason: string;
  itineraryDays: ItineraryDay[];
  pricing: PriceBreakdown;
  totalDistanceKm: number;
  totalTravelHours: number;
  greenTripScore: number; // 0-100
  createdAt: ISODateTimeString;
}

export interface AIPlan {
  id: UUID;
  tripProfileId: UUID;
  currentVersionId: UUID;
  currentVersion: AIPlanVersion;
  allVersions: AIPlanVersion[];
  status: 'DRAFT' | 'SAVED' | 'FINALIZED' | 'BOOKED';
}

// ----------------------------------------------------------------------------
// 8. 12-State Booking Machine & Payments
// ----------------------------------------------------------------------------
export type BookingStatus =
  | 'DRAFT'
  | 'PENDING_PAYMENT'
  | 'PAYMENT_PROCESSING'
  | 'PAYMENT_FAILED'
  | 'CONFIRMED'
  | 'CANCEL_REQUESTED'
  | 'CANCELLED'
  | 'REFUND_PENDING'
  | 'REFUNDED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'EXPIRED';

export interface BookingItem {
  id: string;
  type: 'ROOM' | 'EXPERIENCE' | 'TRANSPORT' | 'PACKAGE';
  title: string;
  date: ISODateString;
  units: number;
  unitPrice: number;
  subtotal: number;
  providerOrgId: UUID;
}

export interface Booking {
  id: UUID;
  bookingReference: string; // e.g. "KL24062012345"
  userId: UUID;
  planVersionId?: UUID;
  tripTitle: string;
  startDate: ISODateString;
  endDate: ISODateString;
  travelersCount: number;
  primaryGuestName: string;
  primaryGuestPhone: string;
  primaryGuestEmail: string;
  items: BookingItem[];
  pricing: PriceBreakdown;
  status: BookingStatus;
  holdExpiresAt?: ISODateTimeString;
  idempotencyKey: string;
  qrCodeDataUrl?: string;
  greenTripScore: number;
  createdAt: ISODateTimeString;
  confirmedAt?: ISODateTimeString;
}

export type PaymentMethodType = 'UPI' | 'CREDIT_CARD' | 'DEBIT_CARD' | 'NET_BANKING' | 'WALLET' | 'PAY_LATER';

export interface PaymentTransaction {
  id: UUID;
  bookingId: UUID;
  amount: number;
  currency: 'INR';
  method: PaymentMethodType;
  status: 'INITIATED' | 'SUCCESS' | 'FAILED' | 'REFUNDED';
  gatewayTransactionId: string;
  createdAt: ISODateTimeString;
}

// ----------------------------------------------------------------------------
// 9. Live Companion & Support
// ----------------------------------------------------------------------------
export interface CompanionMessage {
  id: string;
  sender: 'USER' | 'AI_COMPANION' | 'SYSTEM';
  text: string;
  timestamp: ISODateTimeString;
  suggestedQuickReplies?: string[];
  actionCard?: {
    type: 'RAIN_ALTERNATIVE' | 'RESTAURANT_SUGGESTION' | 'SCHEDULE_CHANGE' | 'ROUTE_ALERT';
    title: string;
    description: string;
    ctaLabel: string;
    payload?: Record<string, any>;
  };
}

export interface EmergencyContact {
  name: string;
  phone: string;
  category: 'POLICE' | 'MEDICAL' | 'TOURIST_HELPLINE' | 'WOMEN_SAFETY' | 'MONSOON_CONTROL';
  availableHours: string;
}

// ----------------------------------------------------------------------------
// 10. Provider Dashboard & Admin Analytics
// ----------------------------------------------------------------------------
export interface ProviderDashboardMetrics {
  todayBookingsCount: number;
  todayRevenue: number;
  monthRevenue: number;
  activeGuests: number;
  occupancyRatePercent: number;
  averageRating: number;
  recentBookings: {
    id: string;
    guestName: string;
    productName: string;
    dates: string;
    amount: number;
    status: BookingStatus;
  }[];
}

export interface AdminKPIs {
  totalUsers: number;
  totalProviders: number;
  totalBookings: number;
  grossMerchandiseValue: number;
  activeTripsCount: number;
  aiTripsCreated: number;
  aiToBookingConversionRate: number; // e.g. 8.4%
  pendingProviderVerifications: number;
}
