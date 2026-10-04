from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from .models import User

class UserProfileTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='traveler@keralink.test',
            password='Password123!',
            first_name='Anand',
            last_name='Kumar',
            phone='+91 98460 11223'
        )

    def test_get_profile_unauthenticated_denied(self):
        url = reverse('user-profile')
        response = self.client.get(url)
        self.assertIn(response.status_code, [401, 403])

    def test_get_profile_authenticated_has_clean_blank_defaults(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('user-profile')
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['data']['email'], 'traveler@keralink.test')
        self.assertEqual(response.data['data']['first_name'], 'Anand')
        profile_data = response.data['data']['profile']
        # Must NOT have demo data from third party
        self.assertEqual(profile_data['emergency_contact_name'], '')
        self.assertEqual(profile_data['emergency_contact_phone'], '')
        self.assertEqual(profile_data['medical_notes'], '')
        self.assertEqual(profile_data['eco_score'], 0)
        self.assertEqual(profile_data['badges'], [])

    def test_patch_profile(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('user-profile-update')
        response = self.client.patch(url, {'first_name': 'Anand Updated', 'phone': '+91 99999 88888'}, format='json')
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.first_name, 'Anand Updated')
        self.assertEqual(self.user.phone, '+91 99999 88888')

    def test_patch_profile_ice_and_preferences(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('user-profile-update')
        payload = {
            'emergency_contact_name': 'Meera K. (Wife)',
            'emergency_contact_phone': '+91 98470 55443',
            'emergency_contact_email': 'meera@keralink.test',
            'emergency_location_sharing_consented': True,
            'blood_group': 'B+',
            'medical_notes': 'Penicillin allergy.',
            'dietary_preference': 'Coastal Seafood Lover',
            'travel_pace': 'Relaxed (1-2 stops/day)',
            'accessibility_required': True
        }
        response = self.client.patch(url, payload, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        
        self.user.refresh_from_db()
        profile = self.user.profile
        self.assertEqual(profile.emergency_contact_name, 'Meera K. (Wife)')
        self.assertEqual(profile.emergency_contact_phone, '+91 98470 55443')
        self.assertEqual(profile.emergency_contact_email, 'meera@keralink.test')
        self.assertTrue(profile.emergency_location_sharing_consented)
        self.assertEqual(profile.blood_group, 'B+')
        self.assertEqual(profile.dietary_preference, 'Coastal Seafood Lover')
        self.assertEqual(profile.travel_pace, 'Relaxed (1-2 stops/day)')
        self.assertTrue(profile.accessibility_required)
        self.assertEqual(profile.medical_notes, 'Penicillin allergy.')

    def test_patch_profile_invalid_blood_group_fails(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('user-profile-update')
        response = self.client.patch(url, {'blood_group': 'InvalidBloodType'}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_patch_profile_cannot_manipulate_eco_score(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('user-profile-update')
        # Attempt to forge eco_score
        response = self.client.patch(url, {'eco_score': 9999}, format='json')
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.profile.eco_score, 0)

    def test_login_does_not_leak_profile_health_data(self):
        url = reverse('login')
        response = self.client.post(url, {
            'email': 'traveler@keralink.test',
            'password': 'Password123!'
        }, format='json')
        self.assertEqual(response.status_code, 200)
        user_data = response.data['data']['user']
        # UserSerializer must NOT leak profile or medical notes
        self.assertNotIn('profile', user_data)
        self.assertNotIn('medical_notes', user_data)
