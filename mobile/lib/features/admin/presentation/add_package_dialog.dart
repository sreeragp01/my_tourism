import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/admin_repository.dart';

class AddPackageDialog extends StatefulWidget {
  final AdminRepository adminRepository;
  final VoidCallback onSuccess;

  const AddPackageDialog({
    super.key,
    required this.adminRepository,
    required this.onSuccess,
  });

  static Future<void> show(BuildContext context, AdminRepository repository, VoidCallback onSuccess) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPackageDialog(adminRepository: repository, onSuccess: onSuccess),
    );
  }

  @override
  State<AddPackageDialog> createState() => _AddPackageDialogState();
}

class _AddPackageDialogState extends State<AddPackageDialog> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _taglineController = TextEditingController();
  final _priceController = TextEditingController();
  final _daysController = TextEditingController(text: '3');
  final _nightsController = TextEditingController(text: '2');
  final _startCityController = TextEditingController(text: 'Kochi');
  final _endCityController = TextEditingController(text: 'Kochi');
  final _destinationsController = TextEditingController(text: 'Munnar, Lockhart Valley');
  final _operatorNameController = TextEditingController(text: 'Highland Kerala Guild');
  final _operatorPhoneController = TextEditingController(text: '+91 94470 12345');
  final _imageController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1596178065887-1198b6148b2b?auto=format&fit=crop&w=800&q=80',
  );

  String _selectedCategory = 'HILL_STATION';
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, String> _categories = {
    'HILL_STATION': 'Misty Hill Stations & Tea Trails',
    'BACKWATERS': 'Backwaters & Houseboat Cruises',
    'HONEYMOON': 'Romantic Honeymoon Escapes',
    'ADVENTURE': 'Wildlife Safari & Adventure Treks',
    'AYURVEDA': 'Ayurvedic Wellness & Yoga',
    'CULTURE': 'Heritage & Temple Arts',
    'FAMILY': 'Complete Family Circuits',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _taglineController.dispose();
    _priceController.dispose();
    _daysController.dispose();
    _nightsController.dispose();
    _startCityController.dispose();
    _endCityController.dispose();
    _destinationsController.dispose();
    _operatorNameController.dispose();
    _operatorPhoneController.dispose();
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
      final days = int.tryParse(_daysController.text.trim()) ?? 3;
      final nights = int.tryParse(_nightsController.text.trim()) ?? 2;
      final price = double.tryParse(_priceController.text.trim()) ?? 9999.0;
      final destinations = _destinationsController.text
          .split(',')
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .toList();

      final success = await widget.adminRepository.createPackage(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        tagline: _taglineController.text.trim(),
        description:
            'Handcrafted experiential journey including certified guide, eco homestay, and curated tea estate or backwater activities.',
        durationDays: days,
        durationNights: nights,
        startCity: _startCityController.text.trim(),
        endCity: _endCityController.text.trim(),
        destinationsCovered: destinations,
        pricePerPerson: price,
        heroImage: _imageController.text.trim(),
        operatorName: _operatorNameController.text.trim(),
        operatorPhone: _operatorPhoneController.text.trim(),
        operatorWhatsapp: _operatorPhoneController.text.trim().replaceAll(' ', ''),
        highlights: ['Verified Local Operator', 'Zero-Plastic Stay', 'Private Chauffeur'],
        inclusions: ['Breakfast & Dinner', 'Entry Passes', 'All Tolls & Permits'],
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
                Text('Tour Package created & published live!'),
              ],
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to create tour package. Check details.';
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
                      Icon(Icons.card_travel, color: AppTheme.sunsetGold, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Add Tour Package',
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
                'Publish an authenticated experiential package to the Kerala marketplace.',
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

              // Title
              _buildField('Package Title', _titleController, 'e.g. Munnar Misty Cloud Valley Trek', required: true),
              const SizedBox(height: 12),

              // Category dropdown
              const Text('Category', style: TextStyle(color: AppTheme.textCream, fontSize: 12, fontWeight: FontWeight.w600)),
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
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceTeal,
                    style: const TextStyle(color: AppTheme.textCream, fontSize: 13),
                    items: _categories.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tagline
              _buildField('Tagline', _taglineController, 'e.g. 3 Days in cloud valleys & organic spice trails', required: true),
              const SizedBox(height: 12),

              // Price & Duration
              Row(
                children: [
                  Expanded(
                    child: _buildField('Price (₹ / person)', _priceController, '8500', isNumber: true, required: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField('Days', _daysController, '3', isNumber: true, required: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField('Nights', _nightsController, '2', isNumber: true, required: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cities
              Row(
                children: [
                  Expanded(
                    child: _buildField('Start City', _startCityController, 'Kochi', required: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField('End City', _endCityController, 'Munnar', required: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildField('Destinations Covered (comma separated)', _destinationsController, 'Munnar, Lockhart, Marayoor', required: true),
              const SizedBox(height: 12),

              _buildField('Tour Operator Name', _operatorNameController, 'e.g. Kerala Highland Guild', required: true),
              const SizedBox(height: 12),

              _buildField('Operator Phone / WhatsApp', _operatorPhoneController, '+91 94470 12345', required: true),
              const SizedBox(height: 12),

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
                          'Publish Package',
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
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
