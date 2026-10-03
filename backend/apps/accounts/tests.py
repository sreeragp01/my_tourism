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

    def test_get_profile_unauthenticated(self):
        url = reverse('user-profile')
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertIn('profile', response.data['data'])
        self.assertEqual(response.data['data']['profile']['eco_score'], 92)

    def test_get_profile_authenticated(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('user-profile')
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['data']['email'], 'traveler@keralink.test')
        self.assertEqual(response.data['data']['first_name'], 'Anand')

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
            'blood_group': 'B+ Positive',
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
        self.assertEqual(profile.blood_group, 'B+ Positive')
        self.assertEqual(profile.dietary_preference, 'Coastal Seafood Lover')
        self.assertEqual(profile.travel_pace, 'Relaxed (1-2 stops/day)')
        self.assertTrue(profile.accessibility_required)
        self.assertEqual(profile.medical_notes, 'Penicillin allergy.')
