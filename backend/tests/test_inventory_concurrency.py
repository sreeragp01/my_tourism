import uuid
import threading
from datetime import date, timedelta
from decimal import Decimal
from django.test import TestCase, TransactionTestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status

from apps.inventory.models import InventoryHold
from apps.inventory.services import (
    InventoryService,
    InsufficientInventoryError,
    HoldExpiredError,
)
from apps.accommodations.models import Accommodation, RoomType, RoomInventory
from apps.experiences.models import Experience, ExperienceSlot

User = get_user_model()


class InventoryAPITestCase(TestCase):
    """
    Functional and REST API Test Suite for Phase 6 — Inventory & Holds:
      - GET /api/v1/inventory/availability/
      - POST /api/v1/inventory/holds/
      - GET /api/v1/inventory/holds/{id}/
      - POST /api/v1/inventory/holds/{id}/release/
      - POST /api/v1/inventory/holds/{id}/extend/
      - POST /api/v1/inventory/holds/itinerary/
      - User Isolation (HTTP 403)
      - Expired Hold Rejection
      - Insufficient Inventory (HTTP 409)
    """

    def setUp(self):
        self.client = APIClient()
        self.user_a = User.objects.create_user(email='traveler_a@keralink.com', password='password123')
        self.user_b = User.objects.create_user(email='traveler_b@keralink.com', password='password123')

        org_id = uuid.uuid4()
        self.accommodation = Accommodation.objects.create(
            id='acc_spicetree',
            org_id=org_id,
            destination_id='munnar',
            name='Spice Tree Luxury Resort',
            type='BOUTIQUE_RESORT',
            tagline='Chalet in the Western Ghats',
            description='Luxury eco chalet.',
            hero_image='https://images.unsplash.com/resort',
            star_rating=5,
            base_price_per_night=Decimal('6500.00'),
        )
        self.room_type = RoomType.objects.create(
            id='room_deluxe_chalet',
            accommodation=self.accommodation,
            name='Deluxe Valley Chalet',
            price_per_night=Decimal('6500.00'),
            capacity=2,
        )
        self.target_date = date(2026, 10, 15)
        self.room_inventory = RoomInventory.objects.create(
            room_type=self.room_type,
            date=self.target_date,
            total_rooms=5,
            booked_rooms=1,
            held_rooms=0,
        )

        self.experience = Experience.objects.create(
            id='exp_tea_masterclass',
            org_id=org_id,
            destination_id='munnar',
            title='Highland Tea Tasting Masterclass',
            category='CULTURE',
            description='Artisan orthodox tea processing.',
            price_per_person=Decimal('1200.00'),
            duration_hours=2.5,
            max_group_size=10,
            hero_image='https://images.unsplash.com/tea',
            meeting_point='Lockhart Tea Museum',
            host_name='Arun Kumar',
            host_role='Master Tea Taster',
        )
        self.experience_slot = ExperienceSlot.objects.create(
            experience=self.experience,
            date=self.target_date,
            start_time='09:00',
            end_time='11:30',
            total_capacity=10,
            booked_capacity=2,
            held_capacity=0,
        )

    def test_check_availability_api(self):
        """GET /api/v1/inventory/availability/ returns authoritative database availability."""
        # Check Room Availability
        res_room = self.client.get(
            '/api/v1/inventory/availability/',
            {'inventory_type': 'ROOM', 'inventory_id': self.room_type.id, 'date': str(self.target_date)},
        )
        self.assertEqual(res_room.status_code, status.HTTP_200_OK)
        self.assertEqual(res_room.data['total_capacity'], 5)
        self.assertEqual(res_room.data['booked_capacity'], 1)
        self.assertEqual(res_room.data['held_capacity'], 0)
        self.assertEqual(res_room.data['available_capacity'], 4)
        self.assertTrue(res_room.data['is_available'])

        # Check Experience Slot Availability
        res_exp = self.client.get(
            '/api/v1/inventory/availability/',
            {'inventory_type': 'EXPERIENCE', 'inventory_id': str(self.experience_slot.id)},
        )
        self.assertEqual(res_exp.status_code, status.HTTP_200_OK)
        self.assertEqual(res_exp.data['available_capacity'], 8)
        self.assertTrue(res_exp.data['is_available'])

    def test_create_hold_api(self):
        """POST /api/v1/inventory/holds/ creates atomic 15-minute hold and updates capacity."""
        self.client.force_authenticate(user=self.user_a)

        payload = {
            'inventory_type': 'ROOM',
            'inventory_id': self.room_type.id,
            'date': str(self.target_date),
            'quantity': 2,
            'itinerary_version_id': 'v1-uuid',
            'duration_mins': 15,
        }
        res = self.client.post('/api/v1/inventory/holds/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['status'], 'ACTIVE')
        self.assertEqual(res.data['quantity'], 2)
        self.assertGreater(res.data['remaining_seconds'], 800)
        self.assertTrue(res.data['is_valid'])

        # Verify DB capacity
        self.room_inventory.refresh_from_db()
        self.assertEqual(self.room_inventory.held_rooms, 2)
        self.assertEqual(self.room_inventory.available_rooms, 2)

    def test_insufficient_inventory_returns_409(self):
        """Attempting to hold more than available capacity returns HTTP 409 INSUFFICIENT_INVENTORY."""
        self.client.force_authenticate(user=self.user_a)

        payload = {
            'inventory_type': 'ROOM',
            'inventory_id': self.room_type.id,
            'date': str(self.target_date),
            'quantity': 10,  # Only 4 available
        }
        res = self.client.post('/api/v1/inventory/holds/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_409_CONFLICT)
        self.assertEqual(res.data['code'], 'INSUFFICIENT_INVENTORY')

        # Verify capacity untouched
        self.room_inventory.refresh_from_db()
        self.assertEqual(self.room_inventory.held_rooms, 0)

    def test_user_isolation_and_hold_detail(self):
        """User A can read own hold; User B cannot read or release User A's hold (HTTP 403)."""
        hold = InventoryService.create_hold(
            user=self.user_a,
            inventory_type='ROOM',
            inventory_id=self.room_type.id,
            date=self.target_date,
            quantity=1,
        )

        # User A reads hold -> 200 OK
        self.client.force_authenticate(user=self.user_a)
        res_a = self.client.get(f'/api/v1/inventory/holds/{hold.id}/')
        self.assertEqual(res_a.status_code, status.HTTP_200_OK)
        self.assertEqual(res_a.data['id'], str(hold.id))

        # User B attempts to read hold -> 403 Forbidden
        self.client.force_authenticate(user=self.user_b)
        res_b = self.client.get(f'/api/v1/inventory/holds/{hold.id}/')
        self.assertEqual(res_b.status_code, status.HTTP_403_FORBIDDEN)

        # User B attempts to release User A's hold -> 403 Forbidden
        res_rel_b = self.client.post(f'/api/v1/inventory/holds/{hold.id}/release/')
        self.assertEqual(res_rel_b.status_code, status.HTTP_403_FORBIDDEN)

    def test_release_hold_restores_capacity(self):
        """POST /api/v1/inventory/holds/{id}/release/ releases hold and restores capacity immediately."""
        hold = InventoryService.create_hold(
            user=self.user_a,
            inventory_type='ROOM',
            inventory_id=self.room_type.id,
            date=self.target_date,
            quantity=2,
        )
        self.room_inventory.refresh_from_db()
        self.assertEqual(self.room_inventory.held_rooms, 2)

        self.client.force_authenticate(user=self.user_a)
        res = self.client.post(f'/api/v1/inventory/holds/{hold.id}/release/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['status'], 'RELEASED')

        self.room_inventory.refresh_from_db()
        self.assertEqual(self.room_inventory.held_rooms, 0)
        self.assertEqual(self.room_inventory.available_rooms, 4)

    def test_extend_hold_and_expired_rejection(self):
        """POST /api/v1/inventory/holds/{id}/extend/ extends hold window; expired holds are rejected."""
        hold = InventoryService.create_hold(
            user=self.user_a,
            inventory_type='EXPERIENCE',
            inventory_id=str(self.experience_slot.id),
            quantity=2,
            duration_mins=15,
        )
        old_expiry = hold.expires_at

        self.client.force_authenticate(user=self.user_a)
        res = self.client.post(f'/api/v1/inventory/holds/{hold.id}/extend/', {'extra_minutes': 10}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        hold.refresh_from_db()
        self.assertGreater(hold.expires_at, old_expiry)

        # Manually expire hold
        hold.expires_at = timezone.now() - timedelta(minutes=5)
        hold.save()

        # Attempting to extend expired hold -> 410 GONE
        res_expired = self.client.post(f'/api/v1/inventory/holds/{hold.id}/extend/', {'extra_minutes': 10}, format='json')
        self.assertEqual(res_expired.status_code, status.HTTP_410_GONE)

    def test_itinerary_batch_hold_success_and_rollback(self):
        """Batch hold of all components in an itinerary succeeds, or rolls back entirely if 1 fails."""
        self.client.force_authenticate(user=self.user_a)

        # Successful batch hold
        payload_ok = {
            'itinerary_version_id': 'plan_v1_xyz',
            'items': [
                {'inventory_type': 'ROOM', 'inventory_id': self.room_type.id, 'date': str(self.target_date), 'quantity': 1},
                {'inventory_type': 'EXPERIENCE', 'inventory_id': str(self.experience_slot.id), 'quantity': 2},
            ],
        }
        res_ok = self.client.post('/api/v1/inventory/holds/itinerary/', payload_ok, format='json')
        self.assertEqual(res_ok.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res_ok.data['total_held'], 2)
        self.assertEqual(res_ok.data['status'], 'ALL_HELD')

        # Failed batch hold with rollback: request 20 seats (only 6 left now)
        payload_fail = {
            'itinerary_version_id': 'plan_v1_xyz',
            'items': [
                {'inventory_type': 'ROOM', 'inventory_id': self.room_type.id, 'date': str(self.target_date), 'quantity': 1},
                {'inventory_type': 'EXPERIENCE', 'inventory_id': str(self.experience_slot.id), 'quantity': 20},
            ],
        }
        res_fail = self.client.post('/api/v1/inventory/holds/itinerary/', payload_fail, format='json')
        self.assertEqual(res_fail.status_code, status.HTTP_409_CONFLICT)
        self.assertEqual(res_fail.data['status'], 'HOLD_FAILED_ROLLED_BACK')


class InventoryConcurrencyTestCase(TransactionTestCase):
    """
    PostgreSQL Row-Level Concurrency & Invariant Test Suite:
      - 10 simultaneous requests competing for capacity = 5
      - Invariant: booked + held <= total at all times
      - Available capacity never negative
      - Two users competing for the final unit (1 succeeds, 1 rejected)
      - Multiple experiences simultaneous holds
      - Automatic release of expired holds restoring capacity
    """

    def setUp(self):
        org_id = uuid.uuid4()
        self.accommodation = Accommodation.objects.create(
            id='acc_concurrency',
            org_id=org_id,
            destination_id='munnar',
            name='Hilltop Tea Chalet',
            type='BOUTIQUE_RESORT',
            tagline='Chalet in hills',
            description='Test resort.',
            hero_image='https://images.unsplash.com/resort',
            star_rating=5,
            base_price_per_night=Decimal('5000.00'),
        )
        self.room_type = RoomType.objects.create(
            id='room_type_concurrency',
            accommodation=self.accommodation,
            name='Cottage Suite',
            price_per_night=Decimal('5000.00'),
            capacity=2,
        )
        self.target_date = date(2026, 11, 1)

    def test_10_simultaneous_requests_for_5_capacity(self):
        """
        Scenario: 10 concurrent users simultaneously attempt to hold 1 unit each from a pool of 5 rooms.
        Invariant: Exactly 5 succeed, exactly 5 fail with InsufficientInventoryError.
        Final: booked + held == 5, available == 0, NEVER negative.
        """
        inv = RoomInventory.objects.create(
            room_type=self.room_type,
            date=self.target_date,
            total_rooms=5,
            booked_rooms=0,
            held_rooms=0,
        )

        results = []
        errors = []
        lock = threading.Lock()

        def try_hold(user_idx):
            import time
            from django.db import connection
            from django.db.utils import OperationalError
            for _ in range(100):
                try:
                    hold = InventoryService.create_hold(
                        inventory_type='ROOM',
                        inventory_id=str(inv.id),
                        quantity=1,
                    )
                    with lock:
                        results.append((user_idx, hold.id))
                    connection.close()
                    return
                except InsufficientInventoryError as e:
                    with lock:
                        errors.append((user_idx, str(e)))
                    connection.close()
                    return
                except OperationalError:
                    connection.close()
                    time.sleep(0.02)
                except Exception as ex:
                    connection.close()
                    with lock:
                        errors.append((user_idx, f"Error: {ex}"))
                    return

        threads = [threading.Thread(target=try_hold, args=(i,)) for i in range(10)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        self.assertEqual(len(results), 5, f"Expected exactly 5 successful holds, got {len(results)}. Errors: {errors}")
        self.assertEqual(len(errors), 5, f"Expected exactly 5 rejections, got {len(errors)}")

        inv.refresh_from_db()
        self.assertEqual(inv.held_rooms, 5)
        self.assertEqual(inv.available_rooms, 0)
        self.assertLessEqual(inv.booked_rooms + inv.held_rooms, inv.total_rooms)

    def test_two_users_final_unit_race(self):
        """
        Scenario: 1 unit remains. Two users attempt to hold simultaneously.
        Result: Exactly 1 succeeds, exactly 1 fails.
        """
        inv = RoomInventory.objects.create(
            room_type=self.room_type,
            date=date(2026, 11, 2),
            total_rooms=1,
            booked_rooms=0,
            held_rooms=0,
        )

        successes = []
        failures = []
        lock = threading.Lock()

        def acquire(user_name):
            import time
            from django.db import connection
            from django.db.utils import OperationalError
            for _ in range(100):
                try:
                    h = InventoryService.create_hold(
                        inventory_type='ROOM',
                        inventory_id=str(inv.id),
                        quantity=1,
                    )
                    with lock:
                        successes.append(user_name)
                    connection.close()
                    return
                except InsufficientInventoryError:
                    with lock:
                        failures.append(user_name)
                    connection.close()
                    return
                except OperationalError:
                    connection.close()
                    time.sleep(0.02)
                except Exception as ex:
                    connection.close()
                    with lock:
                        failures.append(f"Error: {ex}")
                    return

        t1 = threading.Thread(target=acquire, args=('User_1',))
        t2 = threading.Thread(target=acquire, args=('User_2',))
        t1.start()
        t2.start()
        t1.join()
        t2.join()

        self.assertEqual(len(successes), 1, f"Expected 1 success, got {len(successes)}")
        self.assertEqual(len(failures), 1, f"Expected 1 failure, got {len(failures)}")

        inv.refresh_from_db()
        self.assertEqual(inv.held_rooms, 1)
        self.assertEqual(inv.available_rooms, 0)

    def test_hold_expiration_and_capacity_release(self):
        """
        Expired holds release their capacity when swept or accessed.
        """
        inv = RoomInventory.objects.create(
            room_type=self.room_type,
            date=date(2026, 11, 3),
            total_rooms=2,
            booked_rooms=0,
            held_rooms=0,
        )

        # Create hold that is immediately expired
        hold = InventoryService.create_hold(
            inventory_type='ROOM',
            inventory_id=str(inv.id),
            quantity=2,
            duration_mins=0,
        )
        inv.refresh_from_db()
        self.assertEqual(inv.available_rooms, 0)

        # Set expiry in the past
        hold.expires_at = timezone.now() - timedelta(seconds=1)
        hold.save()

        # Release expired holds
        released_count = InventoryService.release_expired_holds()
        self.assertEqual(released_count, 1)

        inv.refresh_from_db()
        self.assertEqual(inv.held_rooms, 0)
        self.assertEqual(inv.available_rooms, 2)

    def test_confirm_hold_transitions_to_booked(self):
        """
        Confirming a hold converts 'held' capacity to 'booked' capacity atomically.
        """
        inv = RoomInventory.objects.create(
            room_type=self.room_type,
            date=date(2026, 11, 4),
            total_rooms=5,
            booked_rooms=0,
            held_rooms=0,
        )
        hold = InventoryService.create_hold(
            inventory_type='ROOM',
            inventory_id=str(inv.id),
            quantity=2,
        )

        booking_uuid = uuid.uuid4()
        confirmed = InventoryService.confirm_hold(hold.id, booking_id=booking_uuid)
        self.assertEqual(confirmed.status, 'CONFIRMED')
        self.assertEqual(confirmed.booking_id, booking_uuid)

        inv.refresh_from_db()
        self.assertEqual(inv.held_rooms, 0)
        self.assertEqual(inv.booked_rooms, 2)
        self.assertEqual(inv.available_rooms, 3)
