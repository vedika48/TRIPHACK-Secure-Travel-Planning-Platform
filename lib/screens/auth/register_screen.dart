import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLocationLoading = false;
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      if (mounted) {
        setState(() {
          _locationError = 'Location permission is required to auto-detect your location';
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLocationLoading = true;
      _locationError = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationError = 'Location services are disabled. Please enable them.';
            _isLocationLoading = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          if (mounted) {
            setState(() {
              _locationError = 'Location permission denied';
              _isLocationLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationError = 'Location permissions are permanently denied. Please enable them in app settings.';
            _isLocationLoading = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLocationLoading = false;
        });
      }

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );

    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Failed to get current location: ${e.toString()}';
          _isLocationLoading = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndGetLocation();
    });
  }

  Future<void> _checkAndGetLocation() async {
    final status = await Permission.location.status;
    if (status.isGranted && _selectedLocation == null && mounted) {
      _getCurrentLocation();
    }
  }

  void _handleRegistration(BuildContext context, AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_selectedLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your location on the map')),
        );
      }
      return;
    }

    final userData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
      'address': _addressController.text.trim(),
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
    };

    try {
      final success = await authProvider.register(userData);
      if (mounted) {
        if (success) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _isLocationLoading ? null : _getCurrentLocation,
            tooltip: 'Use current location',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const SizedBox(height: 10),
                    const Text(
                      'Join Travel Agent',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your account to start exploring',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Form Fields
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter your email';
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter your password';
                        if (value!.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter your age';
                        final age = int.tryParse(value!);
                        if (age == null || age < 1 || age > 120) return 'Please enter a valid age';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.home,
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter your address' : null,
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Select Your Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap on the map to select your preferred location or use the button to detect your current location',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Map Container
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            GoogleMap(
                              onMapCreated: _onMapCreated,
                              onTap: (LatLng location) {
                                setState(() {
                                  _selectedLocation = location;
                                });
                              },
                              markers: _selectedLocation != null
                                  ? {
                                Marker(
                                  markerId: const MarkerId('selected'),
                                  position: _selectedLocation!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                                ),
                              }
                                  : {},
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(18.5204, 73.8567),
                                zoom: 12,
                              ),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              compassEnabled: true,
                            ),

                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: FloatingActionButton(
                                mini: true,
                                onPressed: _isLocationLoading ? null : _getCurrentLocation,
                                backgroundColor: Colors.white,
                                child: _isLocationLoading
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                                  ),
                                )
                                    : Icon(Icons.my_location, color: Colors.blue.shade700),
                              ),
                            ),

                            if (_isLocationLoading)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                      SizedBox(height: 12),
                                      Text(
                                        'Detecting your location...',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (_locationError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _locationError,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_selectedLocation != null)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                                style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Register Button
                    ElevatedButton(
                      onPressed: authProvider.isLoading || _isLocationLoading
                          ? null
                          : () => _handleRegistration(context, authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}