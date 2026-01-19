import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import 'trip_details_screen.dart';
import 'booking_screen.dart';

class TripPlanningScreen extends StatefulWidget {
  const TripPlanningScreen({super.key});

  @override
  _TripPlanningScreenState createState() => _TripPlanningScreenState();
}

class _TripPlanningScreenState extends State<TripPlanningScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = [
    const TripDetailsScreen(),
    const BookingScreen(),
  ];

  final List<String> _pageTitles = [
    'Trip Details',
    'Book Your Trip'
  ];

  final List<String> _pageSubtitles = [
    'Tell us about your journey',
    'Search and book flights, hotels, transport & more'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pageTitles[_currentPage],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _pageSubtitles[_currentPage],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: _getPageColor(_currentPage),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        leading: _currentPage > 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _previousPage(),
        )
            : null,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_pages.length, (index) {
                    final isActive = index <= _currentPage;
                    return Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? _getPageColor(index)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          if (index < _pages.length - 1) const SizedBox(width: 4),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_pages.length, (index) {
                    final isActive = index == _currentPage;
                    return GestureDetector(
                      onTap: () => _goToPage(index),
                      child: Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? _getPageColor(index)
                                  : index < _currentPage
                                  ? _getPageColor(index)
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: index < _currentPage
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: Text(
                              _pageTitles[index].split(' ').first,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive ? _getPageColor(index) : Colors.grey.shade600,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Consumer<TripPlanningProvider>(
          builder: (context, tripProvider, child) {
            return Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: tripProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                    onPressed: _nextPage,
                    icon: Icon(_currentPage == _pages.length - 1
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded),
                    label: Text(
                      _currentPage == _pages.length - 1 ? 'Save Trip Plan' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getPageColor(_currentPage),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getPageColor(int pageIndex) {
    switch (pageIndex) {
      case 0: return Colors.blue.shade700;
      case 1: return Colors.teal.shade700;
      default: return Colors.blue.shade700;
    }
  }

  void _nextPage() {
    if (_validateCurrentPage()) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _saveTripPlan();
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int page) {
    if (page <= _currentPage) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    final provider = Provider.of<TripPlanningProvider>(context, listen: false);

    switch (_currentPage) {
      case 0:
        if (provider.tripDetails.destination.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter destination details')),
          );
          return false;
        }
        return true;
      case 1:
      // Validate that at least one service is selected
        if (provider.selectedFlight == null &&
            provider.selectedHotel == null &&
            provider.selectedTransport == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one service')),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _saveTripPlan() async {
    final tripProvider = Provider.of<TripPlanningProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await tripProvider.saveTripPlan();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.celebration_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text('Trip Saved Successfully!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your trip to ${tripProvider.tripDetails.destination} has been saved.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'What would you like to do next?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Add More Services'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('View My Trips'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}