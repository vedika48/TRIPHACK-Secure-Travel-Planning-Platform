import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/trip_plan.dart';
import '../../providers/trip_provider.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  _MyTripsScreenState createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TripPlan> _allTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId != null) {
        final trips = await tripProvider.getUserTripPlans(userId);
        if (mounted) {
          setState(() {
            _allTrips = trips;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trips: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var favoriteTrips = _allTrips.where((trip) => trip.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Trips',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Trips'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTripsList(_allTrips, 'You haven\'t planned any trips yet.'),
                _buildTripsList(favoriteTrips, 'You don\'t have any favorite trips yet.'),
              ],
            ),
    );
  }

  Widget _buildTripsList(List<TripPlan> trips, String emptyMessage) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return _buildTripCard(trips[index]);
        },
      ),
    );
  }

  Widget _buildTripCard(TripPlan trip) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Future enhancement: navigate to specific trip details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      trip.details.destination,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      trip.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: trip.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () async {
                      try {
                        final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
                        await tripProvider.toggleFavorite(trip);
                        await _loadTrips(); // Reload to refresh lists
                      } catch (e) {
                         // handle silently
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${dateFormat.format(trip.details.startDate)} - ${dateFormat.format(trip.details.endDate)}',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people_rounded, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${trip.details.travelers} traveler${trip.details.travelers > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const Spacer(),
                  Text(
                    '\$${trip.totalCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (trip.flight != null) _buildServiceChip(Icons.flight, 'Flight'),
                  if (trip.hotel != null) _buildServiceChip(Icons.hotel, 'Hotel'),
                  if (trip.transport != null) _buildServiceChip(Icons.directions_car, 'Transport'),
                  if (trip.localServices.isNotEmpty) 
                    _buildServiceChip(Icons.explore, '${trip.localServices.length} Activities'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.blue.shade700),
      label: Text(label, style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
      backgroundColor: Colors.blue.shade50,
      visualDensity: VisualDensity.compact,
    );
  }
}
