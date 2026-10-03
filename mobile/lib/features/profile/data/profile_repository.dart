import '../../../core/network/api_client.dart';
import '../models/user_profile_model.dart';

abstract class IProfileRepository {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? medicalNotes,
    String? dietaryPreference,
    String? travelPace,
    bool? accessibilityRequired,
  });
  Future<UserProfile> toggleOfflinePackage(String packageId);
}

class ProfileRepository implements IProfileRepository {
  final ApiClient? apiClient;
  UserProfile _cachedProfile = UserProfile.mockDefault();

  ProfileRepository({this.apiClient});

  @override
  Future<UserProfile> getProfile() async {
    if (apiClient != null) {
      try {
        final response = await apiClient!.get('/auth/me/');
        if (response is Map<String, dynamic>) {
          final data = response['data'] is Map<String, dynamic>
              ? response['data'] as Map<String, dynamic>
              : response;
          _cachedProfile = UserProfile.fromJson(data);
          return _cachedProfile;
        }
      } catch (_) {
        // Fallback to cached default
      }
    }
    return _cachedProfile;
  }

  @override
  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? medicalNotes,
    String? dietaryPreference,
    String? travelPace,
    bool? accessibilityRequired,
  }) async {
    final updated = _cachedProfile.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      bloodGroup: bloodGroup,
      medicalNotes: medicalNotes,
      dietaryPreference: dietaryPreference,
      travelPace: travelPace,
      accessibilityRequired: accessibilityRequired,
    );

    if (apiClient != null) {
      try {
        await apiClient!.patch(
          '/auth/profile/',
          body: {
            if (firstName != null) 'first_name': firstName,
            if (lastName != null) 'last_name': lastName,
            if (phone != null) 'phone': phone,
            if (emergencyContactName != null) 'emergency_contact_name': emergencyContactName,
            if (emergencyContactPhone != null) 'emergency_contact_phone': emergencyContactPhone,
            if (bloodGroup != null) 'blood_group': bloodGroup,
            if (dietaryPreference != null) 'dietary_preference': dietaryPreference,
            if (travelPace != null) 'travel_pace': travelPace,
          },
        );
      } catch (_) {}
    }

    _cachedProfile = updated;
    return _cachedProfile;
  }

  @override
  Future<UserProfile> toggleOfflinePackage(String packageId) async {
    final updatedPackages = _cachedProfile.offlinePackages.map((pkg) {
      if (pkg.id == packageId) {
        return pkg.copyWith(isDownloaded: !pkg.isDownloaded);
      }
      return pkg;
    }).toList();

    _cachedProfile = _cachedProfile.copyWith(offlinePackages: updatedPackages);
    return _cachedProfile;
  }
}
