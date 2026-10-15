import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/admin_repository.dart';

class AddDriverDialog extends StatefulWidget {
  final AdminRepository adminRepository;
  final VoidCallback onSuccess;

  const AddDriverDialog({
    super.key,
    required this.adminRepository,
    required this.onSuccess,
  });

  static Future<void> show(BuildContext context, AdminRepository repository, VoidCallback onSuccess) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDriverDialog(adminRepository: repository, onSuccess: onSuccess),
    );
  }

  @override
  State<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();

  String _selectedVehicleType = 'SUV_PREMIUM';
  String _selectedDistrict = 'Ernakulam';
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, String> _vehicleTypes = {
    'SEDAN': 'Prime Sedan (Dzire / Etios)',
    'SUV_PREMIUM': 'Mountain SUV (Innova Crysta / Hycross)',
    'TEMPO_TRAVELLER': 'Tempo Traveller (12-17 Seater)',
    'ELECTRIC_EV': 'Green Eco Cab (Nexon / ZS EV)',
  };

  final List<String> _districts = [
    'Thiruvananthapuram', 'Kollam', 'Pathanamthitta', 'Alappuzha',
    'Kottayam', 'Idukki', 'Ernakulam', 'Thrissur', 'Palakkad',
    'Malappuram', 'Kozhikode', 'Wayanad', 'Kannur', 'Kasaragod',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _phoneController.text.trim();
      final whatsapp = _whatsappController.text.trim().isNotEmpty
          ? _whatsappController.text.trim()
          : phone.replaceAll(' ', '');

      final success = await widget.adminRepository.createDriver(
        name: _nameController.text.trim(),
        phone: phone,
        whatsapp: whatsapp,
        licenseNumber: _licenseController.text.trim(),
        vehicleType: _selectedVehicleType,
        vehiclePlateNumber: _plateController.text.trim().toUpperCase(),
        district: _selectedDistrict,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.oceanTeal,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Driver registered and verified into fleet!'),
              ],
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to register driver. Please check inputs.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.midnightTeal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.directions_car_filled, color: AppTheme.sunsetGold, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Add Verified Driver',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textCream,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Enroll a licensed tourist cab chauffeur with ghat-permit authorization.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Driver Name
              _buildField('Full Name', _nameController, 'e.g. Suresh Nair', required: true),
              const SizedBox(height: 12),

              // Contact Phone & WhatsApp
              Row(
                children: [
                  Expanded(
                    child: _buildField('Phone Number', _phoneController, '+91 94470 54321', required: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField('WhatsApp (optional)', _whatsappController, '+919447054321'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // License & Vehicle Plate
              Row(
                children: [
                  Expanded(
                    child: _buildField('License Number', _licenseController, 'KL-07-2018-004589', required: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField('Vehicle Plate', _plateController, 'KL-07-CD-4589', required: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Vehicle Type
              const Text('Vehicle Type', style: TextStyle(color: AppTheme.textCream, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceTeal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderTeal),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVehicleType,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceTeal,
                    style: const TextStyle(color: AppTheme.textCream, fontSize: 13),
                    items: _vehicleTypes.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedVehicleType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Operating District
              const Text('Operating District', style: TextStyle(color: AppTheme.textCream, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceTeal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderTeal),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDistrict,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceTeal,
                    style: const TextStyle(color: AppTheme.textCream, fontSize: 13),
                    items: _districts.map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDistrict = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sunsetGold,
                    foregroundColor: AppTheme.midnightTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: AppTheme.midnightTeal, strokeWidth: 2.2),
                        )
                      : const Text(
                          'Enroll & Verify Driver',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textCream, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: AppTheme.textCream, fontSize: 13),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppTheme.surfaceTeal,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderTeal),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.sunsetGold),
            ),
          ),
        ),
      ],
    );
  }
}
