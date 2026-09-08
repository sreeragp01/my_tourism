import uuid
from decimal import Decimal
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model

from apps.accommodations.models import Accommodation, RoomType, RoomInventory
from apps.experiences.models import Experience, ExperienceSlot
from apps.ai.models import AIPlan, AIPlanVersion
from apps.inventory.models import InventoryHold
from apps.bookings.models import Booking

User = get_user_model()

class MasterE2EJourneyTestCase(TestCase):
    """
    🔥 MASTER END-TO-END TRANSACTIONAL TRIP ENGINE TEST
    Validates the entire unbroken traveler journey through all subsystems:
      1. Register & Login
      2. Synthesize AI Plan (v1)
      3. Customize Plan (v2)
      4. Query Authoritative Inventory
      5. Acquire 15-Minute Row-Locked Holds
      6. Create Booking from Holds (PENDING_PAYMENT)
      7. Create Razorpay Payment Order (PAYMENT_PROCESSING)
      8. Verify Cryptographic Payment Signature (CONFIRMED)
      9. Ingest Razorpay Webhook with Idempotency Guard
      10. Verify Authoritative Capacity Transfer (held -> booked)
      11. Generate Digital Boarding Pass & QR Token
      12. Query My Trips List
      13. Query Deep Trip Details with Vouchers & Chauffeur
      14. Verify Public Digital Pass Scanner Endpoint
    """

    def setUp(self):
        self.client = APIClient()
        self.today = timezone.now().date()
        self.org_id = uuid.uuid4()

        # Seed authoritative inventory: Room
        self.accommodation = Accommodation.objects.create(
            id="acc_e2e_houseboat",
            org_id=self.org_id,
            destination_id="dest_alleppey",
            name="Luxury Heritage Alleppey Houseboat",
            type="LUXURY_HOUSEBOAT",
            tagline="Premier Backwater Cruise",
            description="Private 2-bedroom luxury houseboat on Vembanad Lake",
            hero_image="https://images.unsplash.com/photo-1602216056096-3b40cc0c9944",
            base_price_per_night=Decimal("8500.00"),
        )
        self.room_type = RoomType.objects.create(
            id="room_e2e_houseboat_suite",
            accommodation=self.accommodation,
            name="Upper Deck Jacuzzi Suite",
            price_per_night=Decimal("8500.00"),
            capacity=2,
        )
        self.room_inv = RoomInventory.objects.create(
            room_type=self.room_type,
            date=self.today,
            total_rooms=5,
            booked_rooms=0,
            held_rooms=0,
        )

        # Seed authoritative inventory: Experience
        self.experience = Experience.objects.create(
            id="exp_e2e_kayaking",
            org_id=self.org_id,
            destination_id="dest_alleppey",
            title="Sunrise Shikara & Village Canoe Trail",
            category="WATER",
            description="Guided backwater canal exploration",
            price_per_person=Decimal("1200.00"),
            duration_hours=2.5,
            max_group_size=6,
            hero_image="https://images.unsplash.com/photo-1544644181-1484b3fdfc62",
            meeting_point="Punnamada Finishing Point",
            host_name="Unni",
            host_role="Master Boatman",
            verified=True,
            rain_friendly=True,
        )
        self.slot = ExperienceSlot.objects.create(
            experience=self.experience,
            date=self.today,
            start_time="06:30",
            end_time="09:00",
            total_capacity=8,
            booked_capacity=0,
            held_capacity=0,
        )

    def test_full_master_e2e_transactional_journey(self):
        # -------------------------------------------------------------
        # STEP 1: REGISTER & AUTHENTICATE TRAVELER
        # -------------------------------------------------------------
        reg_payload = {
            "email": "master_traveler@keralink.travel",
            "password": "MasterSecurePassword2026!",
            "first_name": "Sreerag",
            "last_name": "P",
            "phone_number": "+91 98470 99999",
        }
        reg_resp = self.client.post('/api/v1/auth/register/', reg_payload, format='json')
        self.assertIn(reg_resp.status_code, [status.HTTP_201_CREATED, status.HTTP_200_OK])

        # Login to obtain JWT tokens
        login_payload = {
            "email": "master_traveler@keralink.travel",
            "password": "MasterSecurePassword2026!",
        }
        login_resp = self.client.post('/api/v1/auth/login/', login_payload, format='json')
        self.assertEqual(login_resp.status_code, status.HTTP_200_OK)

        access_token = login_resp.data['data']['tokens']['access_token']
        self.assertIsNotNone(access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

        user = User.objects.get(email="master_traveler@keralink.travel")

        # -------------------------------------------------------------
        # STEP 2 & 3: AI PLAN GENERATION & CUSTOMIZATION (v1 -> v2)
        # -------------------------------------------------------------
        gen_payload = {
            'duration_days': 2,
            'budget_limit': 35000.0,
            'interests': ['Nature', 'Culture'],
            'adults': 2,
            'month': 'October',
            'monsoon_mode': False,
        }
        plan_resp = self.client.post('/api/v1/ai/generate-itinerary/', data=gen_payload, format='json')
        self.assertEqual(plan_resp.status_code, status.HTTP_200_OK)
        plan_data = plan_resp.json()
        plan_id = plan_data['plan_id']
        self.assertEqual(plan_data['version_number'], 1)

        # Customize to v2
        ev_to_remove = plan_data['days'][0]['timeline'][1]['id']
        cust_resp = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={
                "operation": "REMOVE_EVENT",
                "day_number": 1,
                "event_id": ev_to_remove,
                "reason": "Optimize schedule for sunset cruise",
            },
            format='json',
        )
        self.assertEqual(cust_resp.status_code, status.HTTP_200_OK)
        data_v2 = cust_resp.json()
        self.assertEqual(data_v2['version_number'], 2)

        # -------------------------------------------------------------
        # STEP 4: CHECK AUTHORITATIVE INVENTORY AVAILABILITY
        # -------------------------------------------------------------
        avail_resp = self.client.get(
            f'/api/v1/inventory/availability/?inventory_type=ROOM&inventory_id={self.room_inv.id}&quantity=1'
        )
        self.assertEqual(avail_resp.status_code, status.HTTP_200_OK)
        self.assertTrue(avail_resp.data['is_available'])
        self.assertEqual(avail_resp.data['available_capacity'], 5)

        # -------------------------------------------------------------
        # STEP 5: ACQUIRE 15-MINUTE TRANSACTIONAL HOLDS (PostgreSQL row locks)
        # -------------------------------------------------------------
        batch_hold_payload = {
            "items": [
                {
                    "inventory_type": "ROOM",
                    "inventory_id": str(self.room_inv.id),
                    "quantity": 1,
                    "date": str(self.today),
                },
                {
                    "inventory_type": "EXPERIENCE",
                    "inventory_id": str(self.slot.id),
                    "quantity": 2,
                    "date": str(self.today),
                }
            ],
            "itinerary_version_id": "v2",
            "duration_mins": 15,
        }
        hold_resp = self.client.post('/api/v1/inventory/holds/itinerary/', batch_hold_payload, format='json')
        self.assertEqual(hold_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(hold_resp.data['status'], 'ALL_HELD')
        holds_list = hold_resp.data['holds']
        self.assertEqual(len(holds_list), 2)
        hold_ids = [h['id'] for h in holds_list]

        # Verify capacities in DB: held incremented, booked untouched
        self.room_inv.refresh_from_db()
        self.slot.refresh_from_db()
        self.assertEqual(self.room_inv.held_rooms, 1)
        self.assertEqual(self.slot.held_capacity, 2)
        self.assertEqual(self.room_inv.booked_rooms, 0)
        self.assertEqual(self.slot.booked_capacity, 0)

        # -------------------------------------------------------------
        # STEP 6: CREATE BOOKING FROM ACTIVE HOLDS (PENDING_PAYMENT)
        # -------------------------------------------------------------
        bkg_payload = {
            "hold_ids": hold_ids,
            "primary_guest_name": "Sreerag P",
            "primary_guest_phone": "+91 98470 99999",
            "primary_guest_email": "master_traveler@keralink.travel",
            "trip_title": "Backwater & Heritage Bliss (v2)",
            "travelers_count": 2,
            "itinerary_version_id": "v2",
            "idempotency_key": f"e2e_bkg_{uuid.uuid4().hex[:12]}",
        }
        bkg_resp = self.client.post('/api/v1/bookings/', bkg_payload, format='json')
        self.assertEqual(bkg_resp.status_code, status.HTTP_201_CREATED)
        booking_data = bkg_resp.data
        booking_id = booking_data['id']
        booking_ref = booking_data['booking_reference']
        self.assertEqual(booking_data['status'], 'PENDING_PAYMENT')

        # Financial breakdown verification: 8500*1 + 1200*2 = 10900 subtotal
        self.assertEqual(Decimal(str(booking_data['subtotal'])), Decimal('10900.00'))
        self.assertEqual(Decimal(str(booking_data['tax'])), Decimal('545.00')) # 5% GST
        self.assertEqual(Decimal(str(booking_data['platform_fee'])), Decimal('218.00')) # 2% Fee
        self.assertEqual(Decimal(str(booking_data['total_amount'])), Decimal('11663.00'))

        # -------------------------------------------------------------
        # STEP 7: CREATE RAZORPAY PAYMENT ORDER (PAYMENT_PROCESSING)
        # -------------------------------------------------------------
        pay_order_payload = {
            "booking_id": booking_id,
            "idempotency_key": f"e2e_pay_{uuid.uuid4().hex[:12]}",
            "gateway": "RAZORPAY",
        }
        order_resp = self.client.post('/api/v1/payments/create-order/', pay_order_payload, format='json')
        self.assertEqual(order_resp.status_code, status.HTTP_201_CREATED)
        gateway_order_id = order_resp.data['gateway_order_id']
        self.assertIsNotNone(gateway_order_id)

        # Booking transitions to PAYMENT_PROCESSING
        booking_record = Booking.objects.get(id=booking_id)
        self.assertEqual(booking_record.status, 'PAYMENT_PROCESSING')

        # -------------------------------------------------------------
        # STEP 8: VERIFY AUTHORITATIVE PAYMENT SIGNATURE (CONFIRMED)
        # -------------------------------------------------------------
        verify_payload = {
            "booking_id": booking_id,
            "gateway_order_id": gateway_order_id,
            "gateway_payment_id": "pay_e2e_rzp_999",
            "gateway_signature": "sig_sim_valid_e2e",
        }
        verify_resp = self.client.post('/api/v1/payments/verify/', verify_payload, format='json')
        self.assertEqual(verify_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(verify_resp.data['status'], 'confirmed')
        self.assertIsNotNone(verify_resp.data['digital_pass_token'])

        # -------------------------------------------------------------
        # STEP 9: INGEST RAZORPAY WEBHOOK WITH IDEMPOTENCY GUARD
        # -------------------------------------------------------------
        webhook_event_id = f"evt_rzp_e2e_{uuid.uuid4().hex[:8]}"
        webhook_payload = {
            "event_id": webhook_event_id,
            "event_type": "payment.captured",
            "payload": {
                "booking_id": booking_id,
                "order_id": gateway_order_id,
                "payment_id": "pay_e2e_rzp_999",
            },
        }

        # First webhook arrival -> processed
        wh_resp1 = self.client.post('/api/v1/payments/webhook/', webhook_payload, format='json')
        self.assertEqual(wh_resp1.status_code, status.HTTP_200_OK)
        self.assertEqual(wh_resp1.data['status'], 'confirmed')

        # Second duplicate webhook arrival -> safely ignored via ProcessedWebhookEvent
        wh_resp2 = self.client.post('/api/v1/payments/webhook/', webhook_payload, format='json')
        self.assertEqual(wh_resp2.status_code, status.HTTP_200_OK)
        self.assertEqual(wh_resp2.data['status'], 'already_processed')
        self.assertEqual(wh_resp2.data['event_id'], webhook_event_id)

        # -------------------------------------------------------------
        # STEP 10: VERIFY AUTHORITATIVE INVENTORY CONSUMPTION (held -> booked)
        # -------------------------------------------------------------
        self.room_inv.refresh_from_db()
        self.slot.refresh_from_db()
        self.assertEqual(self.room_inv.held_rooms, 0)
        self.assertEqual(self.room_inv.booked_rooms, 1) # Transferred!
        self.assertEqual(self.slot.held_capacity, 0)
        self.assertEqual(self.slot.booked_capacity, 2) # Transferred!

        for h_id in hold_ids:
            h = InventoryHold.objects.get(id=h_id)
            self.assertEqual(h.status, 'CONFIRMED')
            self.assertEqual(str(h.booking_id), str(booking_id))

        # -------------------------------------------------------------
        # STEP 11: VERIFY CONFIRMED BOOKING & DIGITAL PASS TOKEN
        # -------------------------------------------------------------
        booking_record.refresh_from_db()
        self.assertEqual(booking_record.status, 'CONFIRMED')
        self.assertIsNotNone(booking_record.confirmed_at)
        self.assertTrue(booking_record.digital_pass_token.startswith('KL-PASS-'))

        # -------------------------------------------------------------
        # STEP 12: QUERY MY TRIPS LIST (GET /api/v1/trips/)
        # -------------------------------------------------------------
        trips_resp = self.client.get('/api/v1/trips/')
        self.assertEqual(trips_resp.status_code, status.HTTP_200_OK)
        trips = trips_resp.data['trips']
        self.assertGreaterEqual(len(trips), 1)

        matched_trip = next((t for t in trips if t['booking_reference'] == booking_ref), None)
        self.assertIsNotNone(matched_trip)
        self.assertEqual(matched_trip['status'], 'CONFIRMED')
        self.assertEqual(matched_trip['items_count'], 2)
        self.assertEqual(matched_trip['digital_pass_token'], booking_record.digital_pass_token)

        # -------------------------------------------------------------
        # STEP 13: QUERY DEEP TRIP DETAILS (GET /api/v1/trips/<ref>/)
        # -------------------------------------------------------------
        detail_resp = self.client.get(f'/api/v1/trips/{booking_ref}/')
        self.assertEqual(detail_resp.status_code, status.HTTP_200_OK)
        detail = detail_resp.data
        self.assertEqual(detail['booking_reference'], booking_ref)
        self.assertEqual(detail['status'], 'CONFIRMED')
        self.assertEqual(len(detail['items']), 2)
        self.assertTrue(any("Upper Deck Jacuzzi Suite" in it['title'] for it in detail['items']))
        self.assertTrue(any("Sunrise Shikara" in it['title'] for it in detail['items']))
        self.assertIn("Rajesh Kumar", detail['chauffeur']['name'])
        self.assertTrue(detail['digital_pass']['is_valid'])

        # -------------------------------------------------------------
        # STEP 14: PUBLIC DIGITAL PASS SCANNER VERIFICATION (GET /api/v1/bookings/pass/<ref>/)
        # -------------------------------------------------------------
        pass_resp = self.client.get(f'/api/v1/bookings/pass/{booking_ref}/')
        self.assertEqual(pass_resp.status_code, status.HTTP_200_OK)
        self.assertTrue(pass_resp.data['valid'])
        self.assertEqual(pass_resp.data['booking_reference'], booking_ref)
        self.assertEqual(pass_resp.data['guest_name'], "Sreerag P")
        self.assertEqual(pass_resp.data['status'], "CONFIRMED")
        self.assertEqual(pass_resp.data['items_count'], 2)
        self.assertEqual(pass_resp.data['pass_token'], booking_record.digital_pass_token)
