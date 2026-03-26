import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/trip_plan.dart';
import '../../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripPlanningProvider>(context);
    final tripDetails = tripProvider.tripDetails;

    return Column(
      children: [
        // Trip Summary Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade100),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planning trip to ${tripDetails.destination}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      '${tripDetails.duration} days • ${tripDetails.travelers} traveler${tripDetails.travelers > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.blue.shade700,
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.flight_takeoff), text: 'Flights'),
              Tab(icon: Icon(Icons.hotel), text: 'Hotels'),
              Tab(icon: Icon(Icons.directions_car), text: 'Transport'),
              Tab(icon: Icon(Icons.explore), text: 'Activities'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              FlightBookingTab(tripDetails: tripDetails),
              HotelBookingTab(tripDetails: tripDetails),
              TransportBookingTab(tripDetails: tripDetails),
              ActivitiesBookingTab(tripDetails: tripDetails),
            ],
          ),
        ),

        // Selection Summary
        _buildSelectionSummary(tripProvider),
      ],
    );
  }

  Widget _buildSelectionSummary(TripPlanningProvider tripProvider) {
    final selectedServices = <String>[];
    if (tripProvider.selectedFlight != null) selectedServices.add('Flight');
    if (tripProvider.selectedHotel != null) selectedServices.add('Hotel');
    if (tripProvider.selectedTransport != null) selectedServices.add('Transport');
    selectedServices.add('${tripProvider.selectedLocalServices.length} Activities');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Services: ${selectedServices.join(', ')}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Estimated Cost: \$${tripProvider.currentTripPlan.totalCost.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// Flight Booking Tab
class FlightBookingTab extends StatefulWidget {
  final TripDetails tripDetails;

  const FlightBookingTab({super.key, required this.tripDetails});

  @override
  _FlightBookingTabState createState() => _FlightBookingTabState();
}

class _FlightBookingTabState extends State<FlightBookingTab> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<dynamic> _flights = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _flights = [];
    });

    try {
      final results = await _apiService.searchFlights(
        departure: widget.tripDetails.source.isEmpty
            ? 'Current Location'
            : widget.tripDetails.source,
        destination: widget.tripDetails.destination,
        date: widget.tripDetails.startDate.toIso8601String().split('T')[0],
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      // Parse the API response
      if (results.containsKey('flights')) {
        setState(() {
          _flights = results['flights'];
        });
      } else if (results.containsKey('data')) {
        setState(() {
          _flights = results['data'];
        });
      } else if (results.containsKey('search_results')) {
        // Handle different response structures
        final searchResults = results['search_results'];
        if (searchResults is List) {
          setState(() {
            _flights = searchResults;
          });
        }
      }

      if (_flights.isEmpty) {
        setState(() {
          _error = 'No flights found for your search criteria';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load flights: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripPlanningProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadFlights,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Summary Card
            _buildSearchSummary(),
            const SizedBox(height: 20),

            if (_isLoading) _buildLoadingState(),
            if (_error != null) _buildErrorState(),
            if (!_isLoading && _error == null) _buildFlightResults(tripProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.flight_takeoff, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Flight Search',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  'From',
                  widget.tripDetails.source.isEmpty
                      ? 'Current Location'
                      : widget.tripDetails.source,
                  Colors.blue,
                ),
                const Spacer(),
                _buildInfoChip('To', widget.tripDetails.destination, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoChip(
              'Date',
              _formatDate(widget.tripDetails.startDate),
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoChip('Travelers', '${widget.tripDetails.travelers}', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              'Searching for flights...',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Search Failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFlights,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightResults(TripPlanningProvider tripProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Flights (${_flights.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 16),

        if (_flights.isEmpty)
          _buildEmptyState()
        else
          ..._flights.map((flight) => _buildFlightCard(flight, tripProvider)),
      ],
    );
  }

  Widget _buildFlightCard(dynamic flightData, TripPlanningProvider tripProvider) {
    // Parse flight data from API response
    final flight = _parseFlightData(flightData);
    final isSelected = tripProvider.selectedFlight?.id == flight.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade600 : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _selectFlight(flight, tripProvider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.flight, color: Colors.blue.shade600, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      flight.details['flightNo'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(flight.details['departure'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(flight.details['arrival'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(flight.details['duration'] ?? '',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${flight.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    'per person',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Colors.green.shade600)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Select',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TripService _parseFlightData(dynamic flightData) {
    // Parse different API response structures
    if (flightData is Map<String, dynamic>) {
      return TripService(
        id: flightData['id'] ?? flightData['flight_number'] ?? UniqueKey().toString(),
        type: 'flight',
        name: flightData['airline'] ?? flightData['name'] ?? 'Flight',
        price: _parsePrice(flightData['price'] ?? flightData['cost']),
        details: {
          'airline': flightData['airline'],
          'flightNo': flightData['flight_number'],
          'departure': flightData['departure_time'],
          'arrival': flightData['arrival_time'],
          'duration': flightData['duration'],
          'class': flightData['class'] ?? 'Economy',
        },
      );
    }

    // Fallback for unexpected data format
    return TripService(
      id: UniqueKey().toString(),
      type: 'flight',
      name: 'Flight',
      price: 0.0,
      details: {},
    );
  }

  double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  void _selectFlight(TripService flight, TripPlanningProvider tripProvider) {
    tripProvider.selectFlight(flight);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.flight, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Flights Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your travel dates or destination',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFlights,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Search Again'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Hotel Booking Tab
class HotelBookingTab extends StatefulWidget {
  final TripDetails tripDetails;

  const HotelBookingTab({super.key, required this.tripDetails});

  @override
  _HotelBookingTabState createState() => _HotelBookingTabState();
}

class _HotelBookingTabState extends State<HotelBookingTab> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<dynamic> _hotels = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hotels = [];
    });

    try {
      final results = await _apiService.searchHotels(
        destination: widget.tripDetails.destination,
        checkin: widget.tripDetails.startDate.toIso8601String().split('T')[0],
        checkout: widget.tripDetails.endDate.toIso8601String().split('T')[0],
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      // Parse the API response
      if (results.containsKey('hotels')) {
        setState(() {
          _hotels = results['hotels'];
        });
      } else if (results.containsKey('data')) {
        setState(() {
          _hotels = results['data'];
        });
      } else if (results.containsKey('search_results')) {
        final searchResults = results['search_results'];
        if (searchResults is List) {
          setState(() {
            _hotels = searchResults;
          });
        }
      }

      if (_hotels.isEmpty) {
        setState(() {
          _error = 'No hotels found for your search criteria';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load hotels: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripPlanningProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadHotels,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchSummary(),
            const SizedBox(height: 20),

            if (_isLoading) _buildLoadingState(),
            if (_error != null) _buildErrorState(),
            if (!_isLoading && _error == null) _buildHotelResults(tripProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.hotel, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Hotel Search',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoChip('Location', widget.tripDetails.destination, Colors.green),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('Check-in', _formatDate(widget.tripDetails.startDate), Colors.green),
                const Spacer(),
                _buildInfoChip('Check-out', _formatDate(widget.tripDetails.endDate), Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoChip('Nights', '${widget.tripDetails.duration}', Colors.green),
            const SizedBox(height: 12),
            _buildInfoChip('Guests', '${widget.tripDetails.travelers}', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.green.shade700),
            const SizedBox(height: 16),
            Text(
              'Searching for hotels...',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Search Failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHotels,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelResults(TripPlanningProvider tripProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Hotels (${_hotels.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 16),

        if (_hotels.isEmpty)
          _buildEmptyState()
        else
          ..._hotels.map((hotel) => _buildHotelCard(hotel, tripProvider)),
      ],
    );
  }

  Widget _buildHotelCard(dynamic hotelData, TripPlanningProvider tripProvider) {
    final hotel = _parseHotelData(hotelData);
    final isSelected = tripProvider.selectedHotel?.id == hotel.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.green.shade600 : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _selectHotel(hotel, tripProvider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.hotel, color: Colors.green.shade600, size: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              hotel.details['rating']?.toString() ?? '0.0',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hotel.details['location'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (hotel.details['amenities'] != null)
                          Wrap(
                            spacing: 8,
                            children: (hotel.details['amenities'] as List).take(3).map((amenity) => Chip(
                              label: Text(amenity.toString()),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              labelStyle: const TextStyle(fontSize: 10),
                              padding: EdgeInsets.zero,
                            )).toList(),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${hotel.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'per night',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isSelected)
                        Icon(Icons.check_circle, color: Colors.green.shade600)
                      else
                        ElevatedButton(
                          onPressed: () => _selectHotel(hotel, tripProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('Select'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TripService _parseHotelData(dynamic hotelData) {
    if (hotelData is Map<String, dynamic>) {
      return TripService(
        id: hotelData['id'] ?? hotelData['hotel_id'] ?? UniqueKey().toString(),
        type: 'hotel',
        name: hotelData['name'] ?? hotelData['hotel_name'] ?? 'Hotel',
        price: _parsePrice(hotelData['price'] ?? hotelData['rate_per_night']),
        details: {
          'rating': hotelData['rating'] ?? hotelData['stars'],
          'location': hotelData['location'] ?? hotelData['address'],
          'amenities': hotelData['amenities'] ?? [],
          'checkIn': hotelData['check_in'] ?? '2:00 PM',
          'checkOut': hotelData['check_out'] ?? '12:00 PM',
        },
      );
    }

    return TripService(
      id: UniqueKey().toString(),
      type: 'hotel',
      name: 'Hotel',
      price: 0.0,
      details: {},
    );
  }

  double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  void _selectHotel(TripService hotel, TripPlanningProvider tripProvider) {
    tripProvider.selectHotel(hotel);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.hotel, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Hotels Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different dates or destination',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHotels,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Search Again'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Transport Booking Tab
class TransportBookingTab extends StatefulWidget {
  final TripDetails tripDetails;

  const TransportBookingTab({super.key, required this.tripDetails});

  @override
  _TransportBookingTabState createState() => _TransportBookingTabState();
}

class _TransportBookingTabState extends State<TransportBookingTab> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<dynamic> _transportOptions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransport();
  }

  Future<void> _loadTransport() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _transportOptions = [];
    });

    try {
      final results = await _apiService.searchTransportation(
        departure: widget.tripDetails.source.isEmpty
            ? 'Current Location'
            : widget.tripDetails.source,
        destination: widget.tripDetails.destination,
        date: widget.tripDetails.startDate.toIso8601String().split('T')[0],
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      // Parse the API response
      if (results.containsKey('transport')) {
        setState(() {
          _transportOptions = results['transport'];
        });
      } else if (results.containsKey('data')) {
        setState(() {
          _transportOptions = results['data'];
        });
      } else if (results.containsKey('search_results')) {
        final searchResults = results['search_results'];
        if (searchResults is List) {
          setState(() {
            _transportOptions = searchResults;
          });
        }
      }

      if (_transportOptions.isEmpty) {
        setState(() {
          _error = 'No transport options found for your search criteria';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load transport options: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripPlanningProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadTransport,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchSummary(),
            const SizedBox(height: 20),

            if (_isLoading) _buildLoadingState(),
            if (_error != null) _buildErrorState(),
            if (!_isLoading && _error == null) _buildTransportResults(tripProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.directions_car, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Transport Search',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  'From',
                  widget.tripDetails.source.isEmpty
                      ? 'Current Location'
                      : widget.tripDetails.source,
                  Colors.orange,
                ),
                const Spacer(),
                _buildInfoChip('To', widget.tripDetails.destination, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoChip('Date', _formatDate(widget.tripDetails.startDate), Colors.orange),
            const SizedBox(height: 12),
            _buildInfoChip('Travelers', '${widget.tripDetails.travelers}', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.orange.shade700),
            const SizedBox(height: 16),
            Text(
              'Searching for transport...',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Search Failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTransport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportResults(TripPlanningProvider tripProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transport Options (${_transportOptions.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
        const SizedBox(height: 16),

        if (_transportOptions.isEmpty)
          _buildEmptyState()
        else
          ..._transportOptions.map((transport) => _buildTransportCard(transport, tripProvider)),
      ],
    );
  }

  Widget _buildTransportCard(dynamic transportData, TripPlanningProvider tripProvider) {
    final transport = _parseTransportData(transportData);
    final isSelected = tripProvider.selectedTransport?.id == transport.id;

    IconData icon;
    Color color;

    switch (transport.details['type']?.toLowerCase()) {
      case 'train':
        icon = Icons.train;
        color = Colors.blue;
        break;
      case 'bus':
        icon = Icons.directions_bus;
        color = Colors.green;
        break;
      case 'cab':
        icon = Icons.local_taxi;
        color = Colors.orange;
        break;
      default:
        icon = Icons.directions;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _selectTransport(transport, tripProvider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transport.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      transport.details['type'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transport.details['description'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${transport.details['duration'] ?? ''}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${transport.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'per person',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Colors.green.shade600)
                  else
                    ElevatedButton(
                      onPressed: () => _selectTransport(transport, tripProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.withOpacity(0.1),
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Select'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TripService _parseTransportData(dynamic transportData) {
    if (transportData is Map<String, dynamic>) {
      return TripService(
        id: transportData['id'] ?? transportData['transport_id'] ?? UniqueKey().toString(),
        type: transportData['type']?.toLowerCase() ?? 'transport',
        name: transportData['name'] ?? transportData['service_name'] ?? 'Transport',
        price: _parsePrice(transportData['price'] ?? transportData['fare']),
        details: {
          'type': transportData['type'],
          'duration': transportData['duration'],
          'description': transportData['description'],
          'departure': transportData['departure_time'],
          'arrival': transportData['arrival_time'],
        },
      );
    }

    return TripService(
      id: UniqueKey().toString(),
      type: 'transport',
      name: 'Transport',
      price: 0.0,
      details: {},
    );
  }

  double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  void _selectTransport(TripService transport, TripPlanningProvider tripProvider) {
    tripProvider.selectTransport(transport);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Transport Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different dates or destination',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTransport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Search Again'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Activities Booking Tab
class ActivitiesBookingTab extends StatefulWidget {
  final TripDetails tripDetails;

  const ActivitiesBookingTab({super.key, required this.tripDetails});

  @override
  _ActivitiesBookingTabState createState() => _ActivitiesBookingTabState();
}

class _ActivitiesBookingTabState extends State<ActivitiesBookingTab> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _activityResults;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _apiService.getTravelGuide(widget.tripDetails.destination)
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      setState(() {
        _activityResults = results;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load activities: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripPlanningProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchSummary(),
            const SizedBox(height: 20),

            if (_isLoading) _buildLoadingState(),
            if (_error != null) _buildErrorState(),
            if (!_isLoading && _error == null) _buildActivityResults(tripProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.explore, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Activities & Experiences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoChip('Destination', widget.tripDetails.destination, Colors.purple),
            const SizedBox(height: 12),
            _buildInfoChip('Trip Style', widget.tripDetails.tripType, Colors.purple),
            const SizedBox(height: 12),
            _buildInfoChip('Duration', '${widget.tripDetails.duration} days', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.purple.shade700),
            const SizedBox(height: 16),
            Text(
              'Loading activities...',
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Load Failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadActivities,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityResults(TripPlanningProvider tripProvider) {
    final youtubeLinks = _activityResults?['youtube_links_md']?.toString() ?? '';
    final googleEarthLink = _activityResults?['google_earth_link']?.toString() ?? '';
    final activities = _parseActivitiesFromResponse(_activityResults);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Guide - ${widget.tripDetails.destination}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // Google Earth Link
        if (googleEarthLink.isNotEmpty)
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.public, color: Colors.purple.shade600),
              title: const Text('Explore on Google Earth'),
              subtitle: const Text('Virtual tour of the destination'),
              trailing: Icon(Icons.open_in_new, color: Colors.purple.shade600),
              onTap: () {
                // Implement Google Earth link opening
              },
            ),
          ),

        const SizedBox(height: 16),

        // YouTube Links
        if (youtubeLinks.isNotEmpty)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video Guides',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    youtubeLinks.length > 150
                        ? '${youtubeLinks.substring(0, 150)}...'
                        : youtubeLinks,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),
        Text(
          'Popular Activities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        if (activities.isEmpty)
          _buildEmptyState()
        else
          ...activities.map((activity) => _buildActivityCard(activity, tripProvider)),
      ],
    );
  }

  List<TripService> _parseActivitiesFromResponse(Map<String, dynamic>? response) {
    final activities = <TripService>[];

    if (response == null) return activities;

    // Parse activities from different response structures
    if (response.containsKey('activities')) {
      final activityList = response['activities'];
      if (activityList is List) {
        for (var activityData in activityList) {
          activities.add(_parseActivityData(activityData));
        }
      }
    } else if (response.containsKey('recommendations')) {
      final recommendations = response['recommendations'];
      if (recommendations is List) {
        for (var rec in recommendations) {
          activities.add(_parseActivityData(rec));
        }
      }
    }

    return activities;
  }

  TripService _parseActivityData(dynamic activityData) {
    if (activityData is Map<String, dynamic>) {
      return TripService(
        id: activityData['id'] ?? activityData['activity_id'] ?? UniqueKey().toString(),
        type: 'activity',
        name: activityData['name'] ?? activityData['activity_name'] ?? 'Activity',
        price: _parsePrice(activityData['price'] ?? activityData['cost']),
        details: {
          'duration': activityData['duration'],
          'type': activityData['type'],
          'description': activityData['description'],
          'includes': activityData['includes'] ?? [],
        },
      );
    }

    return TripService(
      id: UniqueKey().toString(),
      type: 'activity',
      name: 'Activity',
      price: 0.0,
      details: {},
    );
  }

  double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  Widget _buildActivityCard(TripService activity, TripPlanningProvider tripProvider) {
    final isSelected = tripProvider.selectedLocalServices.any((s) => s.id == activity.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.purple.shade600 : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleActivity(activity, tripProvider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.explore, color: Colors.purple.shade600, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      activity.details['description'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${activity.details['duration'] ?? ''}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${activity.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  Text(
                    'per person',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleActivity(activity, tripProvider),
                    activeColor: Colors.purple.shade600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleActivity(TripService activity, TripPlanningProvider tripProvider) {
    tripProvider.toggleLocalService(activity);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.explore, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Activities Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different destination',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadActivities,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}