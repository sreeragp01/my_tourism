import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keralink_mobile/features/profile/models/user_profile_model.dart';
import 'package:keralink_mobile/features/profile/data/profile_repository.dart';
import 'package:keralink_mobile/features/profile/presentation/profile_screen.dart';
import 'package:keralink_mobile/features/main/presentation/main_nav_screen.dart';

class MockProfileRepository implements IProfileRepository {
  UserProfile profile = const UserProfile(
    id: 'd0a1b2c3-4d5e-6f7a-8b9c-0d1e2f3a4b5c',
    email: 'traveler@keralink.travel',
    firstName: 'Test',
    lastName: 'Traveler',
    phone: '+91 00000 00001',
    emergencyContactName: 'Test Contact',
    emergencyContactPhone: '+91 00000 00002',
    bloodGroup: 'O+ Positive',
    medicalNotes: 'No allergies recorded.',
    dietaryPreference: 'Traditional Kerala Sadya (Veg)',
    travelPace: 'Balanced (2-3 stops/day)',
    accessibilityRequired: false,
    ecoScore: 92,
    ecoTier: 'Backwater Guardian',
    tripsCompleted: 3,
    evMiles: 142,
    carbonOffsetKg: 58.4,
    badges: [
      BadgeItem(
        id: 'munnar_mist',
        title: 'Munnar Mist Explorer',
        icon: 'landscape',
        description: 'Navigated high-altitude tea trails of Lockhart Valley',
        earnedAt: 'Aug 2026',
      ),
    ],
    offlinePackages: [
      OfflinePackageItem(
        id: 'pkg_munnar',
        name: 'Munnar & Lockhart Valley Corridor',
        size: '42 MB',
        isDownloaded: true,
        includes: 'Ghat route topo',
      ),
      OfflinePackageItem(
        id: 'pkg_wayanad',
        name: 'Wayanad Ghat & Forest Pass',
        size: '38 MB',
        isDownloaded: false,
        includes: 'Thamarassery Churam hairpin map',
      ),
    ],
  );
  int updateCount = 0;
  int toggleCount = 0;

  @override
  Future<UserProfile> getProfile() async => profile;

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
    updateCount++;
    profile = profile.copyWith(
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
    return profile;
  }

  @override
  Future<UserProfile> toggleOfflinePackage(String packageId) async {
    toggleCount++;
    final updated = profile.offlinePackages.map((p) {
      if (p.id == packageId) {
        return p.copyWith(isDownloaded: !p.isDownloaded);
      }
      return p;
    }).toList();
    profile = profile.copyWith(offlinePackages: updated);
    return profile;
  }
}

void main() {
  group('Traveler Profile & Passport Tests', () {
    late MockProfileRepository mockRepo;

    setUp(() {
      mockRepo = MockProfileRepository();
    });

    testWidgets('ProfileScreen renders traveler details, eco score, and ICE card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(repository: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Traveler name and tier
      expect(find.text('Test Traveler'), findsOneWidget);
      expect(find.text('traveler@keralink.travel'), findsOneWidget);
      expect(find.text('🌿 Backwater Guardian'), findsOneWidget);

      // Ribbon metrics
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('Eco Score'), findsOneWidget);
      expect(find.text('ICE Safety'), findsOneWidget);

      // ICE Emergency contact
      expect(find.text('Test Contact'), findsOneWidget);
      expect(find.text('O+ Positive'), findsOneWidget);

      // AI dietary chips
      expect(find.text('Traditional Kerala Sadya (Veg)'), findsOneWidget);
      expect(find.text('Coastal Seafood Lover'), findsOneWidget);

      // Scroll down to Badges & Offline packages
      await tester.scrollUntilVisible(find.text('Munnar Mist Explorer'), 200);
      expect(find.text('Munnar Mist Explorer'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Munnar & Lockhart Valley Corridor'), 200);
      expect(find.text('Munnar & Lockhart Valley Corridor'), findsOneWidget);
    });

    testWidgets('Tapping dietary chip updates AI travel architect preferences', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(repository: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final seafoodChip = find.text('Coastal Seafood Lover');
      await tester.scrollUntilVisible(seafoodChip, 200);
      expect(seafoodChip, findsOneWidget);

      await tester.tap(seafoodChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(mockRepo.updateCount, 1);
      expect(mockRepo.profile.dietaryPreference, 'Coastal Seafood Lover');
    });

    testWidgets('Tapping offline download toggle changes package status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(repository: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Scroll to Wayanad download button
      final downloadIcons = find.byIcon(Icons.download_rounded);
      await tester.scrollUntilVisible(downloadIcons, 300);
      expect(downloadIcons, findsOneWidget);

      await tester.tap(downloadIcons);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(mockRepo.toggleCount, 1);
      expect(mockRepo.profile.offlinePackages.firstWhere((p) => p.id == 'pkg_wayanad').isDownloaded, true);
    });

    testWidgets('Edit profile button opens modal bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(repository: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final editBtn = find.byTooltip('Edit Profile');
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit Traveler Details'), findsOneWidget);
      expect(find.text('Save Profile Updates'), findsOneWidget);
    });

    testWidgets('MainNavScreen renders 5th Profile tab and switches to ProfileScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavScreen(profileRepository: mockRepo),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final profileTab = find.text('Profile');
      expect(profileTab, findsOneWidget);

      await tester.tap(profileTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Traveler Profile & Passport'), findsOneWidget);
    });
  });
}
