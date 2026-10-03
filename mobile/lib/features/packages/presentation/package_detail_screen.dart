import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/package_repository.dart';
import '../models/package_models.dart';

class PackageDetailScreen extends StatefulWidget {
  final TourPackage package;
  final IPackageRepository? repository;

  const PackageDetailScreen({
    super.key,
    required this.package,
    this.repository,
  });

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  // Option B: Coastal Twilight Teal & Golden Sunset
  static const Color bgDark = AppTheme.midnightTeal;
  static const Color surfaceDark = AppTheme.surfaceTeal;
  static const Color borderSubtle = AppTheme.borderTeal;
  static const Color emerald = AppTheme.oceanTeal;
  static const Color gold = AppTheme.sunsetGold;
  static const Color textPrimary = AppTheme.textCream;
  static const Color textMuted = AppTheme.textMuted;
  static const Color textSubtle = AppTheme.textSubtle;

  late TourPackage _package;

  @override
  void initState() {
    super.initState();
    _package = widget.package;
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    if (widget.repository == null) return;
    try {
      final full = await widget.repository!.getPackageDetail(widget.package.slug);
      if (mounted) {
        setState(() => _package = full);
      }
    } catch (_) {}
  }

  void _openInquiryModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    int guests = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Connect with Operator',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Direct inquiry to ${_package.operator.name}',
                style: const TextStyle(color: emerald, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextField(
                key: const Key('inquiry_name_field'),
                controller: nameCtrl,
                style: const TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Your Full Name',
                  labelStyle: const TextStyle(color: textSubtle),
                  filled: true,
                  fillColor: bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderSubtle)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: emerald, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              // Phone Field
              TextField(
                key: const Key('inquiry_phone_field'),
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Phone / WhatsApp Number',
                  labelStyle: const TextStyle(color: textSubtle),
                  filled: true,
                  fillColor: bgDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderSubtle)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: emerald, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              // Guests Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Number of Travelers:', style: TextStyle(color: textPrimary, fontSize: 14)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: emerald),
                        onPressed: () {
                          if (guests > 1) setModalState(() => guests--);
                        },
                      ),
                      Text('$guests', style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: emerald),
                        onPressed: () => setModalState(() => guests++),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Submit & Connect WhatsApp
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('submit_inquiry_btn'),
                  icon: const Icon(Icons.chat, color: bgDark),
                  label: const Text('Start WhatsApp Chat', style: TextStyle(fontWeight: FontWeight.bold, color: bgDark)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emerald,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim().isEmpty ? 'Traveler' : nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    Navigator.pop(ctx);

                    if (widget.repository != null) {
                      await widget.repository!.recordWhatsAppClick(_package.slug, {
                        'traveler_name': name,
                        'traveler_phone': phone,
                        'guests_count': guests,
                      });
                    }

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening WhatsApp with ${_package.operator.name}...'),
                        backgroundColor: emerald,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _callOperator() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceDark,
        title: Text(_package.operator.name, style: const TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Accredited Tour Operator Helpline:', style: TextStyle(color: textSubtle, fontSize: 13)),
            const SizedBox(height: 8),
            SelectableText(
              _package.operator.phone,
              style: const TextStyle(color: emerald, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _package.operator.license,
              style: const TextStyle(color: textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: emerald),
            icon: const Icon(Icons.phone, size: 16, color: bgDark),
            label: const Text('Call', style: TextStyle(color: bgDark, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${_package.operator.name} at ${_package.operator.phone}...'),
                  backgroundColor: emerald,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _bookPackageDirectly() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceDark,
        title: const Text('Confirm Package Booking', style: TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_package.title, style: const TextStyle(color: emerald, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Operator: ${_package.operator.name}', style: const TextStyle(color: textMuted, fontSize: 12)),
            Text('Duration: ${_package.duration}', style: const TextStyle(color: textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            Text(
              'Total: ₹${_package.pricePerPerson.toInt()} / person',
              style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'A booking pass and instant inventory hold will be reserved for 15 minutes.',
              style: TextStyle(color: textSubtle, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            key: const Key('confirm_package_booking_btn'),
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Package reserved successfully! Digital voucher created.'),
                  backgroundColor: emerald,
                ),
              );
            },
            child: const Text('Confirm & Hold', style: TextStyle(color: bgDark, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Scrollable Content
          CustomScrollView(
            slivers: [
              // Hero App Bar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: surfaceDark,
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Color(0x99000000),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _package.heroImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.landscape, color: emerald, size: 64),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                              bgDark,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Package Details Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Duration & Category Pill
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: emerald),
                            ),
                            child: Text(
                              _package.duration,
                              style: const TextStyle(color: emerald, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: borderSubtle.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _package.category.replaceAll('_', ' '),
                              style: const TextStyle(color: textMuted, fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star, color: gold, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_package.rating} (${_package.reviewCount} reviews)',
                            style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Package Title
                      Text(
                        _package.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _package.tagline,
                        style: const TextStyle(color: textSubtle, fontSize: 13),
                      ),
                      const SizedBox(height: 18),

                      // Operator Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: emerald.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user, color: emerald, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _package.operator.name,
                                          style: const TextStyle(
                                            color: textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.verified, color: emerald, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _package.operator.license,
                                    style: const TextStyle(color: emerald, fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Zero platform markup • Direct operator rates',
                                    style: TextStyle(color: textSubtle, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Highlights
                      if (_package.highlights.isNotEmpty) ...[
                        const Text(
                          'Trip Highlights',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 10),
                        for (final h in _package.highlights)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle, color: emerald, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    h,
                                    style: const TextStyle(color: textMuted, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],

                      // Day by Day Itinerary
                      const Text(
                        'Day-by-Day Itinerary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 12),
                      for (final day in _package.itinerary) _buildItineraryDayCard(day),
                      const SizedBox(height: 20),

                      // Inclusions & Exclusions
                      _buildInclusionsCard(),
                      const SizedBox(height: 90), // Bottom bar clearance
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Fixed Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceDark,
                border: const Border(top: BorderSide(color: borderSubtle)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Price Pill
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Price per person', style: TextStyle(color: textSubtle, fontSize: 10)),
                        Text(
                          '₹${_package.pricePerPerson.toInt()}',
                          style: const TextStyle(
                            color: gold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // WhatsApp Chat Button
                    ElevatedButton.icon(
                      key: const Key('chat_whatsapp_btn'),
                      icon: const Icon(Icons.chat, size: 16, color: bgDark),
                      label: const Text('Chat', style: TextStyle(color: bgDark, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emerald,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _openInquiryModal,
                    ),
                    const SizedBox(width: 8),

                    // Call Operator Button
                    OutlinedButton.icon(
                      key: const Key('call_operator_btn'),
                      icon: const Icon(Icons.phone, size: 16, color: textPrimary),
                      label: const Text('Call', style: TextStyle(color: textPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: borderSubtle),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _callOperator,
                    ),
                    const SizedBox(width: 8),

                    // Book Direct Button
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('book_package_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _bookPackageDirectly,
                        child: const Text('Book', style: TextStyle(color: bgDark, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryDayCard(PackageDayItinerary day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: emerald,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DAY ${day.day}',
                  style: const TextStyle(color: bgDark, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  day.title,
                  style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            day.description,
            style: const TextStyle(color: textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.hotel_outlined, color: textSubtle, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  day.stay,
                  style: const TextStyle(color: textSubtle, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.restaurant_outlined, color: textSubtle, size: 14),
              const SizedBox(width: 4),
              Text(
                day.meals,
                style: const TextStyle(color: textSubtle, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inclusions & Exclusions', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          for (final inc in _package.inclusions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check, color: emerald, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(inc, style: const TextStyle(color: textMuted, fontSize: 12))),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Divider(color: borderSubtle),
          const SizedBox(height: 8),
          for (final exc in _package.exclusions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.close, color: AppTheme.emergencyRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(exc, style: const TextStyle(color: textSubtle, fontSize: 12))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
