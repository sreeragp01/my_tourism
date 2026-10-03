import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../safety/presentation/safety_hub_screen.dart';
import '../data/profile_repository.dart';
import '../models/user_profile_model.dart';

class ProfileScreen extends StatefulWidget {
  final IProfileRepository? repository;
  final VoidCallback? onLogout;

  const ProfileScreen({
    super.key,
    this.repository,
    this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final IProfileRepository _repository;
  UserProfile _profile = UserProfile.mockDefault();
  bool _isLoading = true;
  String _selectedLanguage = 'English (EN)';

  final List<String> _dietaryOptions = [
    'Traditional Kerala Sadya (Veg)',
    'Coastal Seafood Lover',
    'Non-Vegetarian',
    'Jain / Pure Veg',
  ];

  final List<String> _paceOptions = [
    'Relaxed (1-2 stops/day)',
    'Balanced (2-3 stops/day)',
    'Action-Packed (4+ stops/day)',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProfileRepository();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prof = await _repository.getProfile();
    if (mounted) {
      setState(() {
        _profile = prof;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDietary(String diet) async {
    setState(() => _profile = _profile.copyWith(dietaryPreference: diet));
    await _repository.updateProfile(dietaryPreference: diet);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceTeal,
        content: Text(
          'AI Travel Architect preference updated to $diet',
          style: const TextStyle(color: AppTheme.sunsetGold, fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updatePace(String pace) async {
    setState(() => _profile = _profile.copyWith(travelPace: pace));
    await _repository.updateProfile(travelPace: pace);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceTeal,
        content: Text(
          'Travel pace updated to $pace',
          style: const TextStyle(color: AppTheme.sunsetGold, fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleOffline(String packageId) async {
    final updated = await _repository.toggleOfflinePackage(packageId);
    if (mounted) {
      setState(() => _profile = updated);
      final pkg = updated.offlinePackages.firstWhere((p) => p.id == packageId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surfaceTeal,
          content: Text(
            pkg.isDownloaded
                ? 'Downloaded ${pkg.name} for offline ghat navigation'
                : 'Removed ${pkg.name} from offline cache',
            style: const TextStyle(color: AppTheme.oceanTeal, fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _profile.firstName);
    final phoneController = TextEditingController(text: _profile.phone);
    final iceNameController = TextEditingController(text: _profile.emergencyContactName);
    final icePhoneController = TextEditingController(text: _profile.emergencyContactPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceTeal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Traveler Details',
                    style: TextStyle(
                      color: AppTheme.textCream,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDialogField(controller: nameController, label: 'First Name', icon: Icons.person_outline),
              const SizedBox(height: 12),
              _buildDialogField(controller: phoneController, label: 'Phone Number', icon: Icons.phone_outlined),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderTeal),
              const SizedBox(height: 12),
              const Text(
                'Safety & Emergency Contact (ICE)',
                style: TextStyle(color: AppTheme.sunsetGold, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDialogField(controller: iceNameController, label: 'ICE Contact Name', icon: Icons.contact_emergency_outlined),
              const SizedBox(height: 12),
              _buildDialogField(controller: icePhoneController, label: 'ICE Phone Number', icon: Icons.emergency_outlined),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sunsetGold,
                    foregroundColor: AppTheme.midnightTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final updated = await _repository.updateProfile(
                      firstName: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      emergencyContactName: iceNameController.text.trim(),
                      emergencyContactPhone: icePhoneController.text.trim(),
                    );
                    if (mounted) {
                      setState(() => _profile = updated);
                    }
                  },
                  child: const Text('Save Profile Updates', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textCream, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.sunsetGold, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderTeal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.sunsetGold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.midnightTeal,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.sunsetGold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.midnightTeal,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceTeal,
        elevation: 0,
        title: const Text(
          'Traveler Profile & Passport',
          style: TextStyle(
            color: AppTheme.textCream,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.sunsetGold),
            tooltip: 'Edit Profile',
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Traveler Header Card
            _buildTravelerHeader(),
            const SizedBox(height: 16),

            // 2. Metrics Ribbon
            _buildMetricsRibbon(),
            const SizedBox(height: 20),

            // 3. Emergency & Safety Hub (ICE)
            _buildSectionHeader('Safety & Emergency (ICE)', Icons.shield_rounded, AppTheme.emergencyRed),
            const SizedBox(height: 10),
            _buildIceCard(),
            const SizedBox(height: 20),

            // 4. AI Travel Architect Preferences
            _buildSectionHeader('AI Travel & Dietary Preferences', Icons.auto_awesome, AppTheme.sunsetGold),
            const SizedBox(height: 10),
            _buildAiPreferencesCard(),
            const SizedBox(height: 20),

            // 5. Eco-Tourism Passport
            _buildSectionHeader('Eco-Passport & Badges', Icons.eco_rounded, AppTheme.oceanTeal),
            const SizedBox(height: 10),
            _buildEcoPassportCard(),
            const SizedBox(height: 20),

            // 6. Offline Ghat Corridors
            _buildSectionHeader('Offline Ghat Corridors', Icons.offline_pin_rounded, AppTheme.sunsetGold),
            const SizedBox(height: 10),
            _buildOfflineCorridorsCard(),
            const SizedBox(height: 20),

            // 7. App Preferences & Language
            _buildSectionHeader('Preferences & Security', Icons.settings_rounded, AppTheme.textMuted),
            const SizedBox(height: 10),
            _buildPreferencesCard(),
            const SizedBox(height: 24),

            // 8. Sign Out Button
            if (widget.onLogout != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.emergencyRed,
                    side: const BorderSide(color: AppTheme.emergencyRed, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Sign Out of KeraLink', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: widget.onLogout,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textCream,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTravelerHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderTeal),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with golden border
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.sunsetGold, width: 2),
              color: AppTheme.surfaceElevated,
            ),
            child: ClipOval(
              child: (_profile.avatarUrl != null && _profile.avatarUrl!.isNotEmpty)
                  ? Image.network(
                      _profile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.person, color: AppTheme.sunsetGold, size: 36),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.person, color: AppTheme.sunsetGold, size: 36),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _profile.fullName,
                        style: const TextStyle(
                          color: AppTheme.textCream,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.oceanTeal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.oceanTeal.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, color: AppTheme.oceanTeal, size: 12),
                          SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: TextStyle(color: AppTheme.oceanTeal, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _profile.email,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _profile.phone,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.sunsetGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.sunsetGold.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '🌿 ${_profile.ecoTier}',
                    style: const TextStyle(
                      color: AppTheme.sunsetGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRibbon() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Eco Score',
            value: '${_profile.ecoScore}%',
            icon: Icons.eco,
            color: AppTheme.oceanTeal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            label: 'Trips Done',
            value: '${_profile.tripsCompleted}',
            icon: Icons.luggage_rounded,
            color: AppTheme.sunsetGold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            label: 'ICE Safety',
            value: 'Ready',
            icon: Icons.health_and_safety_rounded,
            color: AppTheme.oceanTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderTeal),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.emergencyRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Primary Emergency Contact (ICE)',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _profile.emergencyContactName,
                    style: const TextStyle(
                      color: AppTheme.textCream,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _profile.emergencyContactPhone,
                    style: const TextStyle(
                      color: AppTheme.oceanTeal,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.emergencyRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.emergencyRed.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _profile.bloodGroup,
                  style: const TextStyle(
                    color: AppTheme.emergencyRed,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_profile.medicalNotes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _profile.medicalNotes,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceElevated,
                foregroundColor: AppTheme.textCream,
                side: const BorderSide(color: AppTheme.borderTeal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.shield_outlined, color: AppTheme.emergencyRed, size: 18),
              label: const Text('Open Kerala Safety & SOS Hub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SafetyHubScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dietary Profile (Auto-seeds AI Itinerary Generator)',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dietaryOptions.map((opt) {
              final isSelected = _profile.dietaryPreference == opt;
              return ChoiceChip(
                label: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? AppTheme.midnightTeal : AppTheme.textCream,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.sunsetGold,
                backgroundColor: AppTheme.surfaceElevated,
                side: BorderSide(
                  color: isSelected ? AppTheme.sunsetGold : AppTheme.borderTeal,
                ),
                onSelected: (_) => _updateDietary(opt),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Travel Rhythm & Pace',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paceOptions.map((opt) {
              final isSelected = _profile.travelPace == opt;
              return ChoiceChip(
                label: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? AppTheme.midnightTeal : AppTheme.textCream,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.sunsetGold,
                backgroundColor: AppTheme.surfaceElevated,
                side: BorderSide(
                  color: isSelected ? AppTheme.sunsetGold : AppTheme.borderTeal,
                ),
                onSelected: (_) => _updatePace(opt),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEcoPassportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.electric_car_rounded, color: AppTheme.oceanTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_profile.evMiles} Clean EV Miles',
                    style: const TextStyle(color: AppTheme.textCream, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${_profile.carbonOffsetKg} kg CO₂ saved',
                style: const TextStyle(color: AppTheme.oceanTeal, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Earned Kerala Badges',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Column(
            children: _profile.badges.map((badge) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderTeal),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.sunsetGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.sunsetGold.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.star_rounded, color: AppTheme.sunsetGold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badge.title,
                            style: const TextStyle(color: AppTheme.textCream, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            badge.description,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      badge.earnedAt,
                      style: const TextStyle(color: AppTheme.sunsetGold, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineCorridorsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'High-Range & Ghat Pass Navigation (Works without cellular network)',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Column(
            children: _profile.offlinePackages.map((pkg) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: pkg.isDownloaded ? AppTheme.oceanTeal.withValues(alpha: 0.4) : AppTheme.borderTeal,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      pkg.isDownloaded ? Icons.offline_pin_rounded : Icons.cloud_download_outlined,
                      color: pkg.isDownloaded ? AppTheme.oceanTeal : AppTheme.textMuted,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg.name,
                            style: const TextStyle(color: AppTheme.textCream, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pkg.size} · ${pkg.includes}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        pkg.isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                        color: pkg.isDownloaded ? AppTheme.oceanTeal : AppTheme.sunsetGold,
                      ),
                      onPressed: () => _toggleOffline(pkg.id),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderTeal),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.language_rounded, color: AppTheme.sunsetGold, size: 20),
                  SizedBox(width: 10),
                  Text('App Language', style: TextStyle(color: AppTheme.textCream, fontSize: 14)),
                ],
              ),
              DropdownButton<String>(
                value: _selectedLanguage,
                dropdownColor: AppTheme.surfaceElevated,
                underline: const SizedBox(),
                style: const TextStyle(color: AppTheme.sunsetGold, fontSize: 13, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 'English (EN)', child: Text('English (EN)')),
                  DropdownMenuItem(value: 'Malayalam (മലയാളം)', child: Text('മലയാളം (ML)')),
                  DropdownMenuItem(value: 'Hindi (हिंदी)', child: Text('हिंदी (HI)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
