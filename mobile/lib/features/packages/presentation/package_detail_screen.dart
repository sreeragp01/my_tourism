import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFF142B20),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF7F3E8)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Direct inquiry to ${_package.operator.name}',
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextField(
                key: const Key('inquiry_name_field'),
                controller: nameCtrl,
                style: const TextStyle(color: Color(0xFFF7F3E8)),
                decoration: InputDecoration(
                  labelText: 'Your Full Name',
                  labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFF0D1F17),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              // Phone Field
              TextField(
                key: const Key('inquiry_phone_field'),
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Color(0xFFF7F3E8)),
                decoration: InputDecoration(
                  labelText: 'Phone / WhatsApp Number',
                  labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFF0D1F17),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              // Guests Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Number of Travelers:', style: TextStyle(color: Color(0xFFF7F3E8), fontSize: 14)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF10B981)),
                        onPressed: () {
                          if (guests > 1) setModalState(() => guests--);
                        },
                      ),
                      Text('$guests', style: const TextStyle(color: Color(0xFFF7F3E8), fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
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
                  icon: const Icon(Icons.chat, color: Color(0xFF0D1F17)),
                  label: const Text('Start WhatsApp Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D1F17))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
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
                        backgroundColor: const Color(0xFF10B981),
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
        backgroundColor: const Color(0xFF142B20),
        title: Text(_package.operator.name, style: const TextStyle(color: Color(0xFFF7F3E8))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Accredited Tour Operator Helpline:', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            const SizedBox(height: 8),
            SelectableText(
              _package.operator.phone,
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _package.operator.license,
              style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            icon: const Icon(Icons.phone, size: 16, color: Color(0xFF0D1F17)),
            label: const Text('Call', style: TextStyle(color: Color(0xFF0D1F17), fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${_package.operator.name} at ${_package.operator.phone}...'),
                  backgroundColor: const Color(0xFF10B981),
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
        backgroundColor: const Color(0xFF142B20),
        title: const Text('Confirm Package Booking', style: TextStyle(color: Color(0xFFF7F3E8))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_package.title, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Operator: ${_package.operator.name}', style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 12)),
            Text('Duration: ${_package.duration}', style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 12)),
            const SizedBox(height: 12),
            Text(
              'Total: ₹${_package.pricePerPerson.toInt()} / person',
              style: const TextStyle(color: Color(0xFFF7F3E8), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'A booking pass and instant inventory hold will be reserved for 15 minutes.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            key: const Key('confirm_package_booking_btn'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Package reserved successfully! Digital voucher created.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Confirm & Hold', style: TextStyle(color: Color(0xFF0D1F17), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F17),
      body: Stack(
        children: [
          // Scrollable Content
          CustomScrollView(
            slivers: [
              // Hero App Bar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF142B20),
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
                          child: Icon(Icons.landscape, color: Color(0xFF10B981), size: 64),
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
                              const Color(0xFF0D1F17),
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
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: Text(
                              _package.duration,
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D5A43).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _package.category.replaceAll('_', ' '),
                              style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_package.rating} (${_package.reviewCount} reviews)',
                            style: const TextStyle(color: Color(0xFFF7F3E8), fontWeight: FontWeight.bold, fontSize: 12),
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
                          color: Color(0xFFF7F3E8),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _package.tagline,
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                      ),
                      const SizedBox(height: 18),

                      // Operator Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF142B20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2D5A43)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user, color: Color(0xFF10B981), size: 26),
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
                                            color: Color(0xFFF7F3E8),
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _package.operator.license,
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Zero platform markup • Direct operator rates',
                                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF7F3E8)),
                        ),
                        const SizedBox(height: 10),
                        for (final h in _package.highlights)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    h,
                                    style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 13),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF7F3E8)),
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
                color: const Color(0xFF142B20),
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
                        const Text('Price per person', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                        Text(
                          '₹${_package.pricePerPerson.toInt()}',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
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
                      icon: const Icon(Icons.chat, size: 16, color: Color(0xFF0D1F17)),
                      label: const Text('Chat', style: TextStyle(color: Color(0xFF0D1F17), fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _openInquiryModal,
                    ),
                    const SizedBox(width: 8),

                    // Call Operator Button
                    OutlinedButton.icon(
                      key: const Key('call_operator_btn'),
                      icon: const Icon(Icons.phone, size: 16, color: Color(0xFFF7F3E8)),
                      label: const Text('Call', style: TextStyle(color: Color(0xFFF7F3E8))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2D5A43)),
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
                          backgroundColor: const Color(0xFFD4AF37),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _bookPackageDirectly,
                        child: const Text('Book', style: TextStyle(color: Color(0xFF0D1F17), fontWeight: FontWeight.bold)),
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
        color: const Color(0xFF142B20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D5A43)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DAY ${day.day}',
                  style: const TextStyle(color: Color(0xFF0D1F17), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  day.title,
                  style: const TextStyle(color: Color(0xFFF7F3E8), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            day.description,
            style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.hotel_outlined, color: Color(0xFF9CA3AF), size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  day.stay,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.restaurant_outlined, color: Color(0xFF9CA3AF), size: 14),
              const SizedBox(width: 4),
              Text(
                day.meals,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
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
        color: const Color(0xFF142B20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D5A43)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inclusions & Exclusions', style: TextStyle(color: Color(0xFFF7F3E8), fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          for (final inc in _package.inclusions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(inc, style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 12))),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF2D5A43)),
          const SizedBox(height: 8),
          for (final exc in _package.exclusions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(exc, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
