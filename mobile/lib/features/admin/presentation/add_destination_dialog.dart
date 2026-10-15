import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/admin_repository.dart';

class AddDestinationDialog extends StatefulWidget {
  final AdminRepository adminRepository;
  final VoidCallback onSuccess;

  const AddDestinationDialog({
    super.key,
    required this.adminRepository,
    required this.onSuccess,
  });

  static Future<void> show(BuildContext context, AdminRepository repository, VoidCallback onSuccess) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDestinationDialog(adminRepository: repository, onSuccess: onSuccess),
    );
  }

  @override
  State<AddDestinationDialog> createState() => _AddDestinationDialogState();
}

class _AddDestinationDialogState extends State<AddDestinationDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _latController = TextEditingController(text: '9.6865');
  final _lngController = TextEditingController(text: '76.9056');
  final _seasonController = TextEditingController(text: 'September to March');
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80',
  );

  String _selectedDistrict = 'Idukki';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _districts = [
    'Thiruvananthapuram', 'Kollam', 'Pathanamthitta', 'Alappuzha',
    'Kottayam', 'Idukki', 'Ernakulam', 'Thrissur', 'Palakkad',
    'Malappuram', 'Kozhikode', 'Wayanad', 'Kannur', 'Kasaragod',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _seasonController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lat = double.tryParse(_latController.text.trim()) ?? 9.6865;
      final lng = double.tryParse(_lngController.text.trim()) ?? 76.9056;

      final success = await widget.adminRepository.createDestination(
        name: _nameController.text.trim(),
        district: _selectedDistrict,
        tagline: _taglineController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : '${_nameController.text.trim()} is an authentic destination in $_selectedDistrict known for scenic nature and eco-tourism.',
        latitude: lat,
        longitude: lng,
        bestSeason: _seasonController.text.trim(),
        heroImage: _imageController.text.trim(),
        tags: [_selectedDistrict, 'Eco-Tourism', 'Verified Destination'],
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
                Text('Location added to Kerala Discovery & AI Planner!'),
              ],
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to add destination. Check values and retry.';
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
                      Icon(Icons.location_on, color: AppTheme.sunsetGold, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Add New Location',
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
                'Add a new travel destination to KeraLink maps, circuits, and AI itinerary engine.',
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

              // Name
              _buildField('Destination Name', _nameController, 'e.g. Vagamon / Marayoor', required: true),
              const SizedBox(height: 12),

              // District
              const Text('District', style: TextStyle(color: AppTheme.textCream, fontSize: 12, fontWeight: FontWeight.w600)),
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
              const SizedBox(height: 12),

              // Tagline
              _buildField('Tagline', _taglineController, 'e.g. Pine forests, rolling green meadows & cool mountain air', required: true),
              const SizedBox(height: 12),

              // Best Season
              _buildField('Best Season', _seasonController, 'e.g. October to March', required: true),
              const SizedBox(height: 12),

              // Coordinates
              Row(
                children: [
                  Expanded(
                    child: _buildField('Latitude', _latController, '9.6865', isNumber: true, required: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField('Longitude', _lngController, '76.9056', isNumber: true, required: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              _buildField('Description (optional)', _descriptionController, 'Scenic mountain retreat...'),
              const SizedBox(height: 12),

              // Hero Image
              _buildField('Hero Image URL', _imageController, 'https://...', required: true),
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
                          'Add Destination to Platform',
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
    bool isNumber = false,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textCream, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
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
