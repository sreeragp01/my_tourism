from django.db import migrations

def purge_fake_profile_data(apps, schema_editor):
    """
    Data migration: Purges legacy hardcoded dummy defaults ('Ananya S.', '+91 94471 23456',
    'mild asthma', eco_score=92) from existing database rows so real users/responders
    never encounter fictitious medical or ICE data.
    """
    UserProfile = apps.get_model('accounts', 'UserProfile')
    for profile in UserProfile.objects.all():
        updated = False
        if profile.emergency_contact_name in ['Ananya S. (Sister)', 'Ananya S.', 'Ananya']:
            profile.emergency_contact_name = ''
            updated = True
        if profile.emergency_contact_phone in ['+91 94471 23456', '+919447123456', '9447123456']:
            profile.emergency_contact_phone = ''
            updated = True
        notes = (profile.medical_notes or '').lower()
        if 'mild asthma' in notes or 'no major allergies' in notes:
            profile.medical_notes = ''
            updated = True
            # Also clear dummy blood group if paired with dummy medical notes
            if profile.blood_group in ['O+ Positive', 'O+']:
                profile.blood_group = ''
        if profile.eco_score == 92:
            profile.eco_score = 0
            profile.eco_tier = 'PIONEER'
            updated = True
        if updated:
            profile.save()

def noop(apps, schema_editor):
    pass

class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0005_emailverificationotp_attempts_and_more'),
    ]

    operations = [
        migrations.RunPython(purge_fake_profile_data, noop),
    ]
