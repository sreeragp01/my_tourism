import 'package:flutter/material.dart';
import '../data/transport_repository.dart';
import '../models/transport_models.dart';
import 'cab_pass_screen.dart';

class CabBookingScreen extends StatefulWidget {
  final ITransportRepository? repository;
  final String? initialAirport;
  final String? initialDestination;

  const CabBookingScreen({
    super.key,
    this.repository,
    this.initialAirport,
    this.initialDestination,
  });

  @override
  State<CabBookingScreen> createState() => _CabBookingScreenState();
}

class _CabBookingScreenState extends State<CabBookingScreen> {
  late final ITransportRepository _repo;

  // Booking mode: 'AIRPORT' or 'DAILY_RENTAL'
  String _bookingMode = 'AIRPORT';

  bool _isLoading = true;
  bool _isSubmitting = false;

  List<VehicleCategory> _vehicles = [];
  List<AirportRoute> _routes = [];

  String _selectedAirport = 'COK';
  AirportRoute? _selectedRoute;
  VehicleCategory? _selectedVehicle;

  // Form Controllers
  final TextEditingController _nameController =
      TextEditingController(text: 'Traveler');
  final TextEditingController _phoneController =
      TextEditingController(text: '+91 94470 12345');
  final TextEditingController _flightNumberController =
      TextEditingController(text: 'EK 530');
  final TextEditingController _nameboardController =
      TextEditingController(text: 'Welcome to Kerala');
  final TextEditingController _pickupLocationController =
      TextEditingController(text: 'Cochin International Airport (COK)');
  final TextEditingController _dropLocationController =
      TextEditingController(text: 'Munnar Hill Station');
  final TextEditingController _specialNotesController = TextEditingController();

  DateTime _pickupDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _pickupTime = const TimeOfDay(hour: 14, minute: 30);
  int _rentalDays = 3;
  int _passengerCount = 2;
  int _luggageCount = 2;

  final List<Map<String, String>> _airports = const [
    {'code': 'COK', 'name': 'Cochin / Kochi (COK)', 'city': 'Nedumbassery'},
    {'code': 'TRV', 'name': 'Trivandrum (TRV)', 'city': 'Thiruvananthapuram'},
    {'code': 'CCJ', 'name': 'Calicut (CCJ)', 'city': 'Kozhikode'},
    {'code': 'CNN', 'name': 'Kannur (CNN)', 'city': 'Mattannur'},
  ];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? TransportRepository();
    if (widget.initialAirport != null) {
      _selectedAirport = widget.initialAirport!;
    }
    _fetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _flightNumberController.dispose();
    _nameboardController.dispose();
    _pickupLocationController.dispose();
    _dropLocationController.dispose();
    _specialNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final vehiclesFuture = _repo.getVehicles();
      final routesFuture = _repo.getAirportRoutes(airport: _selectedAirport);

      final results = await Future.wait([vehiclesFuture, routesFuture]);
      final vehicles = results[0] as List<VehicleCategory>;
      final routes = results[1] as List<AirportRoute>;

      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _routes = routes;
          if (_vehicles.isNotEmpty) {
            // Prefer Innova Crysta or first vehicle
            _selectedVehicle = _vehicles.firstWhere(
              (v) => v.vehicleType == 'SUV_PREMIUM',
              orElse: () => _vehicles.first,
            );
          }
          if (_routes.isNotEmpty) {
            _selectedRoute = _routes.firstWhere(
              (r) =>
                  widget.initialDestination != null &&
                  r.destinationName
                      .toLowerCase()
                      .contains(widget.initialDestination!.toLowerCase()),
              orElse: () => _routes.first,
            );
            _updateDropFromRoute();
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onAirportChanged(String airportCode) async {
    setState(() {
      _selectedAirport = airportCode;
      _pickupLocationController.text =
          _airports.firstWhere((a) => a['code'] == airportCode)['name'] ??
              airportCode;
      _isLoading = true;
    });

    try {
      final routes = await _repo.getAirportRoutes(airport: airportCode);
      if (mounted) {
        setState(() {
          _routes = routes;
          _selectedRoute = routes.isNotEmpty ? routes.first : null;
          _updateDropFromRoute();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateDropFromRoute() {
    if (_selectedRoute != null) {
      _dropLocationController.text =
          '${_selectedRoute!.destinationName} (${_selectedRoute!.district})';
    }
  }

  double _calculateTotalFare() {
    if (_selectedVehicle == null) return 0.0;

    if (_bookingMode == 'AIRPORT') {
      if (_selectedRoute != null) {
        switch (_selectedVehicle!.vehicleType) {
          case 'SEDAN_AC':
            return _selectedRoute!.sedanFare;
          case 'SUV_PREMIUM':
            return _selectedRoute!.suvCrystaFare;
          case 'TEMPO_TRAVELLER':
            return _selectedRoute!.tempoFare;
          case 'EV_ELECTRIC':
            return _selectedRoute!.sedanFare * 0.95;
          default:
            return _selectedRoute!.sedanFare;
        }
      }
      return 3500.0;
    } else {
      // Multi-day rental
      final dailyRate = _selectedVehicle!.dailyRentalRate;
      final bata = _selectedVehicle!.driverBataPerDay;
      return (dailyRate + bata) * _rentalDays;
    }
  }

  Future<void> _handleBookCab() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final totalFare = _calculateTotalFare();
    final pickupDateStr =
        '${_pickupDate.year}-${_pickupDate.month.toString().padLeft(2, '0')}-${_pickupDate.day.toString().padLeft(2, '0')}';
    final pickupTimeStr =
        '${_pickupTime.hour.toString().padLeft(2, '0')}:${_pickupTime.minute.toString().padLeft(2, '0')}';

    final payload = <String, dynamic>{
      'booking_type': _bookingMode,
      'traveler_name': _nameController.text.trim(),
      'traveler_phone': _phoneController.text.trim(),
      'vehicle_category': _selectedVehicle?.id ?? '',
      'pickup_location': _pickupLocationController.text.trim(),
      'drop_location': _dropLocationController.text.trim(),
      'pickup_date': pickupDateStr,
      'pickup_time': pickupTimeStr,
      'days_count': _bookingMode == 'AIRPORT' ? 1 : _rentalDays,
      'passenger_count': _passengerCount,
      'luggage_count': _luggageCount,
      'flight_number':
          _bookingMode == 'AIRPORT' ? _flightNumberController.text.trim() : '',
      'nameboard_text':
          _bookingMode == 'AIRPORT' ? _nameboardController.text.trim() : '',
      'flight_delayed_protection': true,
      'total_fare': totalFare,
      'special_notes': _specialNotesController.text.trim(),
    };

    try {
      final bookingResult = await _repo.createCabBooking(payload);

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CabPassScreen(booking: bookingResult),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0D1F17);
    const cardBg = Color(0xFF142B20);
    const primaryEmerald = Color(0xFF10B981);
    const textCream = Color(0xFFF7F3E8);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textCream),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kerala Tourist Cabs & Chauffeurs',
              style: TextStyle(
                color: textCream,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Verified Airport Pickups • Ghat Road Specialists',
              style: TextStyle(color: Color(0xFF9EBAAA), fontSize: 11),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryEmerald),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Guarantee Banner
                  _buildGuaranteeBanner(),

                  // Booking Mode Switcher
                  _buildModeSwitcher(),

                  // Form Fields based on Mode
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_bookingMode == 'AIRPORT')
                          _buildAirportTransferSection()
                        else
                          _buildMultiDayRentalSection(),

                        const SizedBox(height: 20),

                        // Date & Time Picker
                        _buildDateTimeSection(),

                        const SizedBox(height: 20),

                        // Vehicle Selection
                        _buildVehicleSelection(),

                        const SizedBox(height: 20),

                        // Traveler Details
                        _buildTravelerDetailsSection(),

                        const SizedBox(height: 20),

                        // Transparent Fare Inclusions
                        _buildInclusionsCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomSheet: _isLoading ? null : _buildStickyBottomBar(),
    );
  }

  Widget _buildGuaranteeBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A2B), Color(0xFF142B20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E5A44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pre-Book Before Landing in Kerala',
                      style: TextStyle(
                        color: Color(0xFFF7F3E8),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Avoid taxi negotiations, airport queues & language barriers',
                      style: TextStyle(color: Color(0xFFC5D8CD), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _Badge(icon: Icons.flight_land, label: 'Real-Time Flight Tracking'),
              _Badge(icon: Icons.badge, label: 'Name Placard at Arrival Gate'),
              _Badge(icon: Icons.timer, label: '90 Min Free Delay Wait'),
              _Badge(icon: Icons.terrain, label: 'Hill & Ghat Road Certified'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF142B20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A4D3B)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('mode_airport_transfer'),
              onTap: () => setState(() => _bookingMode = 'AIRPORT'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _bookingMode == 'AIRPORT'
                      ? const Color(0xFF10B981)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flight_land,
                        size: 18,
                        color: _bookingMode == 'AIRPORT'
                            ? Colors.black
                            : const Color(0xFFC5D8CD),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Airport Transfer',
                        style: TextStyle(
                          color: _bookingMode == 'AIRPORT'
                              ? Colors.black
                              : const Color(0xFFC5D8CD),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              key: const Key('mode_daily_rental'),
              onTap: () => setState(() => _bookingMode = 'DAILY_RENTAL'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _bookingMode == 'DAILY_RENTAL'
                      ? const Color(0xFF10B981)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 18,
                        color: _bookingMode == 'DAILY_RENTAL'
                            ? Colors.black
                            : const Color(0xFFC5D8CD),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kerala Chauffeur Tour',
                        style: TextStyle(
                          color: _bookingMode == 'DAILY_RENTAL'
                              ? Colors.black
                              : const Color(0xFFC5D8CD),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirportTransferSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Arrival Airport',
          style: TextStyle(
            color: Color(0xFFF7F3E8),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _airports.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final airport = _airports[index];
              final isSelected = _selectedAirport == airport['code'];
              return ChoiceChip(
                key: Key('airport_chip_${airport['code']}'),
                label: Text(
                  '${airport['code']} - ${airport['city']}',
                  style: TextStyle(
                    color: isSelected ? Colors.black : const Color(0xFFF7F3E8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFF142B20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : const Color(0xFF2A4D3B),
                ),
                onSelected: (selected) {
                  if (selected) _onAirportChanged(airport['code']!);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Destination Drop-off Route Selector
        const Text(
          'Select Destination Route',
          style: TextStyle(
            color: Color(0xFFF7F3E8),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (_routes.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF142B20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'No direct fixed routes found for this airport. Custom pickup available.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF142B20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A4D3B)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AirportRoute>(
                value: _selectedRoute,
                isExpanded: true,
                dropdownColor: const Color(0xFF142B20),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF10B981)),
                items: _routes.map((route) {
                  return DropdownMenuItem<AirportRoute>(
                    value: route,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${route.destinationName} (${route.district})',
                            style: const TextStyle(
                              color: Color(0xFFF7F3E8),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${route.distanceKm} km • ${route.approxDurationHours}h',
                          style: const TextStyle(
                            color: Color(0xFF9EBAAA),
                            fontSize: 11,
                          ),
                        ),
                        if (route.isGhatRoad) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '⛰️ Ghats',
                              style: TextStyle(
                                  color: Color(0xFFF59E0B), fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newRoute) {
                  if (newRoute != null) {
                    setState(() {
                      _selectedRoute = newRoute;
                      _updateDropFromRoute();
                    });
                  }
                },
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Flight Number & Nameboard Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF142B20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A4D3B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flight_takeoff,
                      color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Flight & Arrival Gate Details',
                    style: TextStyle(
                      color: Color(0xFFF7F3E8),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Live Radar Sync',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildTextField(
                      controller: _flightNumberController,
                      label: 'Flight Number',
                      hint: 'e.g. EK 530, QR 516',
                      keyName: 'flight_number_field',
                      icon: Icons.confirmation_number_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: _buildTextField(
                      controller: _nameboardController,
                      label: 'Placard Nameboard',
                      hint: 'e.g. Welcome Mr. David',
                      keyName: 'nameboard_field',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Chauffeur will hold this placard at the arrival exit barrier.',
                style: TextStyle(color: Color(0xFF9EBAAA), fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultiDayRentalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF142B20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A4D3B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.map, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Multi-Day Dedicated Chauffeur Itinerary',
                    style: TextStyle(
                      color: Color(0xFFF7F3E8),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _pickupLocationController,
                label: 'Starting City / Airport / Hotel',
                hint: 'e.g. Kochi Airport / Fort Kochi Hotel',
                keyName: 'pickup_location_field',
                icon: Icons.trip_origin,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _dropLocationController,
                label: 'Final Drop-off Destination',
                hint: 'e.g. Trivandrum Airport / Kovalam',
                keyName: 'drop_location_field',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Tour Duration',
                        style: TextStyle(
                          color: Color(0xFFF7F3E8),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Vehicle & driver with you all days',
                        style: TextStyle(color: Color(0xFF9EBAAA), fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F17),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A4D3B)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove,
                              color: Color(0xFF10B981), size: 18),
                          onPressed: () {
                            if (_rentalDays > 1) {
                              setState(() => _rentalDays--);
                            }
                          },
                        ),
                        Text(
                          '$_rentalDays Days',
                          style: const TextStyle(
                            color: Color(0xFFF7F3E8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add,
                              color: Color(0xFF10B981), size: 18),
                          onPressed: () {
                            if (_rentalDays < 21) {
                              setState(() => _rentalDays++);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF142B20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A4D3B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Schedule & Passengers',
            style: TextStyle(
              color: Color(0xFFF7F3E8),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F17),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A4D3B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date',
                                  style: TextStyle(
                                      color: Color(0xFF9EBAAA), fontSize: 10)),
                              Text(
                                '${_pickupDate.day}/${_pickupDate.month}/${_pickupDate.year}',
                                style: const TextStyle(
                                  color: Color(0xFFF7F3E8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F17),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A4D3B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pickup Time',
                                  style: TextStyle(
                                      color: Color(0xFF9EBAAA), fontSize: 10)),
                              Text(
                                _pickupTime.format(context),
                                style: const TextStyle(
                                  color: Color(0xFFF7F3E8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_outlined,
                        color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Passengers: $_passengerCount',
                      style: const TextStyle(
                          color: Color(0xFFF7F3E8), fontSize: 12),
                    ),
                    const Spacer(),
                    _MiniStepper(
                      value: _passengerCount,
                      min: 1,
                      max: 16,
                      onChanged: (val) => setState(() => _passengerCount = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.luggage_outlined,
                        color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Luggage: $_luggageCount',
                      style: const TextStyle(
                          color: Color(0xFFF7F3E8), fontSize: 12),
                    ),
                    const Spacer(),
                    _MiniStepper(
                      value: _luggageCount,
                      min: 0,
                      max: 20,
                      onChanged: (val) => setState(() => _luggageCount = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Select Chauffeur Vehicle',
              style: TextStyle(
                color: Color(0xFFF7F3E8),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Spacer(),
            Text(
              'Hill-Certified Fleet',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _vehicles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final vehicle = _vehicles[index];
            final isSelected = _selectedVehicle?.id == vehicle.id ||
                (_selectedVehicle == null && index == 0);

            // Calculate cost for this vehicle
            double fare = 0;
            if (_bookingMode == 'AIRPORT') {
              if (_selectedRoute != null) {
                switch (vehicle.vehicleType) {
                  case 'SEDAN_AC':
                    fare = _selectedRoute!.sedanFare;
                    break;
                  case 'SUV_PREMIUM':
                    fare = _selectedRoute!.suvCrystaFare;
                    break;
                  case 'TEMPO_TRAVELLER':
                    fare = _selectedRoute!.tempoFare;
                    break;
                  case 'EV_ELECTRIC':
                    fare = _selectedRoute!.sedanFare * 0.95;
                    break;
                  default:
                    fare = _selectedRoute!.sedanFare;
                }
              } else {
                fare = 3500;
              }
            } else {
              fare = (vehicle.dailyRentalRate + vehicle.driverBataPerDay) *
                  _rentalDays;
            }

            return InkWell(
              key: Key('vehicle_card_${vehicle.vehicleType}'),
              onTap: () => setState(() => _selectedVehicle = vehicle),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E3A2B)
                      : const Color(0xFF142B20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : const Color(0xFF2A4D3B),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon / Vehicle Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : const Color(0xFF0D1F17),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          _getVehicleIcon(vehicle.vehicleType),
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.white70,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vehicle.name,
                                  style: const TextStyle(
                                    color: Color(0xFFF7F3E8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (vehicle.vehicleType == 'SUV_PREMIUM') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Top Choice',
                                    style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vehicle.tagline,
                            style: const TextStyle(
                              color: Color(0xFF9EBAAA),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people,
                                      size: 13,
                                      color: isSelected
                                          ? const Color(0xFF10B981)
                                          : Colors.white60),
                                  const SizedBox(width: 3),
                                  Text('${vehicle.passengerCapacity} Seats',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.luggage,
                                      size: 13,
                                      color: isSelected
                                          ? const Color(0xFF10B981)
                                          : Colors.white60),
                                  const SizedBox(width: 3),
                                  Text('${vehicle.luggageCapacity} Bags',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.ac_unit,
                                      size: 13, color: Colors.lightBlueAccent),
                                  SizedBox(width: 3),
                                  Text('AC',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${fare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _bookingMode == 'AIRPORT'
                              ? 'Fixed Flat Rate'
                              : 'for $_rentalDays Days',
                          style: const TextStyle(
                              color: Color(0xFF9EBAAA), fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTravelerDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF142B20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A4D3B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_phone, color: Color(0xFF10B981), size: 18),
              SizedBox(width: 8),
              Text(
                'Traveler Contact & WhatsApp',
                style: TextStyle(
                  color: Color(0xFFF7F3E8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _nameController,
            label: 'Lead Passenger Full Name',
            hint: 'e.g. Sreerag Pillai',
            keyName: 'traveler_name_field',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            label: 'WhatsApp / Phone Number (Include Country Code)',
            hint: 'e.g. +971 50 1234567 or +91 94470 12345',
            keyName: 'traveler_phone_field',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _specialNotesController,
            label: 'Special Requests (Optional)',
            hint: 'e.g. Child car seat needed, mountain motion sickness care',
            keyName: 'special_notes_field',
            icon: Icons.notes,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A4D3B)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: Color(0xFF10B981), size: 18),
              SizedBox(width: 8),
              Text(
                'Transparent Kerala Tourism Guarantee',
                style: TextStyle(
                  color: Color(0xFFF7F3E8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _InclusionRow(
              text: 'Includes all highway tolls, airport parking & fuel charges'),
          _InclusionRow(
              text: 'Driver daily bata (allowance) & food expenses included'),
          _InclusionRow(
              text: 'Police-verified tourist chauffeur with 10+ years ghat experience'),
          _InclusionRow(
              text: 'Free cancellation up to 6 hours before scheduled flight arrival'),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    final fare = _calculateTotalFare();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF142B20),
        boxShadow: [
          BoxStyle.boxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: Color(0xFF2A4D3B))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL ALL-INCLUSIVE',
                  style: TextStyle(
                    color: Color(0xFF9EBAAA),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '₹${fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const Text(
                  'Zero surge • Taxes included',
                  style: TextStyle(color: Color(0xFFC5D8CD), fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                key: const Key('reserve_cab_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _isSubmitting ? null : _handleBookCab,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Reserve Cab & Chauffeur',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String keyName,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9EBAAA), fontSize: 11),
        ),
        const SizedBox(height: 6),
        TextField(
          key: Key(keyName),
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFFF7F3E8), fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
            prefixIcon: Icon(icon, color: const Color(0xFF10B981), size: 18),
            filled: true,
            fillColor: const Color(0xFF0D1F17),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2A4D3B)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2A4D3B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.black,
              surface: Color(0xFF142B20),
              onSurface: Color(0xFFF7F3E8),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _pickupDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.black,
              surface: Color(0xFF142B20),
              onSurface: Color(0xFFF7F3E8),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _pickupTime = picked);
    }
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'SEDAN_AC':
        return Icons.directions_car;
      case 'SUV_PREMIUM':
        return Icons.airport_shuttle;
      case 'TEMPO_TRAVELLER':
        return Icons.directions_bus;
      case 'EV_ELECTRIC':
        return Icons.electric_car;
      default:
        return Icons.local_taxi;
    }
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFF7F3E8), fontSize: 11),
        ),
      ],
    );
  }
}

class _MiniStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _MiniStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F17),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A4D3B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: value > min ? () => onChanged(value - 1) : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.remove, size: 14, color: Color(0xFF10B981)),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
                color: Color(0xFFF7F3E8),
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
          InkWell(
            onTap: value < max ? () => onChanged(value + 1) : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.add, size: 14, color: Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InclusionRow extends StatelessWidget {
  final String text;

  const _InclusionRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check, size: 14, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class BoxStyle {
  static BoxShadow boxShadow({
    required Color color,
    required double blurRadius,
    required Offset offset,
  }) {
    return BoxShadow(color: color, blurRadius: blurRadius, offset: offset);
  }
}
