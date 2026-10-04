from django.test import TestCase, override_settings
from django.urls import reverse
from django.core import mail
from django.core.cache import cache
from django.utils import timezone
from datetime import timedelta
from unittest.mock import patch
from rest_framework.test import APIClient
from rest_framework import status

from apps.accounts.models import User, UserSession, PasswordResetOTP, EmailVerificationOTP
from apps.accounts.services import AccountEmailService

TEST_REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'apps.accounts.authentication.KeraLinkJWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticatedOrReadOnly',
    ],
    'DEFAULT_THROTTLE_CLASSES': [],
    'DEFAULT_THROTTLE_RATES': {},
    'NUM_PROXIES': 1,
}


class OTPModelTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='keralatourist@example.com',
            password='InitialPassword123!',
            first_name='Kavya',
            last_name='Nair'
        )

    def test_password_reset_otp_generation(self):
        otp = PasswordResetOTP.generate_otp_for_user(self.user)
        self.assertEqual(len(otp.otp), 6)
        self.assertTrue(otp.otp.isdigit())
        self.assertFalse(otp.is_used)
        self.assertTrue(otp.is_valid())
        self.assertGreater(otp.expires_at, timezone.now())
        self.assertLessEqual(otp.expires_at, timezone.now() + timedelta(minutes=11))

    def test_password_reset_otp_invalidates_previous_otps(self):
        otp1 = PasswordResetOTP.generate_otp_for_user(self.user)
        otp2 = PasswordResetOTP.generate_otp_for_user(self.user)
        
        otp1.refresh_from_db()
        self.assertTrue(otp1.is_used)
        self.assertFalse(otp1.is_valid())
        
        self.assertFalse(otp2.is_used)
        self.assertTrue(otp2.is_valid())

    def test_password_reset_otp_expiration(self):
        otp = PasswordResetOTP.generate_otp_for_user(self.user)
        otp.expires_at = timezone.now() - timedelta(seconds=1)
        otp.save()
        self.assertFalse(otp.is_valid())

    def test_email_verification_otp_generation(self):
        otp = EmailVerificationOTP.generate_otp_for_user(self.user)
        self.assertEqual(len(otp.otp), 6)
        self.assertTrue(otp.otp.isdigit())
        self.assertFalse(otp.is_used)
        self.assertTrue(otp.is_valid())
        self.assertGreater(otp.expires_at, timezone.now())
        self.assertLessEqual(otp.expires_at, timezone.now() + timedelta(minutes=11))

    def test_email_verification_otp_invalidates_previous_otps(self):
        otp1 = EmailVerificationOTP.generate_otp_for_user(self.user)
        otp2 = EmailVerificationOTP.generate_otp_for_user(self.user)
        
        otp1.refresh_from_db()
        self.assertTrue(otp1.is_used)
        self.assertFalse(otp1.is_valid())
        
        self.assertFalse(otp2.is_used)
        self.assertTrue(otp2.is_valid())


@override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
class AccountEmailServiceTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='traveler.alappuzha@example.com',
            password='OldSecurePass123!',
            first_name='Rahul'
        )

    def test_send_password_reset_otp_email_success(self):
        otp_code = '458921'
        success = AccountEmailService.send_password_reset_otp_email(self.user, otp_code)
        
        self.assertTrue(success)
        self.assertEqual(len(mail.outbox), 1)
        sent_email = mail.outbox[0]
        self.assertEqual(sent_email.to, [self.user.email])
        self.assertIn(otp_code, sent_email.subject)
        self.assertIn(otp_code, sent_email.body)
        self.assertIn(otp_code, sent_email.alternatives[0][0])
        self.assertEqual(sent_email.alternatives[0][1], 'text/html')

    def test_send_verification_otp_email_success(self):
        otp_code = '812349'
        success = AccountEmailService.send_verification_otp_email(self.user, otp_code)
        
        self.assertTrue(success)
        self.assertEqual(len(mail.outbox), 1)
        sent_email = mail.outbox[0]
        self.assertEqual(sent_email.to, [self.user.email])
        self.assertIn(otp_code, sent_email.subject)
        self.assertIn(otp_code, sent_email.body)
        self.assertIn(otp_code, sent_email.alternatives[0][0])
        self.assertEqual(sent_email.alternatives[0][1], 'text/html')

    @patch('apps.accounts.services.send_mail')
    def test_send_email_fallback_on_smtp_error(self, mock_send_mail):
        mock_send_mail.side_effect = Exception("SMTP Connection Timeout")
        success = AccountEmailService.send_password_reset_otp_email(self.user, '111222')
        self.assertFalse(success)


@override_settings(
    EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend',
    REST_FRAMEWORK=TEST_REST_FRAMEWORK,
)
class PasswordResetAPITestCase(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        self.email = 'ananya.kochi@example.com'
        self.user = User.objects.create_user(
            email=self.email,
            password='OriginalPassword123!',
            first_name='Ananya'
        )

    def test_request_password_reset_valid_user_hides_demo_otp(self):
        url = reverse('password-reset-request')
        response = self.client.post(url, {'email': self.email}, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['success'])
        self.assertTrue(response.data['email_sent'])
        # demo_otp must never be returned in API JSON
        self.assertNotIn('demo_otp', response.data)
        
        # Verify email dispatched to outbox containing real OTP
        self.assertEqual(len(mail.outbox), 1)
        otp_record = PasswordResetOTP.objects.filter(user=self.user, is_used=False).first()
        self.assertIsNotNone(otp_record)
        self.assertIn(otp_record.otp, mail.outbox[0].body)

    @patch('apps.accounts.views.VerifyPasswordResetView.throttle_classes', [])
    def test_verify_password_reset_locks_after_5_failed_attempts(self):
        otp = PasswordResetOTP.generate_otp_for_user(self.user)
        url = reverse('password-reset-verify')

        # First 4 failed attempts: returns 400 with attempts count
        for i in range(1, 5):
            res = self.client.post(url, {'email': self.email, 'otp': '000000', 'new_password': 'NewPassword123!'}, format='json')
            self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
            self.assertIn(f'{5 - i} attempt(s) remaining', res.data['error']['message'])

        # 5th failed attempt: reaches max attempts (5)
        res = self.client.post(url, {'email': self.email, 'otp': '000000', 'new_password': 'NewPassword123!'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

        # 6th attempt: locked out with 429 TOO_MANY_REQUESTS
        res = self.client.post(url, {'email': self.email, 'otp': otp.otp, 'new_password': 'NewPassword123!'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertEqual(res.data['error']['code'], 'OTP_LOCKED')

    def test_request_password_reset_nonexistent_user_safe_response(self):
        url = reverse('password-reset-request')
        response = self.client.post(url, {'email': 'ghost.user@nonexistent.domain'}, format='json')
        
        # Must return 200 with generic message to prevent user enumeration
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['success'])
        self.assertIn('If an account exists', response.data['message'])
        self.assertEqual(len(mail.outbox), 0)

    def test_verify_password_reset_success(self):
        otp = PasswordResetOTP.generate_otp_for_user(self.user)
        session = UserSession.objects.create(
            user=self.user,
            device_id='dev-1234',
            device_name='Desktop Linux',
            platform='WEB',
            ip_address='127.0.0.1',
            user_agent='TestRunner/1.0',
            expires_at=timezone.now() + timedelta(days=30)
        )
        
        url = reverse('password-reset-verify')
        payload = {
            'email': self.email,
            'otp': otp.otp,
            'new_password': 'BrandNewSecurePassword456!'
        }
        response = self.client.post(url, payload, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['success'])
        
        # Verify password actually changed
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('BrandNewSecurePassword456!'))
        self.assertFalse(self.user.check_password('OriginalPassword123!'))
        
        # Verify OTP marked as used
        otp.refresh_from_db()
        self.assertTrue(otp.is_used)
        
        # Verify sessions revoked
        session.refresh_from_db()
        self.assertIsNotNone(session.revoked_at)

    def test_verify_password_reset_wrong_otp(self):
        PasswordResetOTP.generate_otp_for_user(self.user)
        url = reverse('password-reset-verify')
        payload = {
            'email': self.email,
            'otp': '000000',
            'new_password': 'AnotherPassword789!'
        }
        response = self.client.post(url, payload, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['error']['code'], 'INVALID_OTP')

    def test_verify_password_reset_expired_otp(self):
        otp = PasswordResetOTP.generate_otp_for_user(self.user)
        otp.expires_at = timezone.now() - timedelta(minutes=5)
        otp.save()
        
        url = reverse('password-reset-verify')
        payload = {
            'email': self.email,
            'otp': otp.otp,
            'new_password': 'AnotherPassword789!'
        }
        response = self.client.post(url, payload, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['error']['code'], 'OTP_EXPIRED')

    def test_verify_password_reset_replay_attack_rejected(self):
        otp = PasswordResetOTP.generate_otp_for_user(self.user)
        url = reverse('password-reset-verify')
        payload = {
            'email': self.email,
            'otp': otp.otp,
            'new_password': 'ValidPasswordPass1!'
        }
        
        # First verification succeeds
        first_res = self.client.post(url, payload, format='json')
        self.assertEqual(first_res.status_code, status.HTTP_200_OK)
        
        # Replaying same OTP must fail
        payload['new_password'] = 'SecondTryPass2!'
        second_res = self.client.post(url, payload, format='json')
        self.assertEqual(second_res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(second_res.data['error']['code'], 'INVALID_OTP')


@override_settings(
    EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend',
    REST_FRAMEWORK=TEST_REST_FRAMEWORK,
)
class EmailVerificationAPITestCase(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='newbie@keralink.travel',
            password='TestPassword123!',
            first_name='UnverifiedUser',
            is_email_verified=False
        )

    def test_send_verification_otp_unauthenticated_fails(self):
        url = reverse('otp-send')
        response = self.client.post(url, {}, format='json')
        self.assertIn(response.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    def test_send_verification_otp_authenticated_success(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('otp-send')
        response = self.client.post(url, {}, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['success'])
        self.assertTrue(response.data['email_sent'])
        self.assertEqual(len(mail.outbox), 1)

    def test_verify_email_otp_success(self):
        otp = EmailVerificationOTP.generate_otp_for_user(self.user)
        self.client.force_authenticate(user=self.user)
        
        url = reverse('otp-verify')
        response = self.client.post(url, {'otp': otp.otp}, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['success'])
        
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_email_verified)
        
        otp.refresh_from_db()
        self.assertTrue(otp.is_used)

    def test_verify_email_otp_wrong_code(self):
        EmailVerificationOTP.generate_otp_for_user(self.user)
        self.client.force_authenticate(user=self.user)
        
        url = reverse('otp-verify')
        response = self.client.post(url, {'otp': '999999'}, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['error']['code'], 'INVALID_OTP')
        self.user.refresh_from_db()
        self.assertFalse(self.user.is_email_verified)
