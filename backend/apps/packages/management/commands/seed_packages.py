import os
from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from apps.packages.models import TourPackage

class Command(BaseCommand):
    help = 'Seeds authentic Kerala Tour Packages from local operators'

    def handle(self, *args, **options):
        if not getattr(settings, 'DEBUG', False) and os.environ.get('ALLOW_PROD_SEED', 'False').lower() not in ('true', '1'):
            raise CommandError("Seeding demo packages is disabled in production (DEBUG=False). Set ALLOW_PROD_SEED=True to override.")

        packages_data = [
            {
                'id': 'pkg-munnar-3d2n-mist',
                'title': '3D/2N Munnar Cloud Mist & Kolukkumalai Sunrise Expedition',
                'slug': 'munnar-cloud-mist-kolukkumalai-3d2n',
                'operator_name': 'Munnar Highland Holidays',
                'operator_phone': '+91 00000 00001',
                'operator_whatsapp': '+910000000001',
                'operator_license': 'DTPC Idukki Accredited (#DTPC-IDK-2024-88)',
                'is_operator_verified': True,
                'category': 'HILL_STATION',
                'tagline': 'Highland tea trails, off-road 4x4 sunrise summit, and waterfalls',
                'description': 'Experience the misty magic of Munnar curated by native high-range guides. Includes 4x4 mountain jeep safari to Kolukkumalai (world highest organic tea estate), guided tea tasting, and boutique tea plantation resort stay.',
                'duration_days': 3,
                'duration_nights': 2,
                'start_city': 'Kochi Airport / Aluva',
                'end_city': 'Kochi Airport / Ernakulam',
                'destinations_covered': ['Kochi', 'Neriamangalam', 'Valara Falls', 'Munnar', 'Kolukkumalai', 'Lockhart Gap'],
                'price_per_person': 8499.00,
                'original_price': 10500.00,
                'hero_image': 'https://images.unsplash.com/photo-1596178065887-1198b6148b2b?auto=format&fit=crop&w=1200&q=80',
                'gallery_images': [
                    'https://images.unsplash.com/photo-1596178065887-1198b6148b2b?auto=format&fit=crop&w=800&q=80',
                    'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=800&q=80',
                    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
                ],
                'highlights': [
                    '4x4 Jeep Safari to Kolukkumalai at 7,130 ft for Golden Sunrise',
                    'Private Tea Factory tour & artisan tea sommelier tasting',
                    'Stop at Cheeyappara & Valara jungle waterfalls on NH85',
                    'Boutique estate cottage accommodation with mountain valley views',
                    'Dedicated chauffeur with ghat-road certified driving credentials'
                ],
                'inclusions': [
                    '2 Nights accommodation in 4-Star Tea Valley Resort',
                    'Daily plantation buffet breakfast & 1 campfire dinner',
                    'Private AC Sedan with fuel, toll, parking & driver allowance',
                    'Kolukkumalai 4x4 mountain Jeep permit and entry fees',
                    'Tea Museum & Lockhart Gap guided trekking permits'
                ],
                'exclusions': [
                    'Airfare / Train tickets to/from Kochi',
                    'Personal expenses & adventure park ride tickets',
                    'Lunches and unmentioned meals'
                ],
                'itinerary': [
                    {
                        'day': 1,
                        'title': 'Kochi to Munnar — Ghat Ascent & Waterfalls',
                        'description': 'Pick up from Kochi Airport/Station. Scenic ascent through Neriamangalam rubber plantations and mountain mist. En-route stop at Valara and Cheeyappara waterfalls. Check in at Tea Estate Resort. Evening stroll through Munnar spice market.',
                        'meals': 'Dinner included',
                        'stay': 'Munnar Tea Valley Resort'
                    },
                    {
                        'day': 2,
                        'title': 'Kolukkumalai Sunrise & Mattupetty Highland Circuit',
                        'description': 'Early 4:30 AM departure in 4x4 rugged jeep to Kolukkumalai peak. Witness the ocean of clouds and breathtaking Tamil Nadu valley sunrise. Visit the 1935 orthodox tea factory. Afternoon visit to Mattupetty Dam, Echo Point, and Kundala Lake.',
                        'meals': 'Breakfast & Campfire Dinner',
                        'stay': 'Munnar Tea Valley Resort'
                    },
                    {
                        'day': 3,
                        'title': 'Eravikulam Nilgiri Tahr & Return Descent to Kochi',
                        'description': 'Morning visit to Rajamalai in Eravikulam National Park to spot the endangered Nilgiri Tahr mountain goats. Photo stop at Lockhart Gap viewpoint. Scenic descent back to Kochi Airport/Station.',
                        'meals': 'Breakfast included',
                        'stay': 'Trip Concludes'
                    }
                ],
                'rating': 4.95,
                'review_count': 64,
                'is_featured': True
            },
            {
                'id': 'pkg-alleppey-2d1n-houseboat',
                'title': '2D/1N Alleppey Royal Backwater Houseboat & Village Canoe Cruise',
                'slug': 'alleppey-royal-houseboat-backwaters-2d1n',
                'operator_name': 'Great Backwaters Tourism Co.',
                'operator_phone': '+91 00000 00002',
                'operator_whatsapp': '+910000000002',
                'operator_license': 'Kerala Tourism Diamond Certified (#KT-ALP-109)',
                'is_operator_verified': True,
                'category': 'BACKWATERS',
                'tagline': 'Private luxury wooden Kettuvallam with master chef Karimeen feast',
                'description': 'Glide through the tranquil canals of Vembanad Lake and Kuttanad on an authentic traditional houseboat. Features private crew (Captain, Chef, Engine Driver), freshly cooked Pearl Spot fish in banana leaf, and sunset country canoe tour.',
                'duration_days': 2,
                'duration_nights': 1,
                'start_city': 'Alappuzha Punnamada Jetty',
                'end_city': 'Alappuzha Punnamada Jetty',
                'destinations_covered': ['Alappuzha', 'Punnamada Lake', 'Kuttanad', 'Champakulam', 'Vembanad'],
                'price_per_person': 7499.00,
                'original_price': 9200.00,
                'hero_image': 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=1200&q=80',
                'gallery_images': [
                    'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80',
                    'https://images.unsplash.com/photo-1596178065887-1198b6148b2b?auto=format&fit=crop&w=800&q=80',
                ],
                'highlights': [
                    'Exclusive Private 1-Bedroom / 2-Bedroom Luxury AC Kettuvallam',
                    'Traditional Kerala Lunch: Karimeen Pollichathu, Chemmeen Roast, Red Rice',
                    'Sunset Country Shikara / Canoe deep into narrow backwater village canals',
                    'Anchor in calm rural backwaters away from town noise',
                    'Watch Chinese fishing nets and coir rope weavers in action'
                ],
                'inclusions': [
                    '1 Night stay on Private AC Houseboat with ensuite bath',
                    'All Meals onboard: Welcome drink, Lunch, Tea/Snacks, Dinner, Breakfast',
                    'Freshly sourced Pearl Spot (Karimeen) fish and local prawns',
                    '1-Hour guided narrow canal country wooden canoe tour',
                    'All navigation taxes, docking fees, and captain crew service'
                ],
                'exclusions': [
                    'Transfers to/from Alappuzha jetty (Available on request)',
                    'Special alcoholic beverages or packaged drinks',
                    'Crew gratuity / tips'
                ],
                'itinerary': [
                    {
                        'day': 1,
                        'title': 'Embarkation at Punnamada Jetty & Backwater Glide',
                        'description': 'Boarding at 12:00 PM with fresh tender coconut welcome drink. Cruise commences past Nehru Trophy race pavilion into Vembanad Lake. Traditional Kerala banana leaf feast prepared by onboard chef. Afternoon narrow canal village visit. Evening anchor with dinner under the stars.',
                        'meals': 'Lunch, Evening Snacks & Dinner',
                        'stay': 'Private Luxury Houseboat'
                    },
                    {
                        'day': 2,
                        'title': 'Morning Mist Cruise & Village Disembarkation',
                        'description': 'Early morning tea on sundeck as the village awakens. Watch cormorants, kingfishers and local fishermen. Authentic Kerala breakfast (Hot Appam with vegetable stew / egg roast). Return to jetty by 9:30 AM.',
                        'meals': 'Breakfast included',
                        'stay': 'Cruise Concludes'
                    }
                ],
                'rating': 4.98,
                'review_count': 92,
                'is_featured': True
            },
            {
                'id': 'pkg-wayanad-4d3n-wilderness',
                'title': '4D/3N Wayanad Wilderness, Bamboo Rafting & Treehouse Retreat',
                'slug': 'wayanad-wilderness-bamboo-rafting-treehouse-4d3n',
                'operator_name': 'Wayanad Eco-Guides Collective',
                'operator_phone': '+91 00000 00003',
                'operator_whatsapp': '+910000000003',
                'operator_license': 'Approved Ecotourism Collective (#WND-ECO-42)',
                'is_operator_verified': True,
                'category': 'ADVENTURE',
                'tagline': 'Stay in authentic rainforest treehouse with tribal honey tasting & safaris',
                'description': 'Escape into the biodiverse Western Ghats of Wayanad. Sleep in canopy treehouses, raft on indigenous bamboo rafts across river streams, explore 6,000-year-old Stone Age petroglyphs at Edakkal Caves, and take an open-jeep wildlife safari.',
                'duration_days': 4,
                'duration_nights': 3,
                'start_city': 'Kozhikode (Calicut) Railway / Airport',
                'end_city': 'Kozhikode (Calicut) Railway / Airport',
                'destinations_covered': ['Calicut', 'Lakkidi Ghat', 'Banasura Sagar', 'Kuruva Island', 'Edakkal Caves', 'Muthanga Safari'],
                'price_per_person': 11999.00,
                'original_price': 14500.00,
                'hero_image': 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1200&q=80',
                'gallery_images': [
                    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=800&q=80',
                    'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=800&q=80',
                ],
                'highlights': [
                    '1 Night in Rainforest Canopy Treehouse 40 feet above ground',
                    '2 Nights in Heritage Coffee Plantation Estate Bungalow',
                    'Indigenous Bamboo Rafting along Kabini River tributaries',
                    'Open 4x4 Jeep Safari in Muthanga Wildlife Sanctuary',
                    'Trek to 6,000 BC Edakkal Caves with certified local archaeologist'
                ],
                'inclusions': [
                    '3 Nights stay (1 Night Treehouse + 2 Nights Coffee Estate)',
                    'Daily traditional Malabar breakfast & 2 plantation dinners',
                    'Dedicated private AC vehicle from Kozhikode pick-up to drop-off',
                    'Muthanga forest department safari vehicle & guide fees',
                    'Bamboo rafting gear & certified life vests'
                ],
                'exclusions': [
                    'Camera permit fees at forest check-posts',
                    'Lunches and snacks during travel stops',
                    'Any personal ayurvedic therapies'
                ],
                'itinerary': [
                    {
                        'day': 1,
                        'title': 'Calicut Ghat Ascent to Rainforest Treehouse',
                        'description': 'Pick up from Calicut. Drive up the 9 hairpin Thamarassery Churam ghat road with breath-taking coastal views. Arrive at treehouse retreat nestled in dense bamboo & coffee grove. Night listening to rainforest sounds.',
                        'meals': 'Dinner included',
                        'stay': 'Rainforest Treehouse, Vythiri'
                    },
                    {
                        'day': 2,
                        'title': 'Banasura Earthen Dam & Kuruva Island Bamboo Rafting',
                        'description': 'Morning walk through spice plantation. Visit Banasura Sagar Dam, India largest earthen dam with speedboating. Proceed to Kuruva Dweep evergreen river islands for gentle bamboo rafting through freshwater streams.',
                        'meals': 'Breakfast & Dinner',
                        'stay': 'Heritage Coffee Plantation Villa'
                    },
                    {
                        'day': 3,
                        'title': 'Edakkal Neolithic Caves & Muthanga Elephant Safari',
                        'description': 'Morning hike up Ambukuthi Mala to Edakkal Caves to view ancient Neolithic rock carvings. Afternoon open-top jeep safari in Muthanga Wildlife Sanctuary to spot wild Asian elephants, deer, and exotic hornbills.',
                        'meals': 'Breakfast & Dinner',
                        'stay': 'Heritage Coffee Plantation Villa'
                    },
                    {
                        'day': 4,
                        'title': 'Soochipara Waterfalls & Calicut Malabar Food Trail',
                        'description': 'Morning visit to three-tiered Soochipara Waterfalls. Scenic descent back to Kozhikode. En-route stop at Paragon for world-famous Calicut Dum Biryani before station/airport drop.',
                        'meals': 'Breakfast included',
                        'stay': 'Tour Concludes'
                    }
                ],
                'rating': 4.92,
                'review_count': 48,
                'is_featured': True
            },
            {
                'id': 'pkg-classical-kerala-5d4n',
                'title': '5D/4N Complete Classical Kerala: Fort Kochi, Munnar & Alleppey',
                'slug': 'classical-kerala-kochi-munnar-alleppey-5d4n',
                'operator_name': 'Voyages Kerala Heritage Expeditions',
                'operator_phone': '+91 00000 00004',
                'operator_whatsapp': '+910000000004',
                'operator_license': 'IATO & Kerala Tourism Accredited (#IATO-KER-551)',
                'is_operator_verified': True,
                'category': 'FAMILY',
                'tagline': 'The ultimate first-timer Kerala grand tour covering culture, mountains & water',
                'description': 'The definitive Kerala golden circuit. Experience colonial Fort Kochi art cafes and Kathakali, roll across high-altitude misty Munnar tea hills, and relax on a private overnight backwater cruise in Alappuzha.',
                'duration_days': 5,
                'duration_nights': 4,
                'start_city': 'Kochi Airport (COK)',
                'end_city': 'Kochi Airport (COK)',
                'destinations_covered': ['Fort Kochi', 'Munnar', 'Lockhart', 'Alleppey', 'Marari Beach'],
                'price_per_person': 16999.00,
                'original_price': 21000.00,
                'hero_image': 'https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=1200&q=80',
                'gallery_images': [
                    'https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=800&q=80',
                    'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80',
                    'https://images.unsplash.com/photo-1596178065887-1198b6148b2b?auto=format&fit=crop&w=800&q=80',
                ],
                'highlights': [
                    'Historic Fort Kochi walking tour: Chinese Nets, St. Francis Church & Jew Town',
                    'VIP evening Kathakali classical dance & Kalaripayattu martial arts tickets',
                    '2 Nights in Munnar highland misty resort with mountain view balcony',
                    '1 Night on exclusive Private Houseboat in Alleppey backwaters',
                    'Dedicated air-conditioned vehicle with English/Hindi/Malayalam speaking driver'
                ],
                'inclusions': [
                    '1 Night Fort Kochi Heritage Hotel + 2 Nights Munnar + 1 Night Houseboat',
                    'Daily Breakfast at all hotels + All Meals on Houseboat',
                    'Private AC Sedan car for all 5 days transfers and sightseeing',
                    'Entry tickets to Kathakali Performance and Tea Museum',
                    'All driver bata, state permits, parking fees, and road taxes'
                ],
                'exclusions': [
                    'Flights / Train fare to Kochi',
                    'Lunches in Kochi and Munnar',
                    'Any boat ride in Mattupetty dam'
                ],
                'itinerary': [
                    {
                        'day': 1,
                        'title': 'Arrival in Kochi & Heritage Fort Kochi Exploration',
                        'description': 'Pickup from Kochi Airport. Check in at Fort Kochi heritage hotel. Walk through colonial streets, see Chinese fishing nets, and attend live Kathakali makeup and performance in the evening.',
                        'meals': 'Welcome drink included',
                        'stay': 'Old Courtyard Heritage Hotel, Fort Kochi'
                    },
                    {
                        'day': 2,
                        'title': 'Ascent to Munnar Tea Valleys & Waterfalls',
                        'description': 'Scenic morning drive towards the Western Ghats. Stop at Valara and Cheeyappara waterfalls. Afternoon tea factory visit and sunset tea garden photography.',
                        'meals': 'Breakfast included',
                        'stay': 'Munnar Tea Mountain Resort'
                    },
                    {
                        'day': 3,
                        'title': 'Eravikulam Mountain Park & Mattupetty Highland Circuit',
                        'description': 'Morning wildlife excursion to Eravikulam National Park. Afternoon visit to Mattupetty Lake, Echo Point, and Rose Garden.',
                        'meals': 'Breakfast included',
                        'stay': 'Munnar Tea Mountain Resort'
                    },
                    {
                        'day': 4,
                        'title': 'Munnar to Alleppey — Boarding Private Houseboat',
                        'description': 'Descend from mountains down to coastal backwaters. Board private luxury Kettuvallam at 12:30 PM. Enjoy authentic banana leaf lunch while gliding past palm-lined canals.',
                        'meals': 'Breakfast, Lunch & Houseboat Dinner',
                        'stay': 'Private AC Houseboat'
                    },
                    {
                        'day': 5,
                        'title': 'Morning Backwater Mist & Departure to Kochi Airport',
                        'description': 'Savor morning village cruise with fresh Appam breakfast. Disembark at 9:30 AM. En-route photo stop at Marari Beach before Kochi Airport departure.',
                        'meals': 'Breakfast included',
                        'stay': 'Tour Concludes'
                    }
                ],
                'rating': 4.97,
                'review_count': 114,
                'is_featured': True
            },
            {
                'id': 'pkg-varkala-3d2n-cliffs',
                'title': '3D/2N Varkala Cliff Waves, Jatayu Earth Center & Munroe Canal Cruise',
                'slug': 'varkala-cliff-jatayu-munroe-island-3d2n',
                'operator_name': 'South Coast Odyssey Guides',
                'operator_phone': '+91 00000 00005',
                'operator_whatsapp': '+910000000005',
                'operator_license': 'DTPC Kollam & Trivandrum Partner (#DTPC-KLM-77)',
                'is_operator_verified': True,
                'category': 'HONEYMOON',
                'tagline': 'Dramatic red cliffs, sunset ocean cafes, giant sculpture & quiet canoe lagoons',
                'description': 'Explore the golden coast of South Kerala. Relax on high red cliffs overlooking the Arabian Sea, ride the Swiss cable car up to Jatayu Earth Center (world largest bird sculpture), and paddle through Munroe Island mangrove channels.',
                'duration_days': 3,
                'duration_nights': 2,
                'start_city': 'Trivandrum (TRV) / Varkala',
                'end_city': 'Trivandrum (TRV) / Varkala',
                'destinations_covered': ['Trivandrum', 'Varkala Cliff', 'Jatayu Center', 'Munroe Island', 'Kappil Beach'],
                'price_per_person': 6999.00,
                'original_price': 8500.00,
                'hero_image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
                'gallery_images': [
                    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
                ],
                'highlights': [
                    '2 Nights at Cliff-top Boutique Resort overlooking Papanasam Beach',
                    'Cable car ride and entry to Jatayu Earth Center mega rock sculpture',
                    'Private morning wooden canoe tour through Munroe Island mangrove canals',
                    'Sunset dining at famous North Cliff Tibetan and seafood cafes',
                    'Scenic drive where Arabian sea and backwater estuary meet at Kappil'
                ],
                'inclusions': [
                    '2 Nights stay in Deluxe Sea-view Room at Varkala North Cliff',
                    'Daily ocean-terrace breakfast',
                    'AC Sedan car for all transfers and excursions',
                    'Munroe Island country canal canoe ride tickets',
                    'Jatayu Earth Center regular entry & cable car tickets'
                ],
                'exclusions': [
                    'Adventure park activities at Jatayu (paintball, zipline, etc.)',
                    'Lunches and Dinners at cliffside cafes',
                    'Surfing lessons or yoga classes'
                ],
                'itinerary': [
                    {
                        'day': 1,
                        'title': 'Arrival & Varkala Red Cliff Sunset Walk',
                        'description': 'Pickup from Trivandrum or Varkala Station. Check in at Cliff-view resort. Afternoon dip at Papanasam beach holy spring waters. Evening cliff promenade walk enjoying chilled fresh juices and candlelit seafood.',
                        'meals': 'Welcome drink included',
                        'stay': 'Varkala Cliff Breeze Resort'
                    },
                    {
                        'day': 2,
                        'title': 'Jatayu Earth Center Cable Car & Munroe Island Mangroves',
                        'description': 'Drive to Chadayamangalam to explore the colossal Jatayu sculpture. Ride the scenic cable car up the granite hill. Proceed to Munroe Island for a quiet afternoon wooden canoe cruise through narrow mangrove canals.',
                        'meals': 'Breakfast included',
                        'stay': 'Varkala Cliff Breeze Resort'
                    },
                    {
                        'day': 3,
                        'title': 'Kappil Estuary & Departure',
                        'description': 'Morning coastal drive to Kappil beach where backwaters flow alongside the sea. Visit 2,000-year-old Janardhana Swamy temple before drop-off at Trivandrum Airport / Station.',
                        'meals': 'Breakfast included',
                        'stay': 'Tour Concludes'
                    }
                ],
                'rating': 4.94,
                'review_count': 38,
                'is_featured': True
            }
        ]

        count = 0
        for data in packages_data:
            obj, created = TourPackage.objects.update_or_create(
                id=data['id'],
                defaults=data
            )
            count += 1
            action = 'Created' if created else 'Updated'
            self.stdout.write(self.style.SUCCESS(f"{action} tour package: {obj.title}"))

        self.stdout.write(self.style.SUCCESS(f"Successfully seeded {count} Kerala Tour Packages!"))
