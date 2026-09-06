import unittest
import uuid
from typing import List

class MockOutboxEvent:
    def __init__(self, event_type: str, aggregate_type: str, aggregate_id: str, payload: dict):
        self.id = str(uuid.uuid4())
        self.event_type = event_type
        self.aggregate_type = aggregate_type
        self.aggregate_id = aggregate_id
        self.payload = payload
        self.status = 'PENDING'
        self.retry_count = 0
        self.max_retries = 3
        self.error_message = None

class MockOutboxDispatcher:
    def __init__(self):
        self.dispatched = []
        self.dead_letter_queue = []

    def dispatch(self, event: MockOutboxEvent, fail_mode: bool = False):
        if fail_mode:
            event.retry_count += 1
            event.error_message = "Downstream consumer unreachable (503 Service Unavailable)"
            if event.retry_count >= event.max_retries:
                event.status = 'DEAD_LETTER'
                self.dead_letter_queue.append(event)
            else:
                event.status = 'FAILED'
        else:
            event.status = 'PROCESSED'
            self.dispatched.append(event)

class OutboxReliabilityAndDeadLetterTestCase(unittest.TestCase):
    """
    Test Suite: Transactional Outbox Reliability, Retries & Dead-Letter Handling.
    Flow:
      1. BookingConfirmed event is written atomically within DB transaction.
      2. Celery worker attempts dispatch:
         - On success: status -> PROCESSED.
         - On temporary failure: retry_count increments, status -> FAILED.
         - On reaching max retries (3): status -> DEAD_LETTER, routed to dead-letter queue.
    """

    def setUp(self):
        self.dispatcher = MockOutboxDispatcher()
        self.event = MockOutboxEvent(
            event_type="BookingConfirmed",
            aggregate_type="Booking",
            aggregate_id="bkg-uuid-101",
            payload={"booking_reference": "KL2609051001", "total_amount": 68450.0}
        )

    def test_successful_outbox_dispatch(self):
        self.dispatcher.dispatch(self.event, fail_mode=False)

        self.assertEqual(self.event.status, 'PROCESSED')
        self.assertEqual(len(self.dispatcher.dispatched), 1)
        self.assertEqual(len(self.dispatcher.dead_letter_queue), 0)

    def test_retry_and_dead_letter_transition(self):
        # Attempt 1: Fail
        self.dispatcher.dispatch(self.event, fail_mode=True)
        self.assertEqual(self.event.status, 'FAILED')
        self.assertEqual(self.event.retry_count, 1)

        # Attempt 2: Fail
        self.dispatcher.dispatch(self.event, fail_mode=True)
        self.assertEqual(self.event.status, 'FAILED')
        self.assertEqual(self.event.retry_count, 2)

        # Attempt 3: Fail -> Max Retries reached -> Must transition to DEAD_LETTER
        self.dispatcher.dispatch(self.event, fail_mode=True)
        self.assertEqual(self.event.status, 'DEAD_LETTER')
        self.assertEqual(self.event.retry_count, 3)
        self.assertEqual(len(self.dispatcher.dead_letter_queue), 1)

if __name__ == '__main__':
    unittest.main()
