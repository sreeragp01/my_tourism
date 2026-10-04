import uuid
from decimal import Decimal
from django.test import TestCase, override_settings
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.core.management.base import CommandError
from rest_framework.test import APIClient
from rest_framework import status

from apps.accounts.models import (
    UserProfile, UserSession, RefreshTokenFamily, RefreshToken,
    EmailVerificationOTP, PasswordResetOTP
)
from apps.bookings.models import Booking
from apps.payments.models import Payment
from apps.audit.models import AuditLog
from apps.safety.models import TripShareToken
from apps.payments.apps import check_production_payment_configuration

User = get_user_model()

class AuditHardeningTestCase(TestCase):
    """
    Test suite verifying the security and compliance hardening:
      1. Account erasure / DPDP right-to-be-forgotten scrubbing
      2. Data export completeness & PII boundary enforcement
      3. payments.E001 startup check logic
      4. Seed command production execution guards
      5. Fresh user profile blank defaults
    """

    def setUp(self):
        self.client = APIClient()
        self.password = "StrongPassword@2026!"
        self.user = User.objects.create_user(
            email="traveler.verify@keralink.travel",
            password=self.password,
            first_name="Verified",
            last_name="Traveler",
            phone="+91 99999 88888",
        )
        self.profile, _ = UserProfile.objects.get_or_create(user=self.user)
        self.profile.emergency_contact_name = "Family Contact"
        self.profile.emergency_contact_phone = "+91 99999 77777"
        self.profile.emergency_contact_email = "ice@example.com"
        self.profile.blood_group = "B+ Positive"
        self.profile.medical_notes = "Peanut allergy"
        self.profile.dietary_preference = "Non-Vegetarian"
        self.profile.eco_score = 45
        self.profile.save()

        # Authenticate client
        self.client.force_authenticate(user=self.user)

    def test_account_deletion_scrubbing(self):
        """
        DPDP Erasure: Verifies that account deletion thoroughly scrubs user,
        profile, bookings, sessions, tokens, OTPs, and revokes trip shares.
        """
        # 1. Create a linked booking
        booking = Booking.objects.create(
            booking_reference="KL-DEL-TEST-001",
            user=self.user,
            trip_title="Munnar Test Trip",
            start_date=timezone.now().date(),
            end_date=timezone.now().date(),
            travelers_count=2,
            primary_guest_name="Verified Traveler",
            primary_guest_phone="+91 99999 88888",
            primary_guest_email=self.user.email,
            total_amount=Decimal("15000.00"),
            idempotency_key="idemp-del-test-01",
        )

        # 2. Create session and refresh token
        session = UserSession.objects.create(
            user=self.user,
            device_id="test_dev_01",
            device_name="iPhone 15 Pro",
            platform="IOS",
            ip_address="203.0.113.195",
            user_agent="Mozilla/5.0 Test Browser",
            expires_at=timezone.now() + timezone.timedelta(days=7),
        )
        family = RefreshTokenFamily.objects.create(session=session)
        token_record = RefreshToken.objects.create(
            family=family,
            token_hash="fake_hash",
            expires_at=timezone.now() + timezone.timedelta(days=7),
        )

        # 3. Create pending OTPs
        EmailVerificationOTP.generate_otp_for_user(self.user)
        PasswordResetOTP.generate_otp_for_user(self.user)

        # 4. Create an active trip share token
        trip_share = TripShareToken.objects.create(
            booking=booking,
            user=self.user,
            expires_at=timezone.now() + timezone.timedelta(days=1),
            is_revoked=False,
        )

        # Execute account deletion
        res = self.client.post('/api/v1/auth/delete-account/', {'password': self.password})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data['success'])

        # Refresh objects
        self.user.refresh_from_db()
        self.profile.refresh_from_db()
        booking.refresh_from_db()
        session.refresh_from_db()
        family.refresh_from_db()
        token_record.refresh_from_db()
        trip_share.refresh_from_db()

        # Assert User scrubbed
        self.assertFalse(self.user.is_active)
        self.assertFalse(self.user.has_usable_password())
        self.assertEqual(self.user.first_name, 'Deleted')
        self.assertEqual(self.user.last_name, 'User')
        self.assertEqual(self.user.phone, '')
        self.assertTrue(self.user.email.startswith('deleted_'))

        # Assert Profile scrubbed
        self.assertEqual(self.profile.emergency_contact_name, '')
        self.assertEqual(self.profile.emergency_contact_phone, '')
        self.assertEqual(self.profile.medical_notes, '')
        self.assertFalse(self.profile.data_processing_consented)
        self.assertIsNotNone(self.profile.consent_withdrawn_at)

        # Assert Booking guest scrubbed while statutory tax retention deadline is set
        self.assertEqual(booking.primary_guest_name, 'Deleted Traveler')
        self.assertEqual(booking.primary_guest_phone, '')
        self.assertTrue(booking.primary_guest_email.startswith('deleted_'))
        self.assertIsNotNone(booking.anonymized_at)
        self.assertIsNotNone(booking.retention_until)
        self.assertGreater(booking.retention_until, timezone.now())

        # Assert financial ledger fields remain strictly unaltered for tax compliance
        self.assertEqual(booking.total_amount, Decimal("15000.00"))
        self.assertEqual(booking.booking_reference, "KL-DEL-TEST-001")
        self.assertEqual(booking.currency, "INR")

        # Assert Session & Tokens revoked and scrubbed
        self.assertEqual(session.ip_address, '0.0.0.0')
        self.assertEqual(session.device_name, 'Redacted Device')
        self.assertIsNotNone(session.revoked_at)
        self.assertFalse(family.is_valid)
        self.assertIsNotNone(token_record.revoked_at)

        # Assert OTPs purged
        self.assertEqual(EmailVerificationOTP.objects.filter(user=self.user).count(), 0)
        self.assertEqual(PasswordResetOTP.objects.filter(user=self.user).count(), 0)

        # Assert Trip Share revoked
        self.assertTrue(trip_share.is_revoked)

    def test_data_export_completeness_and_privacy(self):
        """
        DPDP Data Portability: Verifies export payload includes identity, bookings,
        payments, and activity logs without exposing password hashes or tokens.
        """
        # Create booking and payment
        booking = Booking.objects.create(
            booking_reference="KL-EXP-TEST-002",
            user=self.user,
            trip_title="Wayanad Trek",
            start_date=timezone.now().date(),
            end_date=timezone.now().date(),
            total_amount=Decimal("8000.00"),
            idempotency_key="idemp-exp-01",
        )
        Payment.objects.create(
            booking=booking,
            amount=Decimal("8000.00"),
            currency="INR",
            status="SUCCESS",
            gateway="RAZORPAY",
            gateway_payment_id="pay_test_12345",
            idempotency_key="idemp-pay-exp-01",
        )
        AuditLog.objects.create(
            actor=self.user,
            actor_role="CUSTOMER",
            action="PROFILE_UPDATED",
            resource_type="USER_PROFILE",
            resource_id=str(self.user.id),
        )

        res = self.client.get('/api/v1/auth/export-data/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.data['data']

        # Check required categories exist
        self.assertIn('user_identity', data)
        self.assertIn('profile_and_preferences', data)
        self.assertIn('sessions', data)
        self.assertIn('bookings', data)
        self.assertIn('payments', data)
        self.assertIn('activity_logs', data)

        # Check payment details
        self.assertEqual(len(data['payments']), 1)
        self.assertEqual(data['payments'][0]['booking_reference'], "KL-EXP-TEST-002")
        self.assertEqual(data['payments'][0]['amount'], 8000.0)

        # Check audit activity logs
        self.assertEqual(len(data['activity_logs']), 1)
        self.assertEqual(data['activity_logs'][0]['action'], "PROFILE_UPDATED")

        # Verify NO secret credentials exposed
        raw_text = str(data)
        self.assertNotIn('password', raw_text.lower())
        self.assertNotIn('pbkdf2', raw_text.lower())
        self.assertNotIn('signing_key', raw_text.lower())

    def test_payment_security_check_e001(self):
        """
        Verifies system check E001 fires when payments are enabled in production
        without valid Razorpay keys, and passes when simulator is allowed.
        """
        # Case 1: PAYMENTS_ENABLED=True, ALLOW_PAYMENT_SIMULATOR=False, no keys -> Error
        with override_settings(PAYMENTS_ENABLED=True, ALLOW_PAYMENT_SIMULATOR=False, RAZORPAY_KEY_ID="", RAZORPAY_KEY_SECRET=""):
            errors = check_production_payment_configuration(None)
            self.assertEqual(len(errors), 1)
            self.assertEqual(errors[0].id, 'payments.E001')

        # Case 2: PAYMENTS_ENABLED=True, ALLOW_PAYMENT_SIMULATOR=False, placeholder keys -> Error
        with override_settings(PAYMENTS_ENABLED=True, ALLOW_PAYMENT_SIMULATOR=False, RAZORPAY_KEY_ID="rzp_test_placeholder_key_id", RAZORPAY_KEY_SECRET="rzp_test_placeholder_key_secret"):
            errors = check_production_payment_configuration(None)
            self.assertEqual(len(errors), 1)
            self.assertEqual(errors[0].id, 'payments.E001')

        # Case 3: PAYMENTS_ENABLED=True, ALLOW_PAYMENT_SIMULATOR=True -> Allowed (dev/testing)
        with override_settings(PAYMENTS_ENABLED=True, ALLOW_PAYMENT_SIMULATOR=True, RAZORPAY_KEY_ID="", RAZORPAY_KEY_SECRET=""):
            errors = check_production_payment_configuration(None)
            self.assertEqual(len(errors), 0)

        # Case 4: PAYMENTS_ENABLED=False -> Clean
        with override_settings(PAYMENTS_ENABLED=False, ALLOW_PAYMENT_SIMULATOR=False):
            errors = check_production_payment_configuration(None)
            self.assertEqual(len(errors), 0)

    def test_seed_commands_production_guard(self):
        """
        Verifies that running seed management commands with DEBUG=False raises CommandError.
        """
        with override_settings(DEBUG=False):
            with self.assertRaises(CommandError) as ctx1:
                call_command('seed_packages')
            self.assertIn("disabled in production", str(ctx1.exception))

            with self.assertRaises(CommandError) as ctx2:
                call_command('seed_tourism_data')
            self.assertIn("disabled in production", str(ctx2.exception))

    def test_new_user_clean_defaults(self):
        """
        Verifies that a brand new user profile is created with clean blank defaults
        instead of any hardcoded mock defaults.
        """
        new_user = User.objects.create_user(
            email="clean.traveler@example.com",
            password="StrongPassword@123",
            first_name="Clean",
            last_name="Traveler",
        )
        new_profile, _ = UserProfile.objects.get_or_create(user=new_user)
        self.assertEqual(new_profile.emergency_contact_name, '')
        self.assertEqual(new_profile.emergency_contact_phone, '')
        self.assertEqual(new_profile.medical_notes, '')
        self.assertEqual(new_profile.eco_score, 0)
        self.assertEqual(new_profile.eco_tier, 'Seedling Traveler')
        self.assertEqual(new_profile.trips_completed, 0)

    def test_purge_expired_retention_data_command(self):
        """
        Verifies that purge_expired_retention_data wipes residual metadata & tokens
        from expired retention bookings while leaving active/unexpired bookings intact,
        and preserving financial amounts permanently.
        """
        now = timezone.now()
        # 1. Unexpired booking (retention_until in future)
        unexpired_b = Booking.objects.create(
            booking_reference="KL-RET-ACTIVE-01",
            user=self.user,
            trip_title="Kovalam Beach Getaway",
            start_date=now.date(),
            end_date=now.date(),
            total_amount=Decimal("12000.00"),
            idempotency_key="idemp-ret-act-01",
            digital_pass_token="pass-tok-active",
            qr_code_url="https://keralink.travel/qr/active",
            retention_until=now + timezone.timedelta(days=365),
        )

        # 2. Expired booking (retention_until in past)
        expired_b = Booking.objects.create(
            booking_reference="KL-RET-EXPIRED-02",
            user=self.user,
            trip_title="Old Periyar Safari",
            start_date=now.date(),
            end_date=now.date(),
            total_amount=Decimal("9500.00"),
            idempotency_key="idemp-ret-exp-02",
            digital_pass_token="pass-tok-expired",
            qr_code_url="https://keralink.travel/qr/expired",
            retention_until=now - timezone.timedelta(days=1),
        )

        # Dry run test: counts records without modifying
        call_command('purge_expired_retention_data', '--dry-run')
        expired_b.refresh_from_db()
        self.assertIsNotNone(expired_b.digital_pass_token)

        # Actual purge run
        call_command('purge_expired_retention_data')

        unexpired_b.refresh_from_db()
        expired_b.refresh_from_db()

        # Unexpired booking must remain completely intact
        self.assertEqual(unexpired_b.digital_pass_token, "pass-tok-active")
        self.assertEqual(unexpired_b.trip_title, "Kovalam Beach Getaway")

        # Expired booking must have tokens & QR wiped
        self.assertIsNone(expired_b.digital_pass_token)
        self.assertIsNone(expired_b.qr_code_url)
        self.assertEqual(expired_b.trip_title, "Archived Expired Booking")

        # Financial values must remain strictly unchanged for permanent ledger
        self.assertEqual(expired_b.total_amount, Decimal("9500.00"))
        self.assertEqual(expired_b.booking_reference, "KL-RET-EXPIRED-02")

        # AuditLog entry must have been created
        log_entry = AuditLog.objects.filter(
            action="STATUTORY_RETENTION_EXPIRED_PURGE",
            resource_id=str(expired_b.id),
        ).first()
        self.assertIsNotNone(log_entry)
        self.assertEqual(log_entry.actor_role, "SYSTEM_CRON")

