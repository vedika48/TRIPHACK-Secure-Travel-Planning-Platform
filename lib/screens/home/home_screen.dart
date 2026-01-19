import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/session_manager.dart';
import '../chat/chat_screen.dart';
import '../explore/explore_screen.dart';
import '../profile/profile_screen.dart';
import '../home/trip_plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final SessionManager _sessionManager = SessionManager();

  final List<Widget> _screens = [
    const HomeTab(),
    const ChatScreen(),
    const ExploreScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Use SessionManager to handle session initialization
      if (authProvider.user != null) {
        await _sessionManager.initializeSession(authProvider.user!.uid);

        final sessionKey = await _sessionManager.getSessionKey();
        if (sessionKey != null) {
          agentProvider.initialize(sessionKey);

          // Load available agents from backend
          await agentProvider.loadAvailableAgents();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Initialization error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'TRIPHACK',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: Colors.blue.shade700,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            backgroundColor: Colors.white,
            elevation: 10,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_outlined),
                activeIcon: Icon(Icons.chat_rounded),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore_rounded),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? _userStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      // Simulate getting user stats
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _userStats = {
          'totalTrips': 0,
          'upcomingTrips': 0,
          'activeBookings': 0,
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return RefreshIndicator(
      onRefresh: _loadUserStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(authProvider),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildPlanTripCard(),
            const SizedBox(height: 24),
            _buildQuickAccessSection(),
            const SizedBox(height: 24),
            _buildAgentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade300,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_people_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${authProvider.user?.name ?? 'Explorer'}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to plan your next adventure?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_isLoadingStats) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          title: 'Total Trips',
          value: _userStats?['totalTrips']?.toString() ?? '0',
          icon: Icons.luggage_rounded,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Upcoming',
          value: _userStats?['upcomingTrips']?.toString() ?? '0',
          icon: Icons.calendar_today_rounded,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Active',
          value: _userStats?['activeBookings']?.toString() ?? '0',
          icon: Icons.confirmation_number_rounded,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Agents',
          value: '4',
          icon: Icons.people_rounded,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTripCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        elevation: 8,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TripPlanningScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade500, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.airplane_ticket_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plan Your Trip',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start your journey with personalized planning',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildQuickAccessCard(
              icon: Icons.chat_rounded,
              title: 'AI Assistant',
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/chat'),
            ),
            _buildQuickAccessCard(
              icon: Icons.explore_rounded,
              title: 'Travel Guide',
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/explore'),
            ),
            _buildQuickAccessCard(
              icon: Icons.history_rounded,
              title: 'My Trips',
              color: Colors.blue,
              onTap: () => _showMyTrips(),
            ),
            _buildQuickAccessCard(
              icon: Icons.favorite_rounded,
              title: 'Favorites',
              color: Colors.red,
              onTap: () => _showFavorites(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.9), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentsSection() {
    return Consumer<AgentProvider>(
      builder: (context, agentProvider, child) {
        final activeAgents = agentProvider.agents.where((agent) => agent.status == 'available').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Available Travel Experts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${activeAgents.length} online',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (agentProvider.isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeAgents.length,
                  itemBuilder: (context, index) {
                    final agent = activeAgents[index];
                    return AgentCard(agent: agent);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showMyTrips() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('My Trips feature coming soon!')),
    );
  }

  void _showFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favorites feature coming soon!')),
    );
  }
}

class AgentCard extends StatelessWidget {
  final Agent agent;

  const AgentCard({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAgentColor(agent.type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getAgentIcon(agent.type),
                      color: _getAgentColor(agent.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          agent.type.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: agent.status == 'available'
                          ? Colors.green.shade50
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: agent.status == 'available'
                            ? Colors.green.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: agent.status == 'available'
                                ? Colors.green.shade600
                                : Colors.grey.shade600,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          agent.status == 'available' ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: agent.status == 'available'
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                agent.description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/chat');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getAgentColor(agent.type).withOpacity(0.1),
                  foregroundColor: _getAgentColor(agent.type),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Conversation',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAgentColor(String type) {
    switch (type.toLowerCase()) {
      case 'travel_planner':
        return Colors.blue.shade600;
      case 'booking':
        return Colors.green.shade600;
      case 'guide':
        return Colors.orange.shade600;
      case 'general':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getAgentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'travel_planner':
        return Icons.trip_origin_rounded;
      case 'booking':
        return Icons.airplane_ticket_rounded;
      case 'guide':
        return Icons.travel_explore_rounded;
      case 'general':
        return Icons.chat_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}