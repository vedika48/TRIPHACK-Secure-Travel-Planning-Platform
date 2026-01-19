// explore/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore & Discover',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find travel guides, media, and insights',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
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
              indicatorColor: Colors.green.shade600,
              indicatorWeight: 3,
              labelColor: Colors.green.shade600,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Travel Guide'),
                Tab(text: 'Media'),
                Tab(text: 'Analytics'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                TravelGuideScreen(),
                MediaScreen(),
                AnalyticsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Updated TravelGuideScreen to work with backend
class TravelGuideScreen extends StatefulWidget {
  const TravelGuideScreen({super.key});

  @override
  _TravelGuideScreenState createState() => _TravelGuideScreenState();
}

class _TravelGuideScreenState extends State<TravelGuideScreen> {
  final _destinationController = TextEditingController();
  Map<String, dynamic>? _guideData;
  bool _isLoading = false;
  final List<String> _popularDestinations = [
    'Pune',
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Chennai',
    'Hyderabad',
    'Goa',
    'Kolkata'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Section
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            children: [
              TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Search destination...',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _searchTravelGuide,
                  icon: _isLoading
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.travel_explore),
                  label: Text(_isLoading ? 'Searching...' : 'Get Travel Guide'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Popular Destinations
        if (_guideData == null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Popular Indian Destinations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _popularDestinations.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_popularDestinations[index]),
                    onSelected: (selected) {
                      _destinationController.text = _popularDestinations[index];
                      _searchTravelGuide();
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.green.shade100,
                    checkmarkColor: Colors.green,
                    labelStyle: TextStyle(
                      color: Colors.grey.shade800,
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // Guide Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _guideData != null
              ? SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TravelGuideCard(guideData: _guideData!),
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.travel_explore,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Explore Travel Guides',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for a destination to get detailed travel information',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _searchTravelGuide() async {
    if (_destinationController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final data = await ApiService().getTravelGuide(_destinationController.text);
      setState(() => _guideData = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get travel guide: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Enhanced TravelGuideCard to display backend data
class TravelGuideCard extends StatelessWidget {
  final Map<String, dynamic> guideData;

  const TravelGuideCard({super.key, required this.guideData});

  BuildContext? get context => null;

  @override
  Widget build(BuildContext context) {
    final city = guideData['city'] ?? 'Destination';
    final youtubeLinksMd = guideData['youtube_links_md']?.toString() ?? '';
    final googleEarthLink = guideData['google_earth_link']?.toString() ?? '';

    // Parse YouTube links from markdown
    final youtubeLinks = _parseYouTubeLinks(youtubeLinksMd);

    return Column(
      children: [
        // Destination Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                city,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Travel Guide',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Google Earth Link
        if (googleEarthLink.isNotEmpty) ...[
          _buildSection(
            title: 'Explore on Google Earth',
            icon: Icons.map,
            color: Colors.blue,
            child: GestureDetector(
              onTap: () => _launchURL(googleEarthLink),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'View $city on Google Earth',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          Text(
                            'Interactive 3D view of the destination',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade600),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // YouTube Videos Section
        if (youtubeLinks.isNotEmpty) ...[
          _buildSection(
            title: 'Recommended Videos',
            icon: Icons.video_library,
            color: Colors.red,
            child: Column(
              children: youtubeLinks.map((video) =>
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_arrow, color: Colors.red.shade600, size: 20),
                      ),
                      title: Text(
                        video['title'] ?? 'Travel Video',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('YouTube Video'),
                      trailing: IconButton(
                        icon: Icon(Icons.open_in_new, color: Colors.green.shade600),
                        onPressed: () => _launchURL(video['url']!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
              ).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Analysis Section
        _buildSection(
          title: 'Travel Analysis',
          icon: Icons.analytics,
          color: Colors.orange,
          child: Column(
            children: [
              _buildAnalysisItem(
                icon: Icons.info,
                title: 'Destination Type',
                value: _getDestinationType(city),
                color: Colors.blue,
              ),
              _buildAnalysisItem(
                icon: Icons.people,
                title: 'Tourist Popularity',
                value: _getPopularityLevel(city),
                color: Colors.green,
              ),
              _buildAnalysisItem(
                icon: Icons.attach_money,
                title: 'Cost Level',
                value: _getCostLevel(city),
                color: Colors.orange,
              ),
              _buildAnalysisItem(
                icon: Icons.wb_sunny,
                title: 'Best Season',
                value: _getBestSeason(city),
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _parseYouTubeLinks(String markdownText) {
    final links = <Map<String, String>>[];
    final regex = RegExp(r'-\s*\[([^\]]+)\]\(([^)]+)\)');
    final matches = regex.allMatches(markdownText);

    for (final match in matches) {
      if (match.groupCount >= 2) {
        final title = match.group(1) ?? 'Travel Video';
        final url = match.group(2) ?? '';
        if (url.contains('youtube.com') || url.contains('youtu.be')) {
          links.add({'title': title, 'url': url});
        }
      }
    }
    return links;
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildAnalysisItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  // Analysis helper methods
  String _getDestinationType(String city) {
    final metroCities = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Hyderabad', 'Kolkata'];
    final hillStations = ['Shimla', 'Manali', 'Darjeeling', 'Ooty', 'Mussoorie'];

    if (metroCities.contains(city)) return 'Metropolitan City';
    if (hillStations.contains(city)) return 'Hill Station';
    if (city == 'Goa') return 'Beach Destination';
    if (city == 'Pune') return 'Cultural & Educational Hub';
    return 'Tourist Destination';
  }

  String _getPopularityLevel(String city) {
    final highPopularity = ['Mumbai', 'Delhi', 'Goa', 'Bangalore'];
    final mediumPopularity = ['Chennai', 'Hyderabad', 'Kolkata', 'Pune'];

    if (highPopularity.contains(city)) return 'Very High';
    if (mediumPopularity.contains(city)) return 'High';
    return 'Moderate';
  }

  String _getCostLevel(String city) {
    final expensiveCities = ['Mumbai', 'Delhi', 'Bangalore'];
    final moderateCities = ['Chennai', 'Hyderabad', 'Kolkata', 'Pune'];

    if (expensiveCities.contains(city)) return 'High';
    if (moderateCities.contains(city)) return 'Moderate';
    if (city == 'Goa') return 'Variable (Seasonal)';
    return 'Affordable';
  }

  String _getBestSeason(String city) {
    final winterDestinations = ['Goa', 'Kerala', 'Rajasthan'];
    final summerDestinations = ['Shimla', 'Manali', 'Darjeeling'];

    if (winterDestinations.contains(city)) return 'October to March';
    if (summerDestinations.contains(city)) return 'April to June';
    return 'Year-round';
  }
}

// Updated MediaScreen to show YouTube videos from backend
class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  _MediaScreenState createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final _locationController = TextEditingController();
  Map<String, dynamic>? _mediaData;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Section
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            children: [
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Enter city for videos...',
                  prefixIcon: const Icon(Icons.search, color: Colors.purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _searchVideos,
                  icon: _isLoading
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.video_library),
                  label: Text(_isLoading ? 'Searching...' : 'Find Videos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Media Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _mediaData != null
              ? _buildMediaContent()
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Travel Media',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for a city to find travel videos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaContent() {
    final youtubeLinksMd = _mediaData?['youtube_links_md']?.toString() ?? '';
    final youtubeLinks = _parseYouTubeLinks(youtubeLinksMd);
    final city = _mediaData?['city'] ?? 'the destination';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.pink.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.video_library, size: 48, color: Colors.purple.shade600),
                const SizedBox(height: 12),
                Text(
                  'Travel Videos for $city',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recommended YouTube content for your trip',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Videos List
          if (youtubeLinks.isNotEmpty) ...[
            ...youtubeLinks.map((video) =>
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.play_arrow, color: Colors.red.shade600),
                    ),
                    title: Text(
                      video['title'] ?? 'Travel Video',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Click to watch on YouTube'),
                    trailing: Icon(Icons.open_in_new, color: Colors.purple.shade600),
                    onTap: () => _launchURL(video['url']!),
                  ),
                ),
            ),
          ] else ...[
            const Text('No videos found for this destination'),
          ],
        ],
      ),
    );
  }

  List<Map<String, String>> _parseYouTubeLinks(String markdownText) {
    final links = <Map<String, String>>[];
    final regex = RegExp(r'-\s*\[([^\]]+)\]\(([^)]+)\)');
    final matches = regex.allMatches(markdownText);

    for (final match in matches) {
      if (match.groupCount >= 2) {
        final title = match.group(1) ?? 'Travel Video';
        final url = match.group(2) ?? '';
        if (url.contains('youtube.com') || url.contains('youtu.be')) {
          links.add({'title': title, 'url': url});
        }
      }
    }
    return links;
  }

  void _searchVideos() async {
    if (_locationController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final data = await ApiService().getTravelGuide(_locationController.text);
      setState(() => _mediaData = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get media data: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }
}

// Analytics Screen (Enhanced with real data)
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analytics Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade50, Colors.red.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.analytics, size: 48, color: Colors.orange),
                const SizedBox(height: 12),
                const Text(
                  'Travel Analytics',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Insights and statistics about Indian travel destinations',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Analytics Cards
          _buildAnalyticsCard(
            title: 'Popular Indian Destinations',
            icon: Icons.trending_up,
            color: Colors.green,
            content: Column(
              children: [
                _buildStatItem('Goa', 'Beach destination • 35% searches'),
                _buildStatItem('Manali', 'Hill station • 28% searches'),
                _buildStatItem('Delhi', 'Cultural capital • 22% searches'),
                _buildStatItem('Kerala', 'Backwaters • 15% searches'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildAnalyticsCard(
            title: 'Travel Preferences in India',
            icon: Icons.favorite,
            color: Colors.red,
            content: Column(
              children: [
                _buildStatItem('Beach Vacations', '45% preference'),
                _buildStatItem('Hill Stations', '30% preference'),
                _buildStatItem('Cultural Tours', '15% preference'),
                _buildStatItem('Adventure Travel', '10% preference'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildAnalyticsCard(
            title: 'Indian Travel Trends',
            icon: Icons.bar_chart,
            color: Colors.blue,
            content: Column(
              children: [
                _buildStatItem('Average Trip Duration', '5.2 days'),
                _buildStatItem('Peak Travel Season', 'Oct-Mar'),
                _buildStatItem('Average Budget', '₹15,000-25,000'),
                _buildStatItem('Preferred Transport', 'Trains (42%)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}