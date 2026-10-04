import unittest
from apps.bookings.state_machine import BookingStateMachine, InvalidStateTransitionError

class MockBooking:
    def __init__(self, status='DRAFT'):
        self.status = status
        self.booking_reference = 'KL24062012345'
        self.id = 'test-uuid-001'
        self.total_amount = 68450.00
        self.primary_guest_email = 'guest@keralink.travel'

    def save(self):
        pass

class BookingStateMachineTestCase(unittest.TestCase):
    def test_valid_forward_transitions(self):
        booking = MockBooking('DRAFT')
        sm = BookingStateMachine(booking)
        
        self.assertTrue(sm.can_transition_to('PENDING_PAYMENT'))
        self.assertTrue(sm.can_transition_to('CANCELLED'))
        self.assertFalse(sm.can_transition_to('CONFIRMED'))
        self.assertFalse(sm.can_transition_to('COMPLETED'))

    def test_payment_transitions(self):
        booking = MockBooking('PENDING_PAYMENT')
        sm = BookingStateMachine(booking)
        
        self.assertTrue(sm.can_transition_to('PAYMENT_PROCESSING'))
        self.assertTrue(sm.can_transition_to('PAYMENT_FAILED'))
        self.assertTrue(sm.can_transition_to('EXPIRED'))
        self.assertFalse(sm.can_transition_to('COMPLETED'))

    def test_illegal_jump_rejection(self):
        booking = MockBooking('COMPLETED')
        sm = BookingStateMachine(booking)
        
        # Terminal state cannot jump to payment processing
        self.assertFalse(sm.can_transition_to('PAYMENT_PROCESSING'))
        self.assertFalse(sm.can_transition_to('DRAFT'))
        
        with self.assertRaises(InvalidStateTransitionError):
            sm.transition('PAYMENT_PROCESSING')

if __name__ == '__main__':
    unittest.main()
