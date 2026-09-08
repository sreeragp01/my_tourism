import uuid
from decimal import Decimal
from datetime import timedelta
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.accommodations.models import Accommodation, RoomType, RoomInventory
from apps.experiences.models import Experience, ExperienceSlot
from apps.inventory.models import InventoryHold
from apps.inventory.services import InventoryService
from apps.bookings.models import Booking, BookingItem
from apps.bookings.services import BookingService, BookingValidationError
from apps.payments.services import IdempotentPaymentService
from integrations.payments.payment_gateway import PaymentSimulator

User = get_user_model()

class BookingIntegrationTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="traveler_c@keralink.travel",
            password="Password123!",
            first_name="Traveler",
            last_name="C",
        )
        self.other_user = User.objects.create_user(
            email="other@keralink.travel",
            password="Password123!",
            first_name="Other",
            last_name="Traveler",
        )
        self.today = timezone.now().date()

        # Accommodation & Room setup
        self.org_id = uuid.uuid4()
        self.accommodation = Accommodation.objects.create(
            id="acc_munnar_villa_c",
            org_id=self.org_id,
            destination_id="dest_munnar",
            name="Munnar Tea Estate Heritage Villa",
            type="HERITAGE_HOMESTAY",
            tagline="Colonial charm amidst misty hills",
            description="Heritage luxury bungalow",
            hero_image="https://images.unsplash.com/photo-1542314831-068cd1dbfeeb",
            base_price_per_night=Decimal("6000.00"),
        )
        self.room_type = RoomType.objects.create(
            id="room_munnar_chalet_c",
            accommodation=self.accommodation,
            name="Deluxe Heritage Chalet",
            price_per_night=Decimal("6000.00"),
            capacity=2,
        )
        self.room_inv = RoomInventory.objects.create(
            room_type=self.room_type,
            date=self.today,
            total_rooms=5,
            booked_rooms=0,
            held_rooms=0,
        )

        # Experience & Slot setup
        self.experience = Experience.objects.create(
            id="exp_kolukkumalai_c",
            org_id=self.org_id,
            destination_id="dest_munnar",
            title="Kolukkumalai Sunrise Tea Trek",
            category="NATURE",
            description="Highest tea estate sunrise experience",
            price_per_person=Decimal("1500.00"),
            duration_hours=3.5,
            max_group_size=10,
            hero_image="https://images.unsplash.com/photo-1506744038136-46273834b3fb",
            meeting_point="Suryanelli Base Camp",
            host_name="Mani",
            host_role="Mountain Guide",
            verified=True,
            rain_friendly=False,
        )
        self.slot = ExperienceSlot.objects.create(
            experience=self.experience,
            date=self.today,
            start_time="05:30",
            end_time="09:00",
            total_capacity=10,
            booked_capacity=0,
            held_capacity=0,
        )

    def test_hold_to_booking_creation_pending_payment(self):
        # Step 1: Create active holds for room and experience
        hold_room = InventoryService.create_hold(
            inventory_type='ROOM',
            inventory_id=str(self.room_inv.id),
            quantity=1,
            user=self.user,
            duration_mins=15,
        )
        hold_exp = InventoryService.create_hold(
            inventory_type='EXPERIENCE',
            inventory_id=str(self.slot.id),
            quantity=2,
            user=self.user,
            duration_mins=15,
        )

        self.room_inv.refresh_from_db()
        self.slot.refresh_from_db()
        self.assertEqual(self.room_inv.held_rooms, 1)
        self.assertEqual(self.slot.held_capacity, 2)

        # Step 2: Create booking from holds
        booking = BookingService.create_booking_from_holds(
            user=self.user,
            hold_ids=[str(hold_room.id), str(hold_exp.id)],
            primary_guest_name="Traveler C",
            primary_guest_phone="+91 98470 55555",
            primary_guest_email="traveler_c@keralink.travel",
            idempotency_key="bkg_integ_test_1",
            trip_title="Munnar Luxury Getaway",
            travelers_count=2,
            itinerary_version_id="v1",
        )

        self.assertEqual(booking.status, 'PENDING_PAYMENT')
        self.assertTrue(booking.booking_reference.startswith('KL'))
        # Subtotal: 6000 * 1 + 1500 * 2 = 9000
        self.assertEqual(booking.subtotal, Decimal('9000.00'))
        self.assertEqual(booking.tax, Decimal('450.00')) # 5%
        self.assertEqual(booking.platform_fee, Decimal('180.00')) # 2%
        self.assertEqual(booking.total_amount, Decimal('9630.00'))
        self.assertEqual(booking.items.count(), 2)

        # Verify holds are linked to booking
        hold_room.refresh_from_db()
        hold_exp.refresh_from_db()
        self.assertEqual(hold_room.booking_id, booking.id)
        self.assertEqual(hold_exp.booking_id, booking.id)

    def test_booking_creation_rejects_expired_hold(self):
        hold_room = InventoryService.create_hold(
            inventory_type='ROOM',
            inventory_id=str(self.room_inv.id),
            quantity=1,
            user=self.user,
            duration_mins=15,
        )

        # Manually backdate hold to simulate expiration
        hold_room.expires_at = timezone.now() - timedelta(minutes=1)
        hold_room.save()

        with self.assertRaises(BookingValidationError):
            BookingService.create_booking_from_holds(
                user=self.user,
                hold_ids=[str(hold_room.id)],
                primary_guest_name="Traveler C",
                primary_guest_phone="+91 98470 55555",
                primary_guest_email="traveler_c@keralink.travel",
                idempotency_key="bkg_integ_fail_expired",
            )

        # Verify booking was not created
        self.assertFalse(Booking.objects.filter(idempotency_key="bkg_integ_fail_expired").exists())

    def test_booking_creation_rejects_other_user_hold(self):
        hold_room = InventoryService.create_hold(
            inventory_type='ROOM',
            inventory_id=str(self.room_inv.id),
            quantity=1,
            user=self.other_user,
            duration_mins=15,
        )

        with self.assertRaises(PermissionError):
            BookingService.create_booking_from_holds(
                user=self.user, # different user
                hold_ids=[str(hold_room.id)],
                primary_guest_name="Traveler C",
                primary_guest_phone="+91 98470 55555",
                primary_guest_email="traveler_c@keralink.travel",
                idempotency_key="bkg_integ_fail_auth",
            )

    def test_payment_verification_consumes_inventory_holds(self):
        # Create hold & booking
        hold_room = InventoryService.create_hold(
            inventory_type='ROOM',
            inventory_id=str(self.room_inv.id),
            quantity=2,
            user=self.user,
            duration_mins=15,
        )
        booking = BookingService.create_booking_from_holds(
            user=self.user,
            hold_ids=[str(hold_room.id)],
            primary_guest_name="Traveler C",
            primary_guest_phone="+91 98470 55555",
            primary_guest_email="traveler_c@keralink.travel",
            idempotency_key="bkg_integ_consume_test",
        )

        payment_service = IdempotentPaymentService(gateway_adapter=PaymentSimulator())

        # Step 1: Create payment order
        order_res = payment_service.create_order(
            booking=booking,
            user=self.user,
            idempotency_key="pay_integ_order_1",
        )
        self.assertIn("gateway_order_id", order_res)
        booking.refresh_from_db()
        self.assertEqual(booking.status, 'PAYMENT_PROCESSING')

        # Prior to verification: held_rooms=2, booked_rooms=0
        self.room_inv.refresh_from_db()
        self.assertEqual(self.room_inv.held_rooms, 2)
        self.assertEqual(self.room_inv.booked_rooms, 0)

        # Step 2: Authoritative verification
        verify_res = payment_service.verify_and_confirm_payment(
            booking_id=booking.id,
            gateway_order_id=order_res["gateway_order_id"],
            gateway_payment_id="pay_sim_12345",
            gateway_signature="sig_sim_valid",
            user=self.user,
        )

        self.assertEqual(verify_res["status"], "confirmed")
        self.assertIsNotNone(verify_res["digital_pass_token"])

        # Invariant verified: Hold is CONFIRMED, capacity transferred: held -> booked!
        self.room_inv.refresh_from_db()
        self.assertEqual(self.room_inv.held_rooms, 0) # held decremented
        self.assertEqual(self.room_inv.booked_rooms, 2) # booked incremented

        hold_room.refresh_from_db()
        self.assertEqual(hold_room.status, 'CONFIRMED')

        booking.refresh_from_db()
        self.assertEqual(booking.status, 'CONFIRMED')
        self.assertIsNotNone(booking.confirmed_at)
        self.assertIsNotNone(booking.digital_pass_token)
