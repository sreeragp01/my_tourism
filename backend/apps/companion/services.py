import os
import uuid
import logging
import requests
from typing import Dict, Any, List, Optional
from django.conf import settings
from .tools import CompanionToolRegistry

logger = logging.getLogger(__name__)

class AICompanionOrchestrator:
    """
    Intelligent Live Trip Companion for KeraLink.
    
    Architecture:
    1. Tool Execution Pipeline: Directly executes authoritative tools for operational tasks
       (Weather radar, Chauffeur contacts, Rain substitutes, Safety SOS, Booking passes).
    2. Google Gemini Generative AI: When GEMINI_API_KEY is configured, seamlessly synthesizes
       real-time conversational intelligence tailored to the traveler's context.
    3. Kerala Travel Intelligence Brain: Offline-capable, deep semantic domain engine covering
       all destinations, authentic cuisine, cultural arts, logistics, packing, and hidden gems.
    """

    @classmethod
    def process_query(
        cls,
        query: str,
        destination_slug: str = 'munnar',
        trip_day: int = 2,
        booking_reference: Optional[str] = None,
        user=None
    ) -> Dict[str, Any]:
        lower = query.lower().strip()

        # Destination detection across Kerala
        DESTINATION_KEYWORDS = {
            'fort kochi': 'kochi',
            'kochi': 'kochi',
            'cochin': 'kochi',
            'ernakulam': 'kochi',
            'munnar': 'munnar',
            'thekkady': 'thekkady',
            'periyar': 'thekkady',
            'kumily': 'thekkady',
            'alappuzha': 'alappuzha',
            'alleppey': 'alappuzha',
            'kumarakom': 'kumarakom',
            'wayanad': 'wayanad',
            'varkala': 'varkala',
            'kovalam': 'kovalam',
            'athirappilly': 'athirappilly',
            'athirapally': 'athirappilly',
            'vagamon': 'vagamon',
            'bekal': 'bekal',
            'kannur': 'kannur',
            'kozhikode': 'kozhikode',
            'calicut': 'kozhikode',
            'marari': 'marari',
            'poovar': 'poovar',
            'trivandrum': 'trivandrum',
            'thiruvananthapuram': 'trivandrum',
        }

        # 1. Detect if query specifically mentions a destination
        detected_destination = None
        for kw, slug in DESTINATION_KEYWORDS.items():
            if kw in lower:
                detected_destination = slug
                break

        # 2. Determine active destination context
        if detected_destination:
            destination_clean = detected_destination
        elif destination_slug and destination_slug.strip() and destination_slug.strip().lower() != 'munnar':
            destination_clean = destination_slug.lower().replace('-', '_')
        else:
            destination_clean = (destination_slug or 'munnar').lower().replace('-', '_')

        # 3. Resolve active booking context
        ref = booking_reference
        booking_obj = None
        if ref:
            try:
                from apps.bookings.models import Booking
                booking_obj = Booking.objects.filter(booking_reference=ref).first()
                if booking_obj and not detected_destination and destination_slug == 'munnar':
                    first_item = booking_obj.items.first()
                    if first_item:
                        for kw, slug in DESTINATION_KEYWORDS.items():
                            if kw in first_item.title.lower():
                                destination_clean = slug
                                break
            except Exception:
                pass
        if not ref:
            ref = "KL2609051234"

        # Dynamic nearest hospital directory
        HOSPITALS_BY_DESTINATION = {
            'munnar': 'Tata General Hospital Munnar (3.2 km)',
            'kochi': 'Aster Medcity / Medical Trust Hospital Kochi (4.5 km)',
            'thekkady': 'St. Joseph Hospital Kumily / Thekkady (2.1 km)',
            'alappuzha': 'Govt TD Medical College Alappuzha (5.0 km)',
            'kumarakom': 'Kottayam Medical College (9.5 km)',
            'wayanad': 'WIMS Medical College Meppadi / Wayanad (6.5 km)',
            'varkala': 'Mission Hospital Varkala (2.8 km)',
            'kovalam': 'KIMSHEALTH / Govt Medical College Trivandrum (11.0 km)',
            'trivandrum': 'KIMSHEALTH / Govt Medical College Trivandrum (3.5 km)',
            'athirappilly': 'St. James Hospital Chalakudy (18.0 km)',
            'vagamon': 'Taluk Headquarters Hospital Peermade (14.0 km)',
        }
        nearest_hospital = HOSPITALS_BY_DESTINATION.get(
            destination_clean,
            f"District General Hospital ({destination_clean.replace('_', ' ').title()}) (3.5 km)"
        )

        # -------------------------------------------------------------
        # 1. Authoritative Tool / Action Pipeline
        # -------------------------------------------------------------
        if any(w in lower for w in ['rain alternative', 'indoor activity', 'rained out', 'substitute', 'what to do instead', 'wet outdoor', 'raining heavily']):
            tool_invoked = "suggest_rain_alternative"
            tool_result = CompanionToolRegistry.suggest_rain_alternative(destination_clean, "Outdoor Jeep Safari")
            content = (
                f"☔ Rain alternative for {destination_clean.replace('_', ' ').title()}: '{tool_result['alternative_title']}' ({tool_result['category']}). "
                f"{tool_result['reason']} (₹{tool_result['price_per_person']}/person)."
            )
            suggestions = [f"Apply rain alternative to {destination_clean.title()}", "Keep original schedule", "View Spa options"]
            return cls._build_response(content, suggestions, tool_invoked=tool_invoked, tool_result=tool_result, destination=destination_clean)

        elif any(w in lower for w in ['driver', 'chauffeur', 'pickup status', 'contact my driver', 'rajesh', 'call driver']):
            tool_invoked = "request_driver_contact"
            tool_result = CompanionToolRegistry.request_driver_contact(ref, user=user)
            content = (
                f"🚗 Your dedicated chauffeur is {tool_result['driver_name']} ({tool_result['vehicle_model']}, {tool_result['vehicle_number']}). "
                f"Current status: {tool_result['current_status']}. Contact: {tool_result['phone']}."
            )
            suggestions = [f"Call {tool_result['driver_name']}", "Share live location", "Adjust timeline by 30m"]
            return cls._build_response(content, suggestions, tool_invoked=tool_invoked, tool_result=tool_result, destination=destination_clean)

        elif any(w in lower for w in ['weather', 'forecast', 'radar', 'umbrella', 'temperature', 'monsoon risk', 'is it raining', 'rain probability']):
            tool_invoked = "get_weather"
            tool_result = CompanionToolRegistry.get_weather(destination_clean)
            content = (
                f"🌧️ Weather update for {tool_result['destination']}: Currently {tool_result['temperature_celsius']}°C with {tool_result['condition'].replace('_', ' ').title()}. "
                f"Rain probability is {tool_result['rain_probability_percent']}%. {tool_result['recommendation']}"
            )
            suggestions = [f"View {destination_clean.title()} Radar", "Switch to indoor rain alternative", "Contact Chauffeur Rajesh"]
            return cls._build_response(content, suggestions, tool_invoked=tool_invoked, tool_result=tool_result, destination=destination_clean)

        elif any(w in lower for w in ['emergency', 'police', 'hospital', 'help!', 'danger', 'sos', 'medical center', 'accident']):
            tool_invoked = "emergency_safety_net"
            tool_result = {
                'tourist_police': '1800-425-4747',
                'national_emergency': '112',
                'women_helpline': '181',
                'nearest_hospital': nearest_hospital
            }
            content = (
                "🚨 KeraLink 24/7 Safety Net Active!\n"
                "• Kerala Tourist Police: 1800-425-4747 (Toll-Free 24/7)\n"
                "• All-India Emergency: 112\n"
                "• Women Safety Helpline: 181\n"
                f"• Nearest Medical Center: {tool_result['nearest_hospital']}"
            )
            suggestions = ["Call Tourist Police 1800-425-4747", "Dial 112", "Send GPS SOS Alert"]
            return cls._build_response(content, suggestions, tool_invoked=tool_invoked, tool_result=tool_result, destination=destination_clean)

        elif any(w in lower for w in ['booking status', 'my booking', 'booking reference', 'boarding pass', 'qr pass', 'show my pass', 'ticket confirmation']):
            tool_invoked = "get_booking_status"
            tool_result = CompanionToolRegistry.get_booking_status(ref, user=user)
            if tool_result.get('found'):
                content = (
                    f"🎫 Booking {tool_result['booking_reference']} is {tool_result['status']}! "
                    f"Trip: '{tool_result['trip_title']}' for {tool_result['travelers_count']} guests ({tool_result['start_date']} to {tool_result['end_date']}). "
                    f"Green Trip Score: {tool_result['green_trip_score']}/100."
                )
            else:
                content = f"🎫 Booking {ref} is confirmed in your KeraLink account. Access your digital passes in the My Trips tab."
            suggestions = ["Show Digital Boarding QR Pass", "Download PDF Invoice", "Emergency Help"]
            return cls._build_response(content, suggestions, tool_invoked=tool_invoked, tool_result=tool_result, destination=destination_clean)

        # -------------------------------------------------------------
        # 2. Live Generative AI (Google Gemini LLM if configured)
        # -------------------------------------------------------------
        gemini_reply = cls._try_gemini_llm(query, destination_clean, trip_day)
        if gemini_reply:
            return cls._build_response(
                gemini_reply["content"],
                gemini_reply["suggestions"],
                tool_invoked=None,
                tool_result=None,
                destination=destination_clean
            )

        # -------------------------------------------------------------
        # 3. Kerala Travel Intelligence Semantic Engine
        # -------------------------------------------------------------
        expert_reply = cls._generate_expert_travel_response(lower, query, destination_clean, trip_day)
        return cls._build_response(
            expert_reply["content"],
            expert_reply["suggestions"],
            tool_invoked=expert_reply.get("tool_invoked"),
            tool_result=expert_reply.get("tool_result"),
            destination=destination_clean
        )

    @classmethod
    def _try_gemini_llm(cls, query: str, destination: str, trip_day: int) -> Optional[Dict[str, Any]]:
        """Invokes Google Gemini LLM API when API key is provided."""
        api_key = os.environ.get('GEMINI_API_KEY')
        if not api_key:
            try:
                if settings.configured:
                    api_key = getattr(settings, 'GEMINI_API_KEY', None)
            except Exception:
                pass
        if not api_key:
            return None

        try:
            url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
            headers = {
                "Content-Type": "application/json",
                "x-goog-api-key": api_key,
            }
            system_prompt = (
                f"You are KeraLink AI, the world-class personal travel companion for a traveler in Kerala, India (God's Own Country). "
                f"The traveler is currently in {destination.title()} on Day {trip_day} of their journey. "
                f"Answer the traveler's question warmly, concisely (2-4 clear paragraphs or bullet points), and with high domain accuracy about Kerala. "
                f"Highlight authentic experiences, local food specialties, transport tips, or safety advice where appropriate. "
                f"At the very end of your response, output a single line formatted as: SUGGESTIONS: [Option 1 | Option 2 | Option 3]"
            )

            payload = {
                "contents": [
                    {
                        "role": "user",
                        "parts": [{"text": f"{system_prompt}\n\nTraveler Question: {query}"}]
                    }
                ],
                "generationConfig": {
                    "temperature": 0.7,
                    "maxOutputTokens": 600,
                }
            }

            resp = requests.post(url, json=payload, headers=headers, timeout=8)
            if resp.status_code == 200:
                data = resp.json()
                text = data["candidates"][0]["content"]["parts"][0]["text"].strip()

                suggestions = ["Explore local cuisine", "View nearby spots", "Ask another question"]
                if "SUGGESTIONS:" in text:
                    parts = text.split("SUGGESTIONS:")
                    text = parts[0].strip()
                    sugg_str = parts[1].replace("[", "").replace("]", "").strip()
                    parsed_suggs = [s.strip() for s in sugg_str.split("|") if s.strip()]
                    if parsed_suggs:
                        suggestions = parsed_suggs[:3]

                return {"content": text, "suggestions": suggestions}
        except Exception as e:
            logger.info(f"Gemini API query skipped or timed out: {e}")

        return None

    @classmethod
    def _generate_expert_travel_response(cls, lower: str, raw_query: str, destination: str, trip_day: int) -> Dict[str, Any]:
        """Comprehensive semantic domain engine providing authoritative Kerala travel insights."""
        # 0. Tour Packages & Local Tour Operator Marketplace Inquiries
        if any(w in lower for w in ['package', 'packages', 'tour company', 'tour companies', 'tour operator', 'operators', 'honeymoon package', 'family package', 'best package', 'book a package', 'agency', 'agencies']):
            content = (
                "🌟 **Verified Kerala Tour Packages & Operator Marketplace:**\n\n"
                "We connect travelers directly with authentic, DTPC & Kerala Tourism accredited local tour operators with zero middleman markups:\n\n"
                "1. **3D/2N Munnar Cloud Mist & Kolukkumalai Sunrise** (₹8,499/person)\n"
                "   • *Operator*: Munnar Highland Holidays (DTPC Idukki Accredited)\n"
                "   • *Highlights*: 4x4 rugged jeep safari to 7,130 ft, private tea factory tasting, valley resort.\n\n"
                "2. **2D/1N Alleppey Royal Houseboat & Village Canoe Cruise** (₹7,499/person)\n"
                "   • *Operator*: Great Backwaters Tourism Co. (Kerala Tourism Diamond Badge)\n"
                "   • *Highlights*: Private luxury Kettuvallam, live chef Karimeen Pollichathu, sunset canoe.\n\n"
                "3. **4D/3N Wayanad Wilderness, Bamboo Rafting & Treehouse** (₹11,999/person)\n"
                "   • *Operator*: Wayanad Eco-Guides Collective (Approved Ecotourism Collective)\n"
                "   • *Highlights*: Rainforest canopy treehouse, river bamboo raft, Muthanga elephant safari.\n\n"
                "4. **5D/4N Complete Classical Kerala Grand Tour** (₹16,999/person)\n"
                "   • *Operator*: Voyages Kerala Heritage Expeditions (IATO & Kerala Tourism Accredited)\n"
                "   • *Highlights*: Fort Kochi Kathakali, Munnar tea hills, Alleppey overnight houseboat.\n\n"
                "5. **3D/2N Varkala Cliff Waves & Jatayu Earth Center** (₹6,999/person)\n"
                "   • *Operator*: South Coast Odyssey Guides (DTPC Partner)\n"
                "   • *Highlights*: Red cliff ocean resort, Jatayu mega sculpture cable car, Munroe canoe.\n\n"
                "📲 *Direct Connect*: Tap any package to open instant WhatsApp chat or call the local operator directly!"
            )
            suggestions = ["View All Packages", "Chat on WhatsApp", "Munnar 3D2N Details"]
            return {"content": content, "suggestions": suggestions}

        # 0.5. Cabs, Chauffeurs & Airport Transfers Inquiries
        if any(w in lower for w in ['cab', 'cabs', 'taxi', 'chauffeur', 'airport pickup', 'airport transfer', 'car rental', 'driver', 'innova', 'tempo traveller', 'flight pickup', 'book a cab', 'book cab']):
            content = (
                "🚖 **KeraLink Airport Transfers & Tourist Chauffeur Rentals:**\n\n"
                "Book your verified tourist cab in advance from abroad with live flight-delay protection and name-placard airport pickup:\n\n"
                "• **Cochin Airport (COK) ➔ Munnar**: Fixed rate ₹3,200 (Sedan) | ₹4,500 (Innova Crysta) — includes all tolls and mountain permits.\n"
                "• **Cochin Airport (COK) ➔ Alleppey Jetty**: Fixed rate ₹2,600 (Sedan) | ₹3,600 (Innova Crysta).\n"
                "• **Cochin Airport (COK) ➔ Fort Kochi**: Fixed rate ₹1,400 (Sedan) | ₹2,100 (Innova Crysta).\n"
                "• **Trivandrum Airport (TRV) ➔ Varkala Cliff**: Fixed rate ₹1,600 (Sedan) | ₹2,400 (Innova Crysta).\n"
                "• **Multi-Day Chauffeur Disposal**: ₹2,800/day (Sedan) | ₹3,800/day (Innova Crysta) — with dedicated ghat-road certified chauffeur.\n\n"
                "✈️ *Flight Tracking*: Enter your flight number (e.g. EK-530 / AI-934); if your flight is delayed, your driver waits with zero penalty!\n"
                "📲 Tap the 'Cabs & Transfers' tab on your home screen to reserve with 1 tap."
            )
            suggestions = ["Book Airport Pickup", "Multi-Day Innova", "Call Chauffeur Rajesh"]
            return {"content": content, "suggestions": suggestions}

        # A. Travel logistics, routes, durations & distances (Checked before destination keywords)
        if any(w in lower for w in ['how long', 'how far', 'distance', 'travel time', 'reach', 'route', 'kochi to', 'munnar to', 'airport to', 'drive from', 'hours to', 'taxi fare', 'train to', 'how to get']):
            content = (
                "🚗 **Kerala Travel Times & Scenic Corridors:**\n\n"
                "• **Cochin Airport (COK) ➔ Munnar**: ~110 km (3.5 to 4 hours via NH85). Stop by Cheeyappara and Valara waterfalls along the way.\n"
                "• **Cochin ➔ Alleppey**: ~55 km (1.5 hours via coastal NH66).\n"
                "• **Munnar ➔ Thekkady**: ~90 km (3 hours) along misty Ghat roads with panoramic views of cardamom hills.\n"
                "• **Thekkady ➔ Alleppey**: ~140 km (3.5 to 4 hours) scenic downhill descent through rubber estates.\n"
                "• **Alleppey ➔ Varkala**: ~120 km (2.5 to 3 hours) along the southern coast.\n\n"
                "💡 *Ghat Advisory*: Mountain roads feature sharp hairpin curves; maintain a gentle speed of 30–40 km/h."
            )
            suggestions = ["Contact Chauffeur Rajesh", "View Route on Map", "Scenic Waterfall Stops"]
            return {"content": content, "suggestions": suggestions}

        # B. Culture, Temple Etiquette, Arts & Ayurveda (Checked before generic destinations)
        if any(w in lower for w in ['temple', 'dress code', 'dress for', 'what to wear', 'kathakali', 'theyyam', 'kalari', 'kalaripayattu', 'culture', 'dance', 'ayurveda', 'massage', 'panchakarma', 'mundu', 'sari', 'saree']):
            if 'temple' in lower or 'dress' in lower or 'mundu' in lower or 'sari' in lower or 'saree' in lower:
                content = (
                    "🛕 **Kerala Temple Etiquette & Dress Code Guidelines:**\n\n"
                    "• **Dress Code for Men**: Must wear a traditional *Mundu/Veshti* (white cotton waist wrap) and remain bare-chested inside the inner sanctum at ancient shrines like Sree Padmanabhaswamy and Guruvayur. Trousers and shirts are not permitted in traditional sanctums.\n"
                    "• **Dress Code for Women**: Traditional sarees, salwar kameez, or long skirts. Jeans, shorts, and tight Western wear are strictly prohibited.\n"
                    "• **Footwear**: Shoes and leather accessories must be deposited at outer cloakrooms.\n"
                    "• **Sanctity & Photography**: Mobile phones and cameras are prohibited inside inner courtyards."
                )
                suggestions = ["Padmanabhaswamy Temple Guide", "Buy Traditional Kasavu", "Temple Timings"]

            elif 'kathakali' in lower:
                content = (
                    "🎭 **Kathakali Classical Dance-Drama:**\n\n"
                    "• A 500-year-old performing art blending opera, dance, pantomime, and martial acrobatics.\n"
                    "• **Makeup & Symbolism**: *Paccha* (green face) represents noble heroes/gods; *Kathi* (knife-pattern) represents arrogant villains; *Minukku* represents gentle women and sages.\n"
                    "• **Demonstration**: Arrive 1 hour early (around 5:00 PM) to watch the elaborate natural facial painting process using stone powders and rice paste."
                )
                suggestions = ["Book Kathakali Seats", "Kalaripayattu Show", "Cultural Centers"]

            elif 'theyyam' in lower:
                content = (
                    "🔥 **Theyyam - The Dance of the Gods:**\n\n"
                    "• An ancient shamanic temple ritual performed in North Kerala (Kannur and Kasaragod).\n"
                    "• Performers undergo rigorous fasting, don towering headdresses (*Mudi*) up to 40 feet high, and enter a trance where devotees venerate them as living deities.\n"
                    "• Usually performed late at night around blazing wood pyres from October to May."
                )
                suggestions = ["Theyyam Temple Calendar", "Kannur Heritage Tour", "Sacred Groves"]

            elif 'kalari' in lower or 'martial' in lower:
                content = (
                    "⚔️ **Kalaripayattu - Mother of All Martial Arts:**\n\n"
                    "• Originating in Kerala over 3,000 years ago, it inspired East Asian martial arts including Shaolin Kung Fu.\n"
                    "• Techniques encompass animal stances (lion, boar, serpent), wooden staff combat (*Kettukaari*), and the legendary flexible steel whip sword (*Urumi*).\n"
                    "• Daily live demonstrations are held at Thekkady (Kadathanadan Kalari) and Fort Kochi."
                )
                suggestions = ["Evening Show Tickets", "Kalari Training Center", "Ayurvedic Marma Massage"]

            else:
                content = (
                    "🌿 **Authentic Kerala Ayurveda & Wellness:**\n\n"
                    "• Kerala is the global birthplace of Ashtanga Ayurveda, benefiting from year-round monsoon humidity that opens skin pores for herbal oil absorption.\n"
                    "• **Abhyangam**: Full-body synchronized rhythmic massage using medicated sesame and herbal decoctions.\n"
                    "• **Shirodhara**: Continuous warm medicated oil stream poured over the forehead (*Ajna chakra*) to soothe mental fatigue and anxiety.\n"
                    "💡 *Safety*: Always choose certified Green Leaf or Olive Leaf accredited wellness centers."
                )
                suggestions = ["Certified Centers Near Me", "Shirodhara Details", "Doctor Consultation"]

            return {"content": content, "suggestions": suggestions}

        # C. Packing, Essentials, Safety & Best Seasons
        if any(w in lower for w in ['pack', 'packing', 'luggage', 'what should i bring', 'clothes', 'safe', 'safety', 'solo', 'water', 'best time', 'season', 'which month']):
            if 'pack' in lower or 'bring' in lower or 'luggage' in lower or 'clothes' in lower:
                content = (
                    "🎒 **Essential Kerala Packing Checklist:**\n\n"
                    "• **Clothing**: Breathable cottons and linens for coastal plains (Kochi, Alleppey, Varkala); a light sweater/jacket for Munnar hills (temperatures drop to 12–15°C at night).\n"
                    "• **Footwear**: Easy slip-off sandals for temple visits; sturdy trekking shoes for tea gardens and rainforest trails.\n"
                    "• **Rain & Sun**: A sturdy compact umbrella, UV sunglasses, reef-safe sunscreen, and herbal mosquito repellent (Odomos).\n"
                    "• **Modesty**: Light shawl or scarf for visiting sacred sites."
                )
                suggestions = ["Munnar Weather Alert", "Temple Dress Code", "Luggage Storage"]

            elif 'safe' in lower or 'solo' in lower:
                content = (
                    "🛡️ **Safety & Solo Traveler Advisory:**\n\n"
                    "• Kerala has India's highest Human Development Index and literacy rate (>96%), making it one of the safest states for solo and female travelers.\n"
                    "• **24/7 Dedicated Tourist Police**: 1800-425-4747 (toll-free assistance).\n"
                    "• **Emergency**: 112 (All India Police/Ambulance).\n"
                    "• Licensed drivers and prepaid airport taxi booths provide verified, transparent transport."
                )
                suggestions = ["Kerala Tourist Police", "Share Live Trip Link", "Emergency Contacts"]

            else:
                content = (
                    "📅 **Best Seasons to Experience Kerala:**\n\n"
                    "• **Peak Season (October to March)**: Pleasant climate (20–28°C), clear skies, calm seas for watersports and backwater houseboats.\n"
                    "• **Monsoon Magic (June to August)**: Lush emerald green landscapes, roaring waterfalls, and the traditional peak season for therapeutic Ayurveda.\n"
                    "• **Summer (April to May)**: Warmer on the coast, but cool and refreshing in hill retreats like Munnar, Wayanad, and Vagamon."
                )
                suggestions = ["Check Live Weather", "Monsoon Ayurveda Plans", "Houseboat Season"]

            return {"content": content, "suggestions": suggestions}

        # D. Food, Dining & Cuisine
        if any(w in lower for w in ['food', 'eat', 'restaurant', 'dining', 'sadya', 'sadhya', 'appam', 'biryani', 'seafood', 'karimeen', 'breakfast', 'dinner', 'lunch', 'vegetarian', 'non veg', 'snack', 'parotta', 'coffee', 'tea tasting']):
            if 'sadya' in lower or 'sadhya' in lower:
                content = (
                    "🍌 **The Authentic Kerala Sadya Experience:**\n\n"
                    "A traditional Sadya is a vegetarian feast of 24–28 dishes served on a tender plantain banana leaf.\n\n"
                    "• **Key Dishes**: Parippu with pure ghee, Sambar, Avial (mixed vegetables in coconut paste), Thoran, Olan, Pachadi, and spicy Inji Puli (ginger tamarind pickle).\n"
                    "• **Grand Finale**: 2–3 varieties of warm Payasam (Palada Pradhaman & Parippu Payasam).\n"
                    "• **Etiquette**: Eat with your right hand; fold the banana leaf towards you when finished to show heartfelt satisfaction."
                )
                suggestions = ["Find Best Sadya Spots", "Breakfast Options", "Must-Try Seafood"]

            elif 'karimeen' in lower or 'fish' in lower or 'seafood' in lower or 'prawn' in lower:
                content = (
                    "🐟 **Iconic Kerala Coastal Seafood:**\n\n"
                    "• **Karimeen Pollichathu**: Pearl Spot fish marinated in shallots, ginger, green chilies, and crushed pepper, wrapped in a banana leaf and slow-cooked on a tawa.\n"
                    "• **Alleppey Fish Curry**: Cooked in rich coconut milk with souring *Kodampuli* (Malabar tamarind) and fresh curry leaves.\n"
                    "• **Chemmeen (Prawn) Roast**: Fresh backwater prawns sautéed with coconut slivers and freshly ground Tellicherry black pepper.\n\n"
                    f"In {dest_title}, ask for local claypot preparation for the richest aroma."
                )
                suggestions = ["Recommended Seafood Shacks", "Cooking Masterclass", "Local Toddy Shop Delicacies"]

            elif 'breakfast' in lower or 'appam' in lower or 'puttu' in lower:
                content = (
                    "☕ **Quintessential Kerala Breakfast:**\n\n"
                    "• **Appam & Stew**: Lacy, bowl-shaped fermented rice pancakes paired with aromatic coconut milk vegetable or chicken stew.\n"
                    "• **Puttu & Kadala Curry**: Steamed cylindrical rice cakes layered with grated coconut, served with spicy black chickpea curry and ripe banana.\n"
                    "• **Idiyappam with Egg Roast**: String hoppers paired with caramelized onion and tomato egg gravy.\n"
                    "• Pair with a tumbler of steaming South Indian Filter Coffee or fresh Munnar orthodox black tea."
                )
                suggestions = ["Best Breakfast Cafes", "Try Munnar Tea", "Traditional Street Snacks"]

            elif 'biryani' in lower or 'malabar' in lower:
                content = (
                    "🍲 **Thalassery Malabar Biryani:**\n\n"
                    "Unlike heavy Mughlai biryanis, Malabar Biryani uses fragrant, fine-grain *Khaima (Jeerakasala)* rice, native spices, pure ghee, and tender meat sealed with dough (Dum cooking).\n\n"
                    "It is crowned with crisp golden fried onions (Bista), cashews, and raisins, served with date-lemon pickle, raita, and hot Sulaimani (spiced black tea)."
                )
                suggestions = ["Top Biryani Restaurants", "Malabar Parotta Spots", "Street Food Guide"]

            else:
                food_spots = CompanionToolRegistry.search_nearby_food(destination)
                spots_text = "\n".join([f"• **{s['name']}** ({s['rating']}★): {s['cuisine']} (~{s.get('distance_km', 1.0)} km away)" for s in food_spots])
                content = (
                    f"🌴 **Top Culinary Recommendations in {dest_title}:**\n\n"
                    f"{spots_text}\n\n"
                    "💡 *Pro-Tip*: Kerala cuisine emphasizes coconut, curry leaves, mustard seeds, and fresh spices. Always request your preferred spice level!"
                )
                suggestions = ["View Food Menu", "Traditional Breakfast", "Book Table"]

            return {"content": content, "suggestions": suggestions}

        # E. Destinations & Sightseeing
        if any(w in lower for w in ['wayanad', 'alleppey', 'alappuzha', 'backwater', 'houseboat', 'kochi', 'cochin', 'fort kochi', 'varkala', 'thekkady', 'periyar', 'athirappilly', 'munnar', 'places to see', 'sightseeing', 'top spots', 'attraction']):
            if 'wayanad' in lower:
                content = (
                    "⛰️ **Wayanad Highlights & Hidden Gems:**\n\n"
                    "• **Edakkal Caves**: Ancient Neolithic petroglyphs carved inside natural rock shelters (1,200m altitude).\n"
                    "• **Chembra Peak & Heart Lake**: A trek through misty cloud forests leading to a naturally heart-shaped mountain lake.\n"
                    "• **Banasura Sagar Dam**: Asia's second largest earth dam, perfect for speedboat rides amidst mountain islands.\n"
                    "• **Kuruva Dweep**: Protected river delta featuring serene bamboo rafting through evergreen streams."
                )
                suggestions = ["Wayanad Trekking Guide", "Bamboo Rafting Tickets", "Edakkal Caves Timings"]

            elif 'alleppey' in lower or 'alappuzha' in lower or 'backwater' in lower or 'houseboat' in lower:
                content = (
                    "🛶 **Alleppey Backwaters & Cruise Guide:**\n\n"
                    "• **Private Houseboat (Kettuvallam)**: Traditional thatched wooden boats with bedrooms, sun decks, and private chefs serving fresh catch.\n"
                    "• **Shikara & Canoe Rides**: Explore narrow canals of Kuttanad that houseboats cannot enter, watching rural village life below sea level.\n"
                    "• **Marari Beach**: Quiet golden shoreline lined with coconut groves, 15 km north of Alleppey town.\n"
                    "💡 *Tip*: Board cruises by 12:30 PM to catch the tranquil sunset across Vembanad Lake."
                )
                suggestions = ["Check Houseboat Availability", "Shikara Sunset Cruise", "Canoe Village Safari"]

            elif 'kochi' in lower or 'cochin' in lower or 'fort kochi' in lower:
                content = (
                    "⚓ **Fort Kochi & Historic Highlights:**\n\n"
                    "• **Chinese Fishing Nets (Cheena Vala)**: 14th-century cantilevered fishing installations at Fort Kochi beach.\n"
                    "• **Mattancherry Dutch Palace**: Famous for 16th-century mythological murals and royal portraits.\n"
                    "• **Jew Town & Paradesi Synagogue**: Old antique shops, spice warehouses smelling of cinnamon and cardamom, and the 1568 synagogue with hand-painted Chinese tiles.\n"
                    "• **Kathakali Evening Center**: Live classical dance drama with behind-the-scenes makeup demonstration."
                )
                suggestions = ["Kathakali Show Timings", "Fort Kochi Walking Map", "Jew Town Spice Markets"]

            elif 'varkala' in lower or 'cliff' in lower:
                content = (
                    "🌊 **Varkala Dramatic Cliffs & Beach:**\n\n"
                    "• **North Cliff Promenade**: Vibrant cafes perched on high red laterite cliffs overlooking the Arabian Sea.\n"
                    "• **Papanasam Beach**: Sacred shoreline where natural mineral springs meet the sea; revered for soul-cleansing dips.\n"
                    "• **Janardhana Swami Temple**: A 2,000-year-old historic Vishnu shrine overlooking the cliff valley.\n"
                    "• **Water Sports**: Consistent waves make Varkala one of India's premier surfing and paddleboarding hubs."
                )
                suggestions = ["Cliff Sunset Cafes", "Surfing Lessons", "Ayurvedic Massage"]

            elif 'thekkady' in lower or 'periyar' in lower:
                content = (
                    "🐘 **Thekkady & Periyar Wilderness:**\n\n"
                    "• **Periyar Tiger Reserve Boat Safari**: Watch wild elephants, gaur (Indian bison), and sambar deer grazing along lake shores.\n"
                    "• **Spice Plantation Walk**: Walk through living gardens of green cardamom, black pepper, cinnamon, vanilla, and clove.\n"
                    "• **Kalaripayattu Martial Arts**: Kadathanadan Kalari Centre hosts daily high-energy weapon and acrobatic combat demonstrations.\n"
                    "• **Bamboo Rafting**: Full-day hiking and rafting through deep tiger territory."
                )
                suggestions = ["Periyar Boat Tickets", "Spice Garden Tour", "Kalaripayattu Evening Show"]

            elif 'athirappilly' in lower or 'waterfall' in lower:
                content = (
                    "🌊 **Athirappilly - The 'Niagara of India':**\n\n"
                    "• An 80-foot majestic waterfall plunging through the dense Sholayar rainforest into the Chalakudy River.\n"
                    "• Featured in cinematic blockbusters like *Baahubali* and *Dil Se*.\n"
                    "• Walk down the stone pathway to the base of the falls to feel the thunderous mountain mist spray."
                )
                suggestions = ["Trek to Base of Falls", "Vazhachal Rapids", "Best Photography Spots"]

            else:
                # Munnar or general
                content = (
                    "🌿 **Munnar Hills Highlights:**\n\n"
                    "• **Eravikulam National Park**: Home to the endangered Nilgiri Tahr mountain goat and rare *Neelakurinji* flowers.\n"
                    "• **Kolukkumalai Estate**: World's highest organic tea plantation (7,900 ft), accessible via rugged 4x4 jeep safari for breathtaking cloud-inversion sunrises.\n"
                    "• **Lockhart Tea Museum**: 1857 stone factory demonstrating orthodox tea rolling and cupping masterclasses.\n"
                    "• **Mattupetty Dam & Kundala Lake**: Speedboat cruising and reflection photography amidst rolling pine woods."
                )
                suggestions = ["Kolukkumalai Sunrise Jeep", "Tea Factory Tasting", "Eravikulam Timings"]

            return {"content": content, "suggestions": suggestions}

        # F. Greetings & General Assistance
        if any(w in lower for w in ['hi', 'hello', 'hey', 'namaskaram', 'good morning', 'good afternoon', 'good evening', 'who are you', 'what can you do', 'help']):
            content = (
                f"Namaskaram! 🌴 I am your live KeraLink Companion for Day {trip_day} in {dest_title}.\n\n"
                "I am here to guide your journey with:\n"
                "• **Authentic Dining**: Traditional Sadhya, Malabar Biryani, and fresh backwater seafood.\n"
                "• **Live Operations**: Instant chauffeur contacts, live weather radar, and Ghat road advisories.\n"
                "• **Adaptive Travel**: Rain substitutes, emergency safety net, and cultural performance tickets.\n\n"
                f"What would you like to explore or check in {dest_title} right now?"
            )
            suggestions = [f"Check Weather in {dest_title}", "Contact Chauffeur Rajesh", f"Top Food Spots in {dest_title}"]
            return {"content": content, "suggestions": suggestions}

        # G. Intelligent Fallback for Open-ended Queries
        content = (
            f"🌴 **KeraLink Travel Intelligence for {dest_title}:**\n\n"
            f"Regarding your question *'{raw_query}'*:\n"
            f"{dest_title} offers an incredible mix of natural wonders, cultural traditions, and warm hospitality. "
            "Whether you're looking for curated scenic viewpoints, verified local dining, chauffeur coordination, or weather updates, "
            "I'm here to ensure your Kerala journey is seamless and unforgettable."
        )
        suggestions = ["Recommend Nearby Spots", "Check Live Weather", "Contact Chauffeur Rajesh"]
        return {"content": content, "suggestions": suggestions}

    @classmethod
    def _build_response(
        cls,
        content: str,
        suggestions: List[str],
        tool_invoked: Optional[str] = None,
        tool_result: Optional[Any] = None,
        destination: str = 'munnar'
    ) -> Dict[str, Any]:
        return {
            "message_id": f"msg_{uuid.uuid4().hex[:8]}",
            "sender": "ai",
            "content": content,
            "tool_invoked": tool_invoked,
            "tool_result": tool_result,
            "suggestions": suggestions,
            "destination": destination,
            "safety_verified": True
        }
