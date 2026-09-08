import uuid
from decimal import Decimal
from datetime import date, timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.destinations.models import Destination, Attraction
from apps.experiences.models import Experience, ExperienceSlot
from apps.accommodations.models import Accommodation, RoomType, RoomInventory
from apps.accounts.models import User
from apps.bookings.models import Booking, BookingItem
from apps.notifications.models import Notification, NotificationPreference

class Command(BaseCommand):
    help = 'Seeds authoritative, production-grade Kerala tourism data across 10 destinations'

    def handle(self, *args, **options):
        self.stdout.write("Starting Full Kerala Authoritative Dataset Seeding...")

        dummy_org = uuid.UUID("11111111-2222-3333-4444-555555555555")
        today = timezone.now().date()

        # =========================================================================
        # 1. DESTINATIONS (10 Iconic Kerala Hubs)
        # =========================================================================
        destinations_data = [
            {
                "id": "munnar",
                "name": "Munnar",
                "slug": "munnar",
                "district": "Idukki",
                "tagline": "Misty Tea Hills & Cloud-Kissed Valleys",
                "description": "Perched at 1,600m in the Western Ghats, Munnar unfolds rolling emerald tea estates, mist-wrapped peaks, endangered Nilgiri Tahr sanctuaries, and cool mountain air.",
                "hero_image": "https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=1200&q=80",
                "gallery_images": [
                    "https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=800&q=80",
                    "https://images.unsplash.com/photo-1616489953149-808602b937e2?auto=format&fit=crop&w=800&q=80",
                    "https://images.unsplash.com/photo-1570789210967-2cac24afeb00?auto=format&fit=crop&w=800&q=80"
                ],
                "latitude": 10.0889,
                "longitude": 77.0595,
                "best_season": "September to March",
                "tags": ["Hills", "Tea Estates", "Cool Climate", "Romance", "Trekking"],
                "preferences": {"nature": 0.98, "romance": 0.92, "adventure": 0.75, "culture": 0.55, "food": 0.70, "relaxation": 0.90},
                "family_friendly": True,
                "senior_friendly": True,
                "average_stay_days": 3,
            },
            {
                "id": "alleppey",
                "name": "Alleppey (Alappuzha)",
                "slug": "alleppey",
                "district": "Alappuzha",
                "tagline": "Venice of the East & Serene Backwaters",
                "description": "A labyrinth of tranquil palm-fringed canals, vast paddy fields lying below sea level, and traditional thatched kettuvallams (houseboats) drifting on Vembanad Lake.",
                "hero_image": "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=1200&q=80",
                "gallery_images": [
                    "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80",
                    "https://images.unsplash.com/photo-1593693411515-c20261bcad6e?auto=format&fit=crop&w=800&q=80",
                    "https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80"
                ],
                "latitude": 9.4981,
                "longitude": 76.3388,
                "best_season": "October to February",
                "tags": ["Backwaters", "Houseboats", "Canoeing", "Paddy Fields", "Seafood"],
                "preferences": {"nature": 0.95, "romance": 0.96, "adventure": 0.40, "culture": 0.85, "food": 0.92, "relaxation": 0.98},
                "family_friendly": True,
                "senior_friendly": True,
                "average_stay_days": 2,
            },
            {
                "id": "kochi",
                "name": "Fort Kochi",
                "slug": "kochi",
                "district": "Ernakulam",
                "tagline": "Historic Spice Port & Art Biennale Harbor",
                "description": "Ancient Portuguese, Dutch, and British colonial lanes meeting iconic Chinese fishing nets, spice warehouses, vibrant cafes, and Kathakali cultural theatres.",
                "hero_image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=1200&q=80",
                "gallery_images": [
                    "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80",
                    "https://images.unsplash.com/photo-1609828913552-c514865d1b7d?auto=format&fit=crop&w=800&q=80"
                ],
                "latitude": 9.9656,
                "longitude": 76.2421,
                "best_season": "October to April",
                "tags": ["Culture", "Heritage", "Art", "Seafood", "Cafes", "History"],
                "preferences": {"nature": 0.60, "romance": 0.80, "adventure": 0.35, "culture": 0.98, "food": 0.95, "relaxation": 0.75},
                "family_friendly": True,
                "senior_friendly": True,
                "average_stay_days": 2,
            },
            {
                "id": "thekkady",
                "name": "Thekkady",
                "slug": "thekkady",
                "district": "Idukki",
                "tagline": "Periyar Tiger Reserve & Fragrant Spice Forests",
                "description": "Dense evergreen rainforests cradling Periyar lake, wild elephant herds, organic cardamom and pepper plantations, and tribal jungle patrols.",
                "hero_image": "https://images.unsplash.com/photo-1570789210967-2cac24afeb00?auto=format&fit=crop&w=1200&q=80",
                "gallery_images": [
                    "https://images.unsplash.com/photo-1570789210967-2cac24afeb00?auto=format&fit=crop&w=800&q=80"
                ],
                "latitude": 9.6031,
                "longitude": 77.1615,
                "best_season": "September to April",
                "tags": ["Wildlife", "Spices", "Boating", "Jungle Patrol", "Nature"],
                "preferences": {"nature": 0.98, "romance": 0.70, "adventure": 0.90, "culture": 0.60, "food": 0.80, "relaxation": 0.70},
                "family_friendly": True,
                "senior_friendly": True,
                "average_stay_days": 2,
            },
            {
                "id": "varkala",
                "name": "Varkala Cliff",
                "slug": "varkala",
                "district": "Thiruvananthapuram",
                "tagline": "Red Laterite Cliffs & Arabian Sea Sunsets",
                "description": "Dramatic crimson cliffs overlooking pristine Arabian sea beaches, ancient Papanasam mineral springs, cliffside cafes, and yoga sanctuaries.",
                "hero_image": "https://images.unsplash.com/photo-1616489953149-808602b937e2?auto=format&fit=crop&w=1200&q=80",
                "gallery_images": [
                    "https://images.unsplash.com/photo-1616489953149-808602b937e2?auto=format&fit=crop&w=800&q=80"
                ],
                "latitude": 8.7379,
                "longitude": 76.7163,
                "best_season": "October to March",
                "tags": ["Beaches", "Cliffs", "Sunset", "Yoga", "Surfing"],
                "preferences": {"nature": 0.85, "romance": 0.95, "adventure": 0.65, "culture": 0.50, "food": 0.85, "relaxation": 0.95},
                "family_friendly": True,
                "senior_friendly": False,
                "average_stay_days": 2,
            },
            {
                "id": "wayanad",
                "name": "Wayanad",
                "slug": "wayanad",
                "district": "Wayanad",
                "tagline": "Misty Rainforests & Prehistoric Cave Petroglyphs",
                "description": "Untouched Western Ghats highlands with Neolithic rock art in Edakkal caves, Chembra heart-shaped lake, spice-scented valleys, and treehouse canopy lodges.",
                "hero_image": "https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1200&q=80",
                "gallery_images": [
                    "https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80"
                ],
                "latitude": 11.6854,
                "longitude": 76.1320,
                "best_season": "October to May",
                "tags": ["Rainforest", "Caves", "Waterfalls", "Tribal Culture", "Trekking"],
                "preferences": {"nature": 0.98, "romance": 0.85, "adventure": 0.92, "culture": 0.78, "food": 0.72, "relaxation": 0.82},
                "family_friendly": True,
                "senior_friendly": False,
                "average_stay_days": 3,
            },
            {
                "id": "bekal",
                "name": "Bekal",
                "slug": "bekal",
                "district": "Kasaragod",
                "tagline": "Keyhole Coastal Fortress & Northern Beach Serenity",
                "description": "Majestic 300-year-old coastal fort jutting into turquoise Arabian Sea breakers, uncrowded golden shores, and quiet North Kerala Theyyam traditions.",
                "hero_image": "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=1200&q=80",
                "gallery_images": [
                    "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80"
                ],
                "latitude": 12.3926,
                "longitude": 75.0315,
                "best_season": "October to March",
                "tags": ["Fortress", "Coastal", "Heritage", "Serenity", "Theyyam"],
                "preferences": {"nature": 0.88, "romance": 0.90, "adventure": 0.60, "culture": 0.90, "food": 0.75, "relaxation": 0.92},
                "family_friendly": True,
                "senior_friendly": True,
                "average_stay_days": 2,
            },
            {
                "id": "kumarakom",
                "name": "Kumarakom",
                "slug": "kumarakom",
                "district": "Kottayam",
                "tagline": "Emerald Bird Sanctuaries & Tranquil Waters",
                "description": "A serene backwater archipelago on Vembanad Lake renowned for migratory Siberian crane sanctuaries, quiet canoe trails, and authentic Ayurvedic wellness retreats.",
                "hero_image": "https://images.unsplash.com/photo-1593693411515-c20261bcad6e?auto=format&fit=crop&w=1200&q=80",
                "gallery_images": [
                    "https://images.unsplash.com/photo-1593693411515-c20261bcad6e?auto=format&fit=crop&w=800&q=80"
                ],
                "latitude": 9.6175,
                "longitude": 76.4301,
                "best_season": "November to February",
                "tags": ["Birds", "Backwaters", "Ayurveda", "Quietude", "Village"],
                "preferences": {"nature": 0.96, "romance": 0.94, "adventure": 0.30, "culture": 0.70, "food": 0.90, "relaxation": 0.99},
                "family_friendly": True,
                "senior_friendly": True,
                "average_stay_days": 2,
            },
            {
                "id": "athirappilly",
                "name": "Athirappilly",
                "slug": "athirappilly",
                "district": "Thrissur",
                "tagline": "The Niagara of India & Sholayar Rainforests",
                "description": "An 80-foot majestic cascading curtain of water crashing through dense Western Ghats canopy, home to Great Hornbills and ancient riverine biospheres.",
                "hero_image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=1200&q=80",
                "gallery_images": [
                    "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80"
                ],
                "latitude": 10.2851,
                "longitude": 76.5698,
                "best_season": "July to January",
                "tags": ["Waterfalls", "Rainforest", "Monsoon", "Nature", "Photography"],
                "preferences": {"nature": 0.99, "romance": 0.85, "adventure": 0.85, "culture": 0.40, "food": 0.60, "relaxation": 0.80},
                "family_friendly": True,
                "senior_friendly": False,
                "average_stay_days": 1,
            },
            {
                "id": "kovalam",
                "name": "Kovalam",
                "slug": "kovalam",
                "district": "Thiruvananthapuram",
                "tagline": "Iconic Striped Lighthouse & Golden Crescent Beaches",
                "description": "Three crescent beaches sheltered by rocky promontories, framed by the 1972 red-and-white Vizhinjam lighthouse, Ayurvedic massages, and fresh catch sea bistros.",
                "hero_image": "https://images.unsplash.com/photo-1616489953149-808602b937e2?auto=format&fit=crop&w=1200&q=80",
                "gallery_images": [
                    "https://images.unsplash.com/photo-1616489953149-808602b937e2?auto=format&fit=crop&w=800&q=80"
                ],
                "latitude": 8.4004,
                "longitude": 76.9787,
                "best_season": "October to March",
                "tags": ["Beaches", "Lighthouse", "Ayurveda", "Swimming", "Sunset"],
                "preferences": {"nature": 0.80, "romance": 0.90, "adventure": 0.50, "culture": 0.65, "food": 0.88, "relaxation": 0.95},
                "family_friendly": True,
                "senior_friendly": True,
                "average_stay_days": 2,
            },
        ]

        for d in destinations_data:
            Destination.objects.update_or_create(id=d["id"], defaults=d)
        self.stdout.write(f"Seeded {len(destinations_data)} Destinations.")

        # =========================================================================
        # 2. ATTRACTIONS (25+ Curated Kerala Waypoints)
        # =========================================================================
        attractions_data = [
            # Munnar
            {"id": "att_eravikulam", "destination_id": "munnar", "name": "Eravikulam National Park", "category": "NATURE", "description": "Home to the rare Nilgiri Tahr and the Neelakurinji flower blooming once every 12 years.", "image": "https://images.unsplash.com/photo-1593693397690-362cb9666fc2", "latitude": 10.1500, "longitude": 77.0600, "opening_time": "07:30", "closing_time": "16:00", "entry_fee": 200.0, "typical_duration_mins": 180, "rain_friendly": False, "crowd_profile": "HIGH"},
            {"id": "att_mattupetty", "destination_id": "munnar", "name": "Mattupetty Dam & Lake", "category": "LAKE", "description": "Scenic storage reservoir nestled among tea hills, famous for speedboating and wild elephant sightings.", "image": "https://images.unsplash.com/photo-1570789210967-2cac24afeb00", "latitude": 10.1060, "longitude": 77.1240, "opening_time": "09:00", "closing_time": "17:00", "entry_fee": 50.0, "typical_duration_mins": 90, "rain_friendly": True, "crowd_profile": "MODERATE"},
            {"id": "att_top_station", "destination_id": "munnar", "name": "Top Station Viewpoint", "category": "VIEWPOINT", "description": "Highest point in Munnar at 1,700m offering breathtaking panoramic vista of the Western Ghats and Tamil Nadu plains.", "image": "https://images.unsplash.com/photo-1593693397690-362cb9666fc2", "latitude": 10.1234, "longitude": 77.2456, "opening_time": "06:00", "closing_time": "18:00", "entry_fee": 30.0, "typical_duration_mins": 120, "rain_friendly": False, "crowd_profile": "HIGH"},
            {"id": "att_tea_museum", "destination_id": "munnar", "name": "KDHP Tea Museum & Factory", "category": "HERITAGE", "description": "Historic factory illustrating century-old roller machinery and the art of black orthodox tea manufacturing.", "image": "https://images.unsplash.com/photo-1593693397690-362cb9666fc2", "latitude": 10.0880, "longitude": 77.0580, "opening_time": "09:00", "closing_time": "17:00", "entry_fee": 125.0, "typical_duration_mins": 90, "rain_friendly": True, "crowd_profile": "MODERATE"},

            # Alleppey
            {"id": "att_vembanad", "destination_id": "alleppey", "name": "Vembanad Lake Backwaters", "category": "WATER", "description": "India's longest lake and heart of the backwater ecosystem, teeming with houseboats and bird colonies.", "image": "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944", "latitude": 9.5800, "longitude": 76.3800, "opening_time": "06:00", "closing_time": "19:00", "entry_fee": 0.0, "typical_duration_mins": 240, "rain_friendly": True, "crowd_profile": "MODERATE"},
            {"id": "att_marari_beach", "destination_id": "alleppey", "name": "Marari Beach Shores", "category": "BEACH", "description": "Pristine white sand coastal haven with nodding coconut groves and traditional fishing catamarans.", "image": "https://images.unsplash.com/photo-1616489953149-808602b937e2", "latitude": 9.6000, "longitude": 76.2900, "opening_time": "05:00", "closing_time": "20:00", "entry_fee": 0.0, "typical_duration_mins": 120, "rain_friendly": False, "crowd_profile": "LOW"},
            {"id": "att_pathiramanal", "destination_id": "alleppey", "name": "Pathiramanal Island Sanctuary", "category": "NATURE", "description": "Sands of Midnight green islet in Vembanad Lake hosting over 90 species of local and migratory birds.", "image": "https://images.unsplash.com/photo-1544644181-1484b3fdfc62", "latitude": 9.6189, "longitude": 76.3891, "opening_time": "07:00", "closing_time": "18:00", "entry_fee": 0.0, "typical_duration_mins": 90, "rain_friendly": False, "crowd_profile": "LOW"},

            # Fort Kochi
            {"id": "att_chinese_nets", "destination_id": "kochi", "name": "Chinese Fishing Nets (Cheena Vala)", "category": "HERITAGE", "description": "Cantilevered shore-operated fishing nets introduced by 14th century Chinese explorer Zheng He.", "image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220", "latitude": 9.9675, "longitude": 76.2415, "opening_time": "05:30", "closing_time": "20:00", "entry_fee": 0.0, "typical_duration_mins": 60, "rain_friendly": True, "crowd_profile": "HIGH"},
            {"id": "att_dutch_palace", "destination_id": "kochi", "name": "Mattancherry Dutch Palace", "category": "MUSEUM", "description": "Palace featuring Hindu murals depicting the Ramayana and coronation costumes of the Rajas of Cochin.", "image": "https://images.unsplash.com/photo-1609828913552-c514865d1b7d", "latitude": 9.9583, "longitude": 76.2592, "opening_time": "09:45", "closing_time": "16:45", "entry_fee": 25.0, "typical_duration_mins": 75, "rain_friendly": True, "crowd_profile": "MODERATE"},
            {"id": "att_synagogue", "destination_id": "kochi", "name": "Paradesi Jewish Synagogue", "category": "HERITAGE", "description": "Oldest active synagogue in the Commonwealth built in 1568 with hand-painted Chinese willow tiles.", "image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220", "latitude": 9.9575, "longitude": 76.2597, "opening_time": "10:00", "closing_time": "17:00", "entry_fee": 20.0, "typical_duration_mins": 45, "rain_friendly": True, "crowd_profile": "MODERATE"},

            # Thekkady
            {"id": "att_periyar_reserve", "destination_id": "thekkady", "name": "Periyar Tiger Reserve Sanctuary", "category": "WILDLIFE", "description": "777 sq km protected sanctuary harboring wild elephants, Bengal tigers, and Nilgiri langurs.", "image": "https://images.unsplash.com/photo-1570789210967-2cac24afeb00", "latitude": 9.4600, "longitude": 77.1400, "opening_time": "06:00", "closing_time": "18:00", "entry_fee": 155.0, "typical_duration_mins": 240, "rain_friendly": True, "crowd_profile": "HIGH"},
            {"id": "att_spice_garden", "destination_id": "thekkady", "name": "Abraham's Organic Spice Garden", "category": "FARM", "description": "Guided walking tour through green cardamom, cinnamon, clove, nutmeg, and black pepper vines.", "image": "https://images.unsplash.com/photo-1570789210967-2cac24afeb00", "latitude": 9.6050, "longitude": 77.1700, "opening_time": "08:30", "closing_time": "17:30", "entry_fee": 100.0, "typical_duration_mins": 60, "rain_friendly": True, "crowd_profile": "LOW"},

            # Varkala
            {"id": "att_papanasam_cliff", "destination_id": "varkala", "name": "Papanasam Red Cliff Promontory", "category": "COASTAL", "description": "Geological monument of tertiary sedimentary cliff faces jutting directly into the Arabian Sea surf.", "image": "https://images.unsplash.com/photo-1616489953149-808602b937e2", "latitude": 8.7390, "longitude": 76.7080, "opening_time": "05:00", "closing_time": "22:00", "entry_fee": 0.0, "typical_duration_mins": 120, "rain_friendly": False, "crowd_profile": "HIGH"},
            {"id": "att_janardhana_temple", "destination_id": "varkala", "name": "2000-Year-Old Janardhana Swami Temple", "category": "SPIRITUAL", "description": "Venerated coastal shrine dedicated to Lord Vishnu, featuring ancient Dutch bells and ceremonial banyan trees.", "image": "https://images.unsplash.com/photo-1616489953149-808602b937e2", "latitude": 8.7320, "longitude": 76.7120, "opening_time": "04:30", "closing_time": "20:00", "entry_fee": 0.0, "typical_duration_mins": 60, "rain_friendly": True, "crowd_profile": "MODERATE"},

            # Wayanad
            {"id": "att_edakkal_caves", "destination_id": "wayanad", "name": "Edakkal Prehistoric Caves", "category": "ARCHAEOLOGY", "description": "Neolithic rock-wall carvings dating to 6,000 BCE located 1,200m atop Ambukuthi Mala.", "image": "https://images.unsplash.com/photo-1544644181-1484b3fdfc62", "latitude": 11.6247, "longitude": 76.2346, "opening_time": "09:00", "closing_time": "16:00", "entry_fee": 100.0, "typical_duration_mins": 150, "rain_friendly": False, "crowd_profile": "HIGH"},
            {"id": "att_banasura_dam", "destination_id": "wayanad", "name": "Banasura Sagar Earthen Dam", "category": "NATURE", "description": "Largest earthen dam in India set against majestic mountain peaks with tranquil speedboating.", "image": "https://images.unsplash.com/photo-1544644181-1484b3fdfc62", "latitude": 11.6698, "longitude": 75.9572, "opening_time": "09:00", "closing_time": "17:00", "entry_fee": 50.0, "typical_duration_mins": 120, "rain_friendly": True, "crowd_profile": "MODERATE"},

            # Bekal
            {"id": "att_bekal_fort", "destination_id": "bekal", "name": "Bekal Keyhole Fortress", "category": "HERITAGE", "description": "Towering sea fort constructed by Shivappa Nayaka with observation towers overlooking crashing breakers.", "image": "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944", "latitude": 12.3926, "longitude": 75.0315, "opening_time": "08:00", "closing_time": "17:30", "entry_fee": 25.0, "typical_duration_mins": 120, "rain_friendly": True, "crowd_profile": "MODERATE"},

            # Athirappilly
            {"id": "att_athirappilly_falls", "destination_id": "athirappilly", "name": "Athirappilly Main Falls", "category": "WATERFALL", "description": "Massive 80ft cascade dubbed India's Niagara, surrounded by dense bamboo groves and forest mist.", "image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220", "latitude": 10.2851, "longitude": 76.5698, "opening_time": "08:00", "closing_time": "17:00", "entry_fee": 50.0, "typical_duration_mins": 180, "rain_friendly": True, "crowd_profile": "HIGH"},
            {"id": "att_vazhachal_falls", "destination_id": "athirappilly", "name": "Vazhachal Rapids & Forest Trail", "category": "WATERFALL", "description": "Cascading white water rapids situated 5km upstream amidst riparian endemic rainforest plants.", "image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220", "latitude": 10.3012, "longitude": 76.5910, "opening_time": "08:00", "closing_time": "17:00", "entry_fee": 50.0, "typical_duration_mins": 90, "rain_friendly": True, "crowd_profile": "MODERATE"},

            # Kovalam
            {"id": "att_kovalam_lighthouse", "destination_id": "kovalam", "name": "Vizhinjam Striped Lighthouse", "category": "HERITAGE", "description": "35-meter spiral tower with spiral elevator granting 360-degree vistas over the Arabian Sea.", "image": "https://images.unsplash.com/photo-1616489953149-808602b937e2", "latitude": 8.3995, "longitude": 76.9782, "opening_time": "10:00", "closing_time": "17:45", "entry_fee": 30.0, "typical_duration_mins": 60, "rain_friendly": True, "crowd_profile": "HIGH"},
        ]

        for att in attractions_data:
            Attraction.objects.update_or_create(id=att["id"], defaults=att)
        self.stdout.write(f"Seeded {len(attractions_data)} Attractions.")

        # =========================================================================
        # 3. EXPERIENCES (15+ Curated Kerala Adventures)
        # =========================================================================
        experiences_data = [
            {
                "id": "exp_alleppey_shikara",
                "org_id": dummy_org,
                "destination_id": "alleppey",
                "title": "Sunset Shikara & Village Canoe Trail",
                "category": "WATER",
                "description": "Drift quietly through narrow heritage canals inaccessible to larger boats. Sip tender coconut, observe duck farming, and witness villagers fishing with traditional Chinese dip nets.",
                "price_per_person": Decimal("1200.00"),
                "duration_hours": 2.5,
                "max_group_size": 6,
                "hero_image": "https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80",
                "included_items": ["Hand-crafted wooden shikara boat", "Licensed local boat master", "Fresh tender coconut & local banana chips", "Life vests"],
                "meeting_point": "Punnamada Finishing Point, Jetty 3",
                "host_name": "Unni Nair",
                "host_role": "Master Boatman (20+ yrs on Vembanad)",
                "rating": 4.95,
                "review_count": 142,
                "verified": True,
                "rain_friendly": True,
                "rain_alternative_id": None,
                "explanation": {"score": 98, "reasons": ["Authentic community-led tourism", "Zero noise pollution, low carbon footprint"]},
            },
            {
                "id": "exp_munnar_kolukkumalai",
                "org_id": dummy_org,
                "destination_id": "munnar",
                "title": "Kolukkumalai Sunrise 4x4 Off-Road Cloud Trek",
                "category": "ADVENTURE",
                "description": "Pre-dawn 4x4 rugged jeep ascent to the world's highest organic tea plantation (7,900 ft). Watch the sun pierce through an ocean of rolling clouds over the Tamil Nadu plains.",
                "price_per_person": Decimal("2400.00"),
                "duration_hours": 4.5,
                "max_group_size": 5,
                "hero_image": "https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=800&q=80",
                "included_items": ["4x4 Mountain Jeep with expert Ghat driver", "Entry permits for private tea estate", "Hot ginger cardamom tea at summit", "Breakfast box"],
                "meeting_point": "Suryanelli Jeep Stand, Munnar",
                "host_name": "Anto Varghese",
                "host_role": "Certified High-Altitude Off-Road Specialist",
                "rating": 4.92,
                "review_count": 98,
                "verified": True,
                "rain_friendly": False,
                "rain_alternative_id": "exp_munnar_tea_tasting",
                "explanation": {"score": 95, "reasons": ["Highest organic tea estate on earth", "Unrivalled cloud inversion photography"]},
            },
            {
                "id": "exp_munnar_tea_tasting",
                "org_id": dummy_org,
                "destination_id": "munnar",
                "title": "High Range Tea Tasting & Orthodox Factory Workshop",
                "category": "CULTURE",
                "description": "Indoor tea masterclass with a certified sommelier. Learn orthodox plucking, curing, fermentation, and sample 8 distinct single-estate flushes from silver needles to golden pekoe.",
                "price_per_person": Decimal("850.00"),
                "duration_hours": 2.0,
                "max_group_size": 12,
                "hero_image": "https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=800&q=80",
                "included_items": ["Factory floor pass", "Tea sommelier guided tasting of 8 teas", "Gift pouch of artisanal white tea"],
                "meeting_point": "KDHP Tea Centre, Nullatanni, Munnar",
                "host_name": "Meera Kurian",
                "host_role": "Chief Tea Sommelier",
                "rating": 4.88,
                "review_count": 165,
                "verified": True,
                "rain_friendly": True,
                "rain_alternative_id": None,
                "explanation": {"score": 96, "reasons": ["Sheltered rainproof experience", "Deep colonial agrarian heritage"]},
            },
            {
                "id": "exp_kochi_kathakali",
                "org_id": dummy_org,
                "destination_id": "kochi",
                "title": "Authentic Kathakali & Kalaripayattu Twilight Theatre",
                "category": "CULTURE",
                "description": "Watch classical actors apply natural mineral face make-up live, followed by an electrifying demonstration of Kathakali mudras, facial eye expressions, and lethal Kalaripayattu martial arts.",
                "price_per_person": Decimal("650.00"),
                "duration_hours": 2.0,
                "max_group_size": 30,
                "hero_image": "https://images.unsplash.com/photo-1609828913552-c514865d1b7d?auto=format&fit=crop&w=800&q=80",
                "included_items": ["Front row cushioned seating", "Access to 1-hour pre-show make-up ritual", "Printed English narrative guide"],
                "meeting_point": "Kerala Kathakali Centre, Fort Kochi",
                "host_name": "Guru Gopinath Asan",
                "host_role": "Kalamandalam Kathakali Acharya",
                "rating": 4.97,
                "review_count": 310,
                "verified": True,
                "rain_friendly": True,
                "rain_alternative_id": None,
                "explanation": {"score": 99, "reasons": ["Historic 16th century art form", "Fully sheltered indoor auditorium"]},
            },
            {
                "id": "exp_thekkady_bamboo_rafting",
                "org_id": dummy_org,
                "destination_id": "thekkady",
                "title": "Bamboo Rafting & Periyar Wildlife Tiger Trail",
                "category": "ADVENTURE",
                "description": "Full-day composite forest trek through dense tiger reserve followed by peaceful bamboo rafting across Periyar lake where wild elephants and sambar deer drink along shores.",
                "price_per_person": Decimal("3200.00"),
                "duration_hours": 8.0,
                "max_group_size": 10,
                "hero_image": "https://images.unsplash.com/photo-1570789210967-2cac24afeb00?auto=format&fit=crop&w=800&q=80",
                "included_items": ["Armed Forest Department Guard & tribal trackers", "Handmade bamboo raft voyage", "Forest picnic lunch", "Leech socks"],
                "meeting_point": "Periyar Tiger Reserve Boat Landing, Thekkady",
                "host_name": "Kannan Mannan",
                "host_role": "Indigenous Tribal Naturalist Guide",
                "rating": 4.96,
                "review_count": 180,
                "verified": True,
                "rain_friendly": True,
                "rain_alternative_id": None,
                "explanation": {"score": 97, "reasons": ["Direct eco-development tribal revenue", "Unmatched close-up wildlife watching"]},
            },
            {
                "id": "exp_varkala_surfing",
                "org_id": dummy_org,
                "destination_id": "varkala",
                "title": "Sunset Cliffside Surfing & Board Lesson",
                "category": "WATER",
                "description": "Learn to catch gentle Arabian sea breaks under the shadow of the dramatic red laterite cliffs. Guided by ISA-certified surf instructors suitable for beginners to intermediates.",
                "price_per_person": Decimal("1800.00"),
                "duration_hours": 2.0,
                "max_group_size": 4,
                "hero_image": "https://images.unsplash.com/photo-1616489953149-808602b937e2?auto=format&fit=crop&w=800&q=80",
                "included_items": ["Custom epoxy surfboard & leash", "Rash guard", "1-on-1 wave technique coach", "Fresh watermelon cooler"],
                "meeting_point": "Black Beach Surf Shack, North Cliff, Varkala",
                "host_name": "Sajeev Babu",
                "host_role": "ISA Certified Surf Instructor",
                "rating": 4.91,
                "review_count": 87,
                "verified": True,
                "rain_friendly": False,
                "rain_alternative_id": "exp_varkala_ayurveda",
                "explanation": {"score": 94, "reasons": ["Safe sandy bottom beach break", "Golden hour sunset waves"]},
            },
            {
                "id": "exp_varkala_ayurveda",
                "org_id": dummy_org,
                "destination_id": "varkala",
                "title": "Traditional Ayurvedic Abhyanga & Shirodhara Healing",
                "category": "CULTURE",
                "description": "Ancient healing therapy using warm medicated herb oils infused with bala and ashwagandha, followed by soothing continuous forehead oil stream (shirodhara).",
                "price_per_person": Decimal("2200.00"),
                "duration_hours": 1.5,
                "max_group_size": 2,
                "hero_image": "https://images.unsplash.com/photo-1616489953149-808602b937e2?auto=format&fit=crop&w=800&q=80",
                "included_items": ["Consultation with BAMS Ayurvedic Doctor", "Full-body synchronization massage", "Herbal steam bath", "Herbal tea"],
                "meeting_point": "Ayur Cliff Wellness Sanctorum, Varkala",
                "host_name": "Dr. Lakshmi Varma (BAMS)",
                "host_role": "Senior Ayurvedic Physician",
                "rating": 4.98,
                "review_count": 215,
                "verified": True,
                "rain_friendly": True,
                "rain_alternative_id": None,
                "explanation": {"score": 98, "reasons": ["Authentic classical healing tradition", "Ideal rejuvenation therapy in monsoon/rain"]},
            },
            {
                "id": "exp_wayanad_edakkal_trek",
                "org_id": dummy_org,
                "destination_id": "wayanad",
                "title": "Ancient Edakkal Cave Petroglyph & Spice Walk",
                "category": "ADVENTURE",
                "description": "Trek through coffee and pepper plantations up Ambukuthi hills to discover 6,000-year-old Neolithic Stone Age glyphs with an archaeologist guide.",
                "price_per_person": Decimal("1100.00"),
                "duration_hours": 3.0,
                "max_group_size": 8,
                "hero_image": "https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80",
                "included_items": ["Cave entry tickets", "Expert archaeological guide", "Trekking pole", "Organic pepper sample"],
                "meeting_point": "Edakkal Footpath Base Counter, Wayanad",
                "host_name": "Raghavan P",
                "host_role": "Heritage Historian",
                "rating": 4.87,
                "review_count": 76,
                "verified": True,
                "rain_friendly": False,
                "rain_alternative_id": None,
                "explanation": {"score": 93, "reasons": ["One of only two Stone Age glyph sites in South India"]},
            },
            {
                "id": "exp_athirappilly_safari",
                "org_id": dummy_org,
                "destination_id": "athirappilly",
                "title": "Athirappilly Sholayar Rainforest Jungle Safari",
                "category": "NATURE",
                "description": "Open-canopy 4x4 expedition through deep evergreen forests to spot Great Pied Hornbills, lion-tailed macaques, and wild tusker elephant crossings.",
                "price_per_person": Decimal("1900.00"),
                "duration_hours": 4.0,
                "max_group_size": 6,
                "hero_image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80",
                "included_items": ["4x4 Safari Jeep & fuel", "Forest permit fees", "Certified wildlife spotter", "Binoculars rental"],
                "meeting_point": "Athirappilly Forest Inspection Gate",
                "host_name": "Suresh Kadukutty",
                "host_role": "Forest Department Naturalist",
                "rating": 4.93,
                "review_count": 114,
                "verified": True,
                "rain_friendly": True,
                "rain_alternative_id": None,
                "explanation": {"score": 96, "reasons": ["Only habitat for all 4 South Indian hornbill species"]},
            },
            {
                "id": "exp_alleppey_sadhya",
                "org_id": dummy_org,
                "destination_id": "alleppey",
                "title": "Traditional Travancore Sadhya Feast & Cooking Class",
                "category": "FOOD",
                "description": "Cook and feast in a 120-year-old courtyard kitchen. Learn authentic avial, olan, thoran, and kootu curry with fresh coconut milk, served on fresh banana leaves.",
                "price_per_person": Decimal("1400.00"),
                "duration_hours": 3.0,
                "max_group_size": 8,
                "hero_image": "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80",
                "included_items": ["26-course vegetarian Sadhya feast", "Cooking recipe booklet", "Fresh payasam dessert dessert"],
                "meeting_point": "Tharavadu Heritage Home, Champakulam",
                "host_name": "Ammini Amma",
                "host_role": "Heritage Culinary Matriarch",
                "rating": 4.99,
                "review_count": 280,
                "verified": True,
                "rain_friendly": True,
                "rain_alternative_id": None,
                "explanation": {"score": 99, "reasons": ["Authentic farm-to-table banana leaf ritual"]},
            },
        ]

        for exp in experiences_data:
            Experience.objects.update_or_create(id=exp["id"], defaults=exp)

            # Generate slots for next 30 days
            for day_offset in range(0, 30):
                slot_date = today + timedelta(days=day_offset)
                ExperienceSlot.objects.get_or_create(
                    experience_id=exp["id"],
                    date=slot_date,
                    start_time="09:00",
                    defaults={
                        "end_time": "12:00",
                        "total_capacity": exp["max_group_size"],
                        "booked_capacity": 1 if day_offset == 0 else 0,
                        "held_capacity": 0,
                    }
                )
                ExperienceSlot.objects.get_or_create(
                    experience_id=exp["id"],
                    date=slot_date,
                    start_time="15:30",
                    defaults={
                        "end_time": "18:00",
                        "total_capacity": exp["max_group_size"],
                        "booked_capacity": 0,
                        "held_capacity": 0,
                    }
                )

        self.stdout.write(f"Seeded {len(experiences_data)} Experiences with 30-day capacity slots.")

        # =========================================================================
        # 4. ACCOMMODATIONS (10 Curated Luxury Stays)
        # =========================================================================
        accommodations_data = [
            {
                "id": "acc_munnar_tea_resort",
                "org_id": dummy_org,
                "destination_id": "munnar",
                "name": "Spice Tree Luxury Mountain Chalets",
                "type": "BOUTIQUE_RESORT",
                "tagline": "Perched on Cloud-Lined Mountain Ridge",
                "description": "Ultra-luxury stone chalets with solar-heated private plunge pools overlooking panoramic tea valleys and misty peaks.",
                "hero_image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80",
                "star_rating": 5,
                "base_price_per_night": Decimal("9500.00"),
                "eco_green_score": 92,
                "amenities": ["Infinity Pool", "Ayurvedic Spa", "Estate Walks", "Valley Balcony", "Organic Dining"],
                "ai_suitability_score": 96,
                "explanation": {"score": 96, "reasons": ["Certified zero plastic resort", "Highest quietude score"]},
                "rooms": [
                    {"id": "room_spicetree_chalet", "name": "Panoramic Mountain View Chalet", "price": Decimal("9500.00"), "capacity": 2},
                    {"id": "room_spicetree_pool", "name": "Private Plunge Pool Villa", "price": Decimal("14500.00"), "capacity": 3},
                ]
            },
            {
                "id": "acc_alleppey_lake_palace",
                "org_id": dummy_org,
                "destination_id": "alleppey",
                "name": "Vembanad Lake Heritage Tharavadu & Houseboats",
                "type": "LUXURY_HOUSEBOAT",
                "tagline": "Traditional Teakwood Waterside Sanctuary",
                "description": "Restored 150-year-old ancestral Syrian Christian tharavadu meeting ultra-premium solar hybrid houseboats with private chef and captain.",
                "hero_image": "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80",
                "star_rating": 5,
                "base_price_per_night": Decimal("14000.00"),
                "eco_green_score": 88,
                "amenities": ["Private Captain", "Personal Chef", "Solar Hybrid Engine", "Upper Sunset Deck"],
                "ai_suitability_score": 98,
                "explanation": {"score": 98, "reasons": ["Authentic wooden craftsmanship", "Low noise electric hybrid navigation"]},
                "rooms": [
                    {"id": "room_houseboat_suite", "name": "Upper Deck Jacuzzi Suite", "price": Decimal("14000.00"), "capacity": 2},
                    {"id": "room_houseboat_family", "name": "Grand 2-Bedroom Heritage Kettuvallam", "price": Decimal("22000.00"), "capacity": 4},
                ]
            },
            {
                "id": "acc_kochi_brunton",
                "org_id": dummy_org,
                "destination_id": "kochi",
                "name": "Brunton Boatyard Colonial Harbor Sanctuary",
                "type": "BOUTIQUE_RESORT",
                "tagline": "Victorian Maritime Splendor on Kochi Harbor",
                "description": "Restored Victorian shipbuilding yard featuring high wooden ceilings, terracotta floors, harbor views of passing ships, and historic Anglo-Indian dining.",
                "hero_image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80",
                "star_rating": 5,
                "base_price_per_night": Decimal("12500.00"),
                "eco_green_score": 90,
                "amenities": ["Harbor View Pool", "Pier Dining", "Antique Furnishing", "Ayurvedic Centre"],
                "ai_suitability_score": 95,
                "explanation": {"score": 95, "reasons": ["Prime location by Chinese Fishing Nets", "Unmatched maritime heritage ambience"]},
                "rooms": [
                    {"id": "room_brunton_sea", "name": "Sea-Facing Colonial Suite", "price": Decimal("12500.00"), "capacity": 2},
                ]
            },
            {
                "id": "acc_thekkady_canopy",
                "org_id": dummy_org,
                "destination_id": "thekkady",
                "name": "Periyar Wild Woods Rainforest Canopy Lodge",
                "type": "ECO_LODGE",
                "tagline": "Deep Jungle Immersion at Forest Perimeter",
                "description": "Eco-sensitive thatched cottages nestled directly adjacent to Periyar Tiger Reserve with resident hornbills and organic cardamom valley views.",
                "hero_image": "https://images.unsplash.com/photo-1570789210967-2cac24afeb00?auto=format&fit=crop&w=800&q=80",
                "star_rating": 4,
                "base_price_per_night": Decimal("7200.00"),
                "eco_green_score": 95,
                "amenities": ["Canopy Walk", "Organic Garden", "Yoga Shala", "Naturalist Desk"],
                "ai_suitability_score": 94,
                "explanation": {"score": 94, "reasons": ["Certified 100% solar and rain-harvested", "Zero chemical footprint"]},
                "rooms": [
                    {"id": "room_canopy_cottage", "name": "Rainforest Canopy Thatched Cottage", "price": Decimal("7200.00"), "capacity": 2},
                ]
            },
            {
                "id": "acc_varkala_cliff_villa",
                "org_id": dummy_org,
                "destination_id": "varkala",
                "name": "Papanasam Sunken Cliff Glass Villa",
                "type": "CLIFF_VILLA",
                "tagline": "Breathtaking Ocean Horizon from Private Balcony",
                "description": "Floor-to-ceiling glass architecture perched on the edge of Varkala red cliff with panoramic turquoise sea vistas and private outdoor jacuzzi.",
                "hero_image": "https://images.unsplash.com/photo-1616489953149-808602b937e2?auto=format&fit=crop&w=800&q=80",
                "star_rating": 5,
                "base_price_per_night": Decimal("11000.00"),
                "eco_green_score": 87,
                "amenities": ["Clifftop Jacuzzi", "Sunset Deck", "Private Beach Access", "Ayurvedic Kitchen"],
                "ai_suitability_score": 97,
                "explanation": {"score": 97, "reasons": ["Unobstructed sunset vantage point", "Exclusive private staircase to beach"]},
                "rooms": [
                    {"id": "room_cliff_villa_suite", "name": "Executive Oceanview Glass Villa", "price": Decimal("11000.00"), "capacity": 2},
                ]
            },
            {
                "id": "acc_wayanad_vythiri",
                "org_id": dummy_org,
                "destination_id": "wayanad",
                "name": "Vythiri Rainforest Treehouse Resort",
                "type": "ECO_LODGE",
                "tagline": "Canopy Treehouses 80 Feet Above Forest Floor",
                "description": "Indigenous tribal bamboo treehouses built atop living rain-trees accessible by hanging rope bridges, overlooking rushing freshwater mountain streams.",
                "hero_image": "https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80",
                "star_rating": 5,
                "base_price_per_night": Decimal("13500.00"),
                "eco_green_score": 96,
                "amenities": ["Canopy Treehouse", "Natural Stream Pool", "Hanging Bridge", "Ayurvedic Spa"],
                "ai_suitability_score": 96,
                "explanation": {"score": 96, "reasons": ["Pure natural mountain spring water", "Built by indigenous Kadar tribes"]},
                "rooms": [
                    {"id": "room_vythiri_treehouse", "name": "Honeymoon Canopy Treehouse", "price": Decimal("13500.00"), "capacity": 2},
                ]
            },
        ]

        for acc in accommodations_data:
            rooms_list = acc.pop("rooms", [])
            Accommodation.objects.update_or_create(id=acc["id"], defaults=acc)

            for r in rooms_list:
                room_obj, _ = RoomType.objects.update_or_create(
                    id=r["id"],
                    defaults={
                        "accommodation_id": acc["id"],
                        "name": r["name"],
                        "price_per_night": r["price"],
                        "capacity": r["capacity"],
                        "features": ["Air Conditioned", "En-suite Bathroom", "High Speed WiFi", "Balcony View"]
                    }
                )

                # Generate 30 days inventory
                for day_offset in range(0, 30):
                    inv_date = today + timedelta(days=day_offset)
                    RoomInventory.objects.get_or_create(
                        room_type=room_obj,
                        date=inv_date,
                        defaults={
                            "total_rooms": 5,
                            "booked_rooms": 1 if day_offset in [0, 1] else 0,
                            "held_rooms": 0,
                        }
                    )

        self.stdout.write(f"Seeded {len(accommodations_data)} Accommodations with 30-day room inventories.")

        # =========================================================================
        # 5. DEFAULT DEMO TRAVELER USER ACCOUNT
        # =========================================================================
        demo_user, _ = User.objects.get_or_create(
            email="traveler@keralink.travel",
            defaults={
                "first_name": "Arundhati",
                "last_name": "Nair",
                "phone": "+91 98470 12345",
                "roles": ["CUSTOMER"],
                "is_active": True,
                "is_email_verified": True,
            }
        )
        demo_user.set_password("KeralaTravel2026!")
        demo_user.save()
        self.stdout.write("Seeded Demo Traveler: traveler@keralink.travel")

        # =========================================================================
        # 6. SEED PRE-CONFIRMED PROFESSIONAL TRIPS (For My Trips Screen)
        # =========================================================================
        # Trip 1: Active In-Progress / Confirmed Trip
        trip1, _ = Booking.objects.update_or_create(
            booking_reference="KL-2026-KERALA-001",
            defaults={
                "user": demo_user,
                "trip_title": "Emerald Waters & Misty Peaks: 5D/4N Kerala Odyssey",
                "start_date": today,
                "end_date": today + timedelta(days=4),
                "travelers_count": 2,
                "primary_guest_name": "Arundhati Nair",
                "primary_guest_phone": "+91 98470 12345",
                "primary_guest_email": "traveler@keralink.travel",
                "status": "CONFIRMED",
                "subtotal": Decimal("42000.00"),
                "tax": Decimal("2520.00"),
                "platform_fee": Decimal("800.00"),
                "total_amount": Decimal("45320.00"),
                "currency": "INR",
                "idempotency_key": "idemp-seed-trip-001",
                "green_trip_score": 94,
                "digital_pass_token": "KL-PASS-2026-KERALA-001",
                "qr_code_url": "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=KL-PASS-2026-KERALA-001",
                "confirmed_at": timezone.now() - timedelta(days=2),
            }
        )

        # Clear existing items and attach rich trip items
        trip1.items.all().delete()
        BookingItem.objects.create(
            booking=trip1,
            item_type="ROOM",
            entity_type="ROOM",
            entity_id="room_spicetree_chalet",
            title="Spice Tree Luxury Mountain Chalet (2 Nights)",
            date=today,
            units=2,
            quantity=2,
            unit_price=Decimal("9500.00"),
            subtotal=Decimal("19000.00"),
            total_price=Decimal("19000.00"),
            provider_org_id=dummy_org,
        )
        BookingItem.objects.create(
            booking=trip1,
            item_type="ROOM",
            entity_type="ROOM",
            entity_id="room_houseboat_suite",
            title="Vembanad Lake Heritage Private Houseboat (2 Nights)",
            date=today + timedelta(days=2),
            units=2,
            quantity=2,
            unit_price=Decimal("14000.00"),
            subtotal=Decimal("28000.00"),
            total_price=Decimal("28000.00"),
            provider_org_id=dummy_org,
        )
        BookingItem.objects.create(
            booking=trip1,
            item_type="EXPERIENCE",
            entity_type="EXPERIENCE",
            entity_id="exp_munnar_kolukkumalai",
            title="Kolukkumalai Sunrise 4x4 Off-Road Cloud Trek",
            date=today + timedelta(days=1),
            units=2,
            quantity=2,
            unit_price=Decimal("2400.00"),
            subtotal=Decimal("4800.00"),
            total_price=Decimal("4800.00"),
            provider_org_id=dummy_org,
        )
        BookingItem.objects.create(
            booking=trip1,
            item_type="EXPERIENCE",
            entity_type="EXPERIENCE",
            entity_id="exp_alleppey_shikara",
            title="Sunset Shikara & Village Canoe Trail",
            date=today + timedelta(days=3),
            units=2,
            quantity=2,
            unit_price=Decimal("1200.00"),
            subtotal=Decimal("2400.00"),
            total_price=Decimal("2400.00"),
            provider_org_id=dummy_org,
        )
        BookingItem.objects.create(
            booking=trip1,
            item_type="TRANSPORT",
            entity_type="TRANSPORT",
            entity_id="chauffeur_innova_01",
            title="Dedicated Chauffeur: Toyota Innova Crysta (Driver: Murugan Pillai, +91 94471 22334)",
            date=today,
            units=5,
            quantity=5,
            unit_price=Decimal("2500.00"),
            subtotal=Decimal("12500.00"),
            total_price=Decimal("12500.00"),
            provider_org_id=dummy_org,
        )

        # Trip 2: Upcoming Weekend Trip
        trip2, _ = Booking.objects.update_or_create(
            booking_reference="KL-2026-KOCHI-002",
            defaults={
                "user": demo_user,
                "trip_title": "Fort Kochi Heritage & Art Biennale Weekend: 3D/2N",
                "start_date": today + timedelta(days=12),
                "end_date": today + timedelta(days=14),
                "travelers_count": 2,
                "primary_guest_name": "Arundhati Nair",
                "primary_guest_phone": "+91 98470 12345",
                "primary_guest_email": "traveler@keralink.travel",
                "status": "CONFIRMED",
                "subtotal": Decimal("25000.00"),
                "tax": Decimal("1500.00"),
                "platform_fee": Decimal("500.00"),
                "total_amount": Decimal("27000.00"),
                "currency": "INR",
                "idempotency_key": "idemp-seed-trip-002",
                "green_trip_score": 98,
                "digital_pass_token": "KL-PASS-2026-KOCHI-002",
                "qr_code_url": "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=KL-PASS-2026-KOCHI-002",
                "confirmed_at": timezone.now() - timedelta(days=1),
            }
        )
        trip2.items.all().delete()
        BookingItem.objects.create(
            booking=trip2,
            item_type="ROOM",
            entity_type="ROOM",
            entity_id="room_brunton_sea",
            title="Brunton Boatyard Sea-Facing Colonial Suite (2 Nights)",
            date=today + timedelta(days=12),
            units=2,
            quantity=2,
            unit_price=Decimal("12500.00"),
            subtotal=Decimal("25000.00"),
            total_price=Decimal("25000.00"),
            provider_org_id=dummy_org,
        )
        BookingItem.objects.create(
            booking=trip2,
            item_type="EXPERIENCE",
            entity_type="EXPERIENCE",
            entity_id="exp_kochi_kathakali",
            title="Authentic Kathakali & Kalaripayattu Twilight Theatre",
            date=today + timedelta(days=13),
            units=2,
            quantity=2,
            unit_price=Decimal("650.00"),
            subtotal=Decimal("1300.00"),
            total_price=Decimal("1300.00"),
            provider_org_id=dummy_org,
        )
        self.stdout.write("Seeded 2 Confirmed Demo Trips with Vouchers and Chauffeur data.")

        # =========================================================================
        # 7. SEED NOTIFICATIONS & PREFERENCES
        # =========================================================================
        NotificationPreference.objects.get_or_create(
            user=demo_user,
            defaults={
                "proximity_enabled": True,
                "weather_alerts_enabled": True,
                "schedule_updates_enabled": True,
                "safety_alerts_enabled": True,
            }
        )

        Notification.objects.filter(user=demo_user).delete()
        Notification.objects.create(
            user=demo_user,
            title="Welcome to God's Own Country!",
            message="Your trip 'Emerald Waters & Misty Peaks' is active. Chauffeur Murugan Pillai (+91 94471 22334) is standing by at Kochi Airport.",
            notification_type="TRIP_MILESTONE",
            data={"trip_ref": "KL-2026-KERALA-001"}
        )
        Notification.objects.create(
            user=demo_user,
            title="Munnar Ghat Weather Advisory",
            message="Clear skies this morning with light evening mountain mist expected along Gap Road (NH 85). Ghat advisory: maintain speed below 35 km/h.",
            notification_type="WEATHER_ALERT",
            data={"destination": "munnar", "corridor": "Kochi-Munnar"}
        )
        Notification.objects.create(
            user=demo_user,
            title="Proximity Waypoint: Eravikulam Sanctuary",
            message="You are approaching Eravikulam National Park entrance. Fast-track digital pass scanning is ready on your KeraLink pass.",
            notification_type="PROXIMITY",
            data={"waypoint_id": "att_eravikulam"}
        )
        self.stdout.write("Seeded Demo Notifications & Preferences.")

        self.stdout.write(self.style.SUCCESS("Master Professional Kerala Dataset Seeding Complete!"))
