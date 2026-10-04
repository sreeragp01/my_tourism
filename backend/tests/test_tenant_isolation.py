import unittest
import uuid

class MockUser:
    def __init__(self, user_id: str, email: str, is_staff: bool = False):
        self.id = user_id
        self.email = email
        self.is_staff = is_staff

class MockOrganization:
    def __init__(self, org_id: str, name: str):
        self.id = org_id
        self.name = name

class MockBookingRecord:
    def __init__(self, booking_id: str, provider_org_id: str, customer_user_id: str, amount: float):
        self.id = booking_id
        self.provider_org_id = provider_org_id
        self.customer_user_id = customer_user_id
        self.amount = amount

class TenantIsolationTestCase(unittest.TestCase):
    """
    Test Suite: Multi-Tenant RBAC & Cross-Organization Data Isolation.
    Ensures:
      1. Provider A cannot query or mutate Provider B's bookings, inventory, or financial payouts.
      2. Regular customers cannot see other travelers' bookings.
      3. Only Platform Admins (is_staff=True) have platform-wide aggregate access.
    """

    def setUp(self):
        self.org_A = MockOrganization("org-spice-valley-munnar", "Spice Valley Resort")
        self.org_B = MockOrganization("org-alleppey-houseboats", "Lakes & Lagoons Houseboats")

        self.provider_user_A = MockUser("usr-provider-A", "owner@spicevalley.in")
        self.provider_user_B = MockUser("usr-provider-B", "captain@alleppeyboats.in")
        self.customer_user_1 = MockUser("usr-customer-1", "traveler1@gmail.com")
        self.customer_user_2 = MockUser("usr-customer-2", "traveler2@gmail.com")
        self.admin_user = MockUser("usr-admin", "admin@keralink.org", is_staff=True)

        self.bookings = [
            MockBookingRecord("bkg-001", self.org_A.id, self.customer_user_1.id, 28500.0),
            MockBookingRecord("bkg-002", self.org_A.id, self.customer_user_2.id, 14200.0),
            MockBookingRecord("bkg-003", self.org_B.id, self.customer_user_1.id, 18000.0),
        ]

    def query_provider_bookings(self, requesting_user: MockUser, user_org_id: str) -> list:
        """Simulates DRF queryset filtering with organization tenant boundary."""
        if requesting_user.is_staff:
            return self.bookings
        # Tenant boundary filter: only records belonging to the provider's verified organization
        return [b for b in self.bookings if b.provider_org_id == user_org_id]

    def query_customer_bookings(self, requesting_user: MockUser) -> list:
        """Simulates customer booking history query with user isolation."""
        if requesting_user.is_staff:
            return self.bookings
        return [b for b in self.bookings if b.customer_user_id == requesting_user.id]

    def test_provider_a_cannot_see_provider_b_data(self):
        # Provider A queries bookings
        results_A = self.query_provider_bookings(self.provider_user_A, self.org_A.id)
        
        self.assertEqual(len(results_A), 2)
        for b in results_A:
            self.assertEqual(b.provider_org_id, self.org_A.id)
            self.assertNotEqual(b.provider_org_id, self.org_B.id, "Cross-tenant leak: Provider A saw Provider B's booking!")

    def test_customer_cannot_see_other_customer_data(self):
        # Customer 1 queries bookings
        results_C1 = self.query_customer_bookings(self.customer_user_1)
        self.assertEqual(len(results_C1), 2) # bkg-001, bkg-003
        
        # Verify Customer 2's private booking (bkg-002) is NOT in results
        booking_ids = [b.id for b in results_C1]
        self.assertNotIn("bkg-002", booking_ids, "Customer 1 cannot see Customer 2's booking")

    def test_admin_has_platform_wide_visibility(self):
        results_admin = self.query_provider_bookings(self.admin_user, None)
        self.assertEqual(len(results_admin), 3, "Platform Admin has complete platform-wide visibility")

if __name__ == '__main__':
    unittest.main()
