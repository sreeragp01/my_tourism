import uuid
from datetime import timedelta
from unittest.mock import patch
from django.test import TestCase, override_settings
from django.utils import timezone
from django.core import mail
from django.contrib.auth import get_user_model

from apps.events.models import OutboxEvent, ProcessedEvent
from apps.events.dispatcher import EventDispatcher
from apps.safety.services import SafetyService
from apps.accounts.models import UserProfile

User = get_user_model()


@override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
class OutboxEventDispatcherTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='kavya.wayanad@example.com',
            password='SecurePassword123!',
            first_name='Kavya',
            last_name='Nair',
            phone='+91 98460 11223'
        )
        # Update user profile with emergency and medical details
        profile, _ = UserProfile.objects.get_or_create(user=self.user)
        profile.emergency_contact_name = 'Arun Nair'
        profile.emergency_contact_phone = '+91 94470 99887'
        profile.emergency_contact_email = 'arun.emergency@example.com'
        profile.blood_group = 'O+'
        profile.medical_conditions = 'Mild asthma'
        profile.allergies = 'Penicillin'
        profile.emergency_location_sharing_consented = True
        profile.save()

    def test_outbox_event_model_creation(self):
        event = OutboxEvent.objects.create(
            event_type='TestDomainEvent',
            aggregate_type='TestAggregate',
            aggregate_id=str(uuid.uuid4()),
            payload={'message': 'hello outbox'}
        )
        self.assertEqual(event.status, 'PENDING')
        self.assertEqual(event.retry_count, 0)
        self.assertIsNone(event.next_retry_at)
        self.assertIsNone(event.processed_at)

    def test_crash_recovery_resets_stuck_processing_events(self):
        # Create an event stuck in PROCESSING from 10 minutes ago
        past_time = timezone.now() - timedelta(minutes=10)
        stuck_event = OutboxEvent.objects.create(
            event_type='StuckEvent',
            aggregate_type='Order',
            aggregate_id='ord-123',
            payload={},
            status='PROCESSING',
            retry_count=1
        )
        OutboxEvent.objects.filter(id=stuck_event.id).update(created_at=past_time)

        # Run dispatcher
        EventDispatcher.dispatch_pending_events()

        # Should be processed successfully
        stuck_event.refresh_from_db()
        self.assertEqual(stuck_event.status, 'PROCESSED')

    def test_crash_recovery_moves_to_dead_letter_if_max_retries_exceeded(self):
        past_time = timezone.now() - timedelta(minutes=10)
        stuck_exhausted = OutboxEvent.objects.create(
            event_type='ExhaustedEvent',
            aggregate_type='Order',
            aggregate_id='ord-456',
            payload={},
            status='PROCESSING',
            retry_count=5
        )
        OutboxEvent.objects.filter(id=stuck_exhausted.id).update(created_at=past_time)

        EventDispatcher.dispatch_pending_events()

        stuck_exhausted.refresh_from_db()
        self.assertEqual(stuck_exhausted.status, 'DEAD_LETTER')

    def test_event_failure_schedules_exponential_backoff(self):
        failing_event = OutboxEvent.objects.create(
            event_type='FailingEvent',
            aggregate_type='Payment',
            aggregate_id='pay-fail',
            payload={}
        )

        with patch.object(EventDispatcher, '_handle_event', side_effect=RuntimeError("Gateway timeout")):
            EventDispatcher.dispatch_pending_events()

        failing_event.refresh_from_db()
        self.assertEqual(failing_event.status, 'FAILED')
        self.assertEqual(failing_event.retry_count, 1)
        self.assertIsNotNone(failing_event.next_retry_at)
        self.assertGreater(failing_event.next_retry_at, timezone.now())
        self.assertIn("Gateway timeout", failing_event.error_message)

    def test_event_moves_to_dead_letter_after_5_failed_attempts(self):
        event = OutboxEvent.objects.create(
            event_type='PermanentFailEvent',
            aggregate_type='Inventory',
            aggregate_id='inv-999',
            payload={},
            status='FAILED',
            retry_count=4,
            next_retry_at=timezone.now() - timedelta(seconds=1)
        )

        with patch.object(EventDispatcher, '_handle_event', side_effect=ValueError("Unrecoverable data error")):
            EventDispatcher.dispatch_pending_events()

        event.refresh_from_db()
        self.assertEqual(event.status, 'DEAD_LETTER')
        self.assertEqual(event.retry_count, 5)
        self.assertIsNone(event.next_retry_at)

    def test_safety_sos_atomic_creation_and_emergency_dispatch(self):
        # 1. Trigger SOS via SafetyService
        lat, lng = 9.9312, 76.2673
        sos_res = SafetyService.trigger_sos(
            user=self.user,
            latitude=lat,
            longitude=lng,
            location_name='Fort Kochi Beach Promenade',
            alert_type='SOS_112',
            notes='Need immediate medical support'
        )

        self.assertTrue(sos_res['success'])
        alert_id = sos_res['alert_id']

        # Verify OutboxEvent was created atomically
        outbox_event = OutboxEvent.objects.filter(
            event_type='SAFETY_SOS_TRIGGERED',
            aggregate_id=alert_id
        ).first()
        self.assertIsNotNone(outbox_event)
        self.assertEqual(outbox_event.status, 'PENDING')
        self.assertEqual(outbox_event.payload['traveler_name'], 'Kavya Nair')
        self.assertEqual(outbox_event.payload['emergency_contact_email'], 'arun.emergency@example.com')
        self.assertEqual(outbox_event.payload['blood_group'], 'O+')

        # 2. Dispatch pending events
        EventDispatcher.dispatch_pending_events()

        # Verify outbox event is now PROCESSED
        outbox_event.refresh_from_db()
        self.assertEqual(outbox_event.status, 'PROCESSED')
        self.assertIsNotNone(outbox_event.processed_at)

        # Verify emergency notification email sent
        self.assertGreaterEqual(len(mail.outbox), 1)
        sent_email = mail.outbox[0]
        self.assertIn('[CRITICAL EMERGENCY SOS]', sent_email.subject)
        self.assertIn('Kavya Nair', sent_email.subject)
        self.assertIn('arun.emergency@example.com', sent_email.to)
        self.assertIn(f"https://www.google.com/maps?q={lat},{lng}", sent_email.body)
        self.assertIn('Mild asthma', sent_email.body)
        self.assertIn('Penicillin', sent_email.body)
        self.assertIn('O+', sent_email.body)

        # 3. Verify Idempotency: re-running dispatcher does NOT send duplicate emails
        mail.outbox.clear()
        EventDispatcher.dispatch_pending_events()
        self.assertEqual(len(mail.outbox), 0)
