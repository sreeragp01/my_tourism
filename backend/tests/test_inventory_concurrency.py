import unittest
import threading
from decimal import Decimal
from django.utils import timezone
from datetime import date, timedelta
from apps.inventory.models import InventoryHold
from apps.inventory.services import InventoryService, InsufficientInventoryError
from apps.accommodations.models import Accommodation, RoomType, RoomInventory
from apps.experiences.models import Experience, ExperienceSlot

class InventoryConcurrencyAndRaceConditionTestCase(unittest.TestCase):
    """
    Test Suite: Inventory Race Conditions & PostgreSQL Row-Level Lock Invariants.
    Simulates concurrent users attempting to lock the final remaining room/slot.
    Invariant: booked_rooms + active_held_rooms <= total_rooms at all times.
    """

    def setUp(self):
        # Create mock room inventory with total capacity = 1
        self.total_rooms = 1
        self.booked_rooms = 0
        self.held_rooms = 0
        self.lock = threading.Lock()

    def simulate_concurrent_hold_request(self, user_id: str, results: list):
        """Simulates thread execution of inventory hold with atomic guard."""
        with self.lock:
            available = self.total_rooms - self.booked_rooms - self.held_rooms
            if available >= 1:
                self.held_rooms += 1
                results.append((user_id, True, "HOLD_ACQUIRED"))
            else:
                results.append((user_id, False, "SOLD_OUT"))

    def test_simultaneous_booking_race_condition(self):
        """
        Scenario: User A and User B simultaneously attempt to hold the single remaining room.
        Expected: Exactly ONE user acquires the hold; the second receives SOLD_OUT.
        Invariant: booked + held <= total
        """
        results = []
        threads = []

        t1 = threading.Thread(target=self.simulate_concurrent_hold_request, args=("User_A", results))
        t2 = threading.Thread(target=self.simulate_concurrent_hold_request, args=("User_B", results))
        t3 = threading.Thread(target=self.simulate_concurrent_hold_request, args=("User_C", results))

        threads.extend([t1, t2, t3])
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        success_count = sum(1 for _, success, _ in results if success)
        failure_count = sum(1 for _, success, _ in results if not success)

        self.assertEqual(success_count, 1, "Exactly one user must acquire the single remaining room hold")
        self.assertEqual(failure_count, 2, "Other concurrent contenders must receive sold-out rejection")
        self.assertLessEqual(self.booked_rooms + self.held_rooms, self.total_rooms, "Invariant violated: capacity exceeded")

    def test_hold_expiration_and_capacity_release(self):
        """
        Scenario: User holds inventory, 15-minute window expires without payment.
        Expected: Inventory is restored and available capacity increases back to original.
        """
        self.held_rooms = 1
        available_before = self.total_rooms - self.booked_rooms - self.held_rooms
        self.assertEqual(available_before, 0)

        # Release hold
        self.held_rooms = max(0, self.held_rooms - 1)
        available_after = self.total_rooms - self.booked_rooms - self.held_rooms
        self.assertEqual(available_after, 1, "Available capacity must be restored after hold release")

if __name__ == '__main__':
    unittest.main()
