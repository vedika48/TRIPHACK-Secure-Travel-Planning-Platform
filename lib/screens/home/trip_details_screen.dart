import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trip_plan.dart';
import '../../providers/trip_provider.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  _TripDetailsScreenState createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _purposeController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int _travelers = 1;
  String _tripType = 'leisure';
  final List<String> _preferences = [];
  final _specialRequirementsController = TextEditingController();

  final List<String> _tripTypes = ['leisure', 'business', 'adventure', 'family', 'romantic'];
  final List<String> _availablePreferences = [
    'Beach', 'Mountain', 'City', 'Cultural', 'Food',
    'Shopping', 'Nature', 'Historical', 'Luxury', 'Budget'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  void _loadExistingDetails() {
    final provider = Provider.of<TripPlanningProvider>(context, listen: false);
    final details = provider.tripDetails;

    if (details.destination.isNotEmpty) {
      _sourceController.text = details.source;
      _destinationController.text = details.destination;
      _purposeController.text = details.purpose;
      _startDate = details.startDate;
      _endDate = details.endDate;
      _travelers = details.travelers;
      _tripType = details.tripType;
      _preferences.addAll(details.preferences);
      _specialRequirementsController.text = details.specialRequirements;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.flag_rounded,
            title: 'Destination Details',
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _sourceController,
            label: 'Source City/Country*',
            hint: 'Where are you now?',
            icon: Icons.location_on_rounded,
            onChanged: (_) => _saveTripDetails(),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _destinationController,
            label: 'Destination City/Country*',
            hint: 'Where are you going?',
            icon: Icons.location_on_rounded,
            onChanged: (_) => _saveTripDetails(),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _purposeController,
            label: 'Trip Purpose',
            hint: 'What brings you here?',
            icon: Icons.work_rounded,
            onChanged: (_) => _saveTripDetails(),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Start Date*',
                  date: _startDate,
                  onTap: _selectStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'End Date*',
                  date: _endDate,
                  onTap: _selectEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader(
            icon: Icons.people_rounded,
            title: 'Travel Party',
            color: Colors.green.shade700,
          ),
          const SizedBox(height: 16),

          _buildTravelerSelector(),
          const SizedBox(height: 20),

          _buildSectionHeader(
            icon: Icons.category_rounded,
            title: 'Trip Preferences',
            color: Colors.orange.shade700,
          ),
          const SizedBox(height: 16),

          _buildTripTypeSelector(),
          const SizedBox(height: 16),

          _buildPreferencesSelector(),
          const SizedBox(height: 20),

          _buildSectionHeader(
            icon: Icons.note_rounded,
            title: 'Special Requirements',
            color: Colors.purple.shade700,
          ),
          const SizedBox(height: 16),

          _buildSpecialRequirementsField(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(
                  date?.toString().split(' ')[0] ?? 'Select Date',
                  style: TextStyle(
                    color: date == null ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTravelerSelector() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Travelers', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _travelers > 1 ? () {
                        setState(() => _travelers--);
                        _saveTripDetails();
                      } : null,
                      icon: Icon(Icons.remove, color: _travelers > 1 ? Colors.red.shade600 : Colors.grey),
                    ),
                    Text(
                      '$_travelers traveler${_travelers > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _travelers++);
                        _saveTripDetails();
                      },
                      icon: Icon(Icons.add, color: Colors.green.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Trip Type', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tripTypes.map((type) {
            final isSelected = _tripType == type;
            return FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _tripType = type);
                _saveTripDetails();
              },
              label: Text(type[0].toUpperCase() + type.substring(1)),
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.blue.shade600,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreferencesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preferences (Select multiple)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availablePreferences.map((preference) {
            final isSelected = _preferences.contains(preference);
            return FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _preferences.add(preference);
                  } else {
                    _preferences.remove(preference);
                  }
                });
                _saveTripDetails();
              },
              label: Text(preference),
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.green.shade600,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecialRequirementsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Special Requirements', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _specialRequirementsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any special requirements or notes...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (_) => _saveTripDetails(),
        ),
      ],
    );
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
      _saveTripDetails();
    }
  }

  void _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endDate = date);
      _saveTripDetails();
    }
  }

  void _saveTripDetails() {
    if (_startDate != null && _endDate != null) {
      final provider = Provider.of<TripPlanningProvider>(context, listen: false);
      provider.updateTripDetails(TripDetails(
        source: _sourceController.text,
        destination: _destinationController.text,
        purpose: _purposeController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        travelers: _travelers,
        tripType: _tripType,
        preferences: _preferences,
        specialRequirements: _specialRequirementsController.text,
      ));
    }
  }
}