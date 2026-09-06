import uuid
from django.core.management.base import BaseCommand
from apps.destinations.models import Destination, Attraction
from apps.experiences.models import Experience, ExperienceSlot
from apps.accommodations.models import Accommodation, RoomType, RoomInventory
from datetime import date, timedelta

class Command(BaseCommand):
    help = 'Seeds authoritative Kerala launch corridor tourism data'

    def handle(self, *args, **options):
        self.stdout.write("Seeding Kerala Launch Corridor data...")

        # 1. Destinations
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
                    "https://images.unsplash.com/photo-1616489953149-808602b937e2?auto=format&fit=crop&w=800&q=80"
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
                    "https://images.unsplash.com/photo-1593693411515-c20261bcad6e?auto=format&fit=crop&w=800&q=80"
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
                "tags": ["Beaches", "Cliffs", "Sunset", "Yoga", "Cafes", "Surfing"],
                "preferences": {"nature": 0.85, "romance": 0.95, "adventure": 0.65, "culture": 0.50, "food": 0.85, "relaxation": 0.95},
                "family_friendly": True,
                "senior_friendly": False,
                "average_stay_days": 2,
            },
        ]

        for d in destinations_data:
            Destination.objects.update_or_create(id=d["id"], defaults=d)
        self.stdout.write(f"Seeded {len(destinations_data)} Destinations.")

        # 2. Experiences
        dummy_org = uuid.UUID("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
        experiences_data = [
            {
                "id": "exp_munnar_tea_tasting",
                "org_id": dummy_org,
                "destination_id": "munnar",
                "title": "Lockhart Estate Tea Tasting & Factory Experience",
                "category": "CULTURE",
                "description": "Private walking masterclass across 1857 colonial tea slopes, Orthodox whole-leaf cupping session, and hand-plucking with local tea sommeliers.",
                "price_per_person": 1200.0,
                "duration_hours": 2.5,
                "max_group_size": 8,
                "hero_image": "https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=800&q=80",
                "included_items": ["Estate walking pass", "Private tea tasting flights", "Artisanal tea sample pack"],
                "meeting_point": "Lockhart Tea Museum Main Portico, Munnar",
                "host_name": "Raman Pillai",
                "host_role": "Master Planter & Sommelier",
                "rating": 4.95,
                "review_count": 48,
                "verified": True,
                "rain_friendly": True,
                "rain_alternative_id": None,
                "explanation": {"score": 98, "reasons": ["100% weather sheltered factory", "Award-winning artisanal tasting"]},
            },
            {
                "id": "exp_alleppey_canoe_village",
                "org_id": dummy_org,
                "destination_id": "alleppey",
                "title": "Guided Country Canoe Canal Safari & Village Lunch",
                "category": "WATER",
                "description": "Silently glide in low-draft wooden canoes through narrow village canals unreachable by motorboats, with authentic home-cooked banana leaf Karimeen sadya.",
                "price_per_person": 1600.0,
                "duration_hours": 3.5,
                "max_group_size": 4,
                "hero_image": "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80",
                "included_items": ["Private wooden canoe & boatman", "Fresh coconut toddy / tender coconut", "Authentic village tharavadu lunch"],
                "meeting_point": "Kainakary Village Boat Jetty, Alleppey",
                "host_name": "Captain Biju",
                "host_role": "Heritage Canal Oarsman",
                "rating": 4.98,
                "review_count": 72,
                "verified": True,
                "rain_friendly": False,
                "rain_alternative_id": "exp_alleppey_culinary_shack",
                "explanation": {"score": 96, "reasons": ["Authentic rural immersion", "Zero motor pollution"]},
            },
            {
                "id": "exp_kochi_kathakali_backstage",
                "org_id": dummy_org,
                "destination_id": "kochi",
                "title": "Kathakali Backstage Makeup Ritual & Live Performance",
                "category": "CULTURE",
                "description": "Exclusive backstage access to observe the 2-hour organic chutti mineral makeup transformation, followed by mudra demonstration and classical epic performance.",
                "price_per_person": 850.0,
                "duration_hours": 3.0,
                "max_group_size": 15,
                "hero_image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80",
                "included_items": ["Front row orchestra seating", "Backstage greenroom pass", "Mudras explanation guide"],
                "meeting_point": "Kerala Kathakali Cultural Centre, Fort Kochi",
                "host_name": "Guru Balakrishnan",
                "host_role": "Padma Shri Trained Artiste",
                "rating": 4.92,
                "review_count": 115,
                "verified": True,
                "rain_friendly": True,
                "rain_alternative_id": None,
                "explanation": {"score": 99, "reasons": ["Historic 16th century art form", "Fully sheltered indoor auditorium"]},
            },
        ]

        for e in experiences_data:
            Experience.objects.update_or_create(id=e["id"], defaults=e)
        self.stdout.write(f"Seeded {len(experiences_data)} Experiences.")

        # 3. Accommodations
        accommodations_data = [
            {
                "id": "acc_munnar_tea_resort",
                "org_id": dummy_org,
                "destination_id": "munnar",
                "name": "Spice Tree Luxury Mountain Chalets",
                "type": "BOUTIQUE_RESORT",
                "tagline": "Perched on Cloud-Lined Mountain Ridge",
                "description": "Ultra-luxury stone chalets with solar-heated private plunge pools overlooking panoramic tea valleys.",
                "hero_image": "https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80",
                "star_rating": 5,
                "base_price_per_night": 9500.0,
                "eco_green_score": 92,
                "amenities": ["Infinity Pool", "Ayurvedic Spa", "Estate Walks", "Valley Balcony", "Organic Dining"],
                "ai_suitability_score": 96,
                "explanation": {"score": 96, "reasons": ["Certified zero plastic resort", "Highest quietude score"]},
            },
            {
                "id": "acc_alleppey_lake_palace",
                "org_id": dummy_org,
                "destination_id": "alleppey",
                "name": "Vembanad Lake Heritage Tharavadu & Houseboats",
                "type": "LUXURY_HOUSEBOAT",
                "tagline": "Traditional Teakwood Waterside Sanctuary",
                "description": "Restored 150-year-old ancestral Syrian Christian tharavadu meeting ultra-premium solar hybrid houseboats.",
                "hero_image": "https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80",
                "star_rating": 5,
                "base_price_per_night": 14000.0,
                "eco_green_score": 88,
                "amenities": ["Private Captain", "Personal Chef", "Solar Hybrid Engine", "Upper Sunset Deck"],
                "ai_suitability_score": 98,
                "explanation": {"score": 98, "reasons": ["Authentic wooden craftsmanship", "Low noise electric hybrid navigation"]},
            },
        ]

        for a in accommodations_data:
            Accommodation.objects.update_or_create(id=a["id"], defaults=a)
        self.stdout.write(f"Seeded {len(accommodations_data)} Accommodations.")

        self.stdout.write(self.style.SUCCESS("All Kerala Launch Corridor data successfully seeded!"))
