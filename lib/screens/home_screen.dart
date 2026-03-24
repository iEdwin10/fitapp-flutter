import 'package:flutter/material.dart';
import 'workout_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good Morning 🔥',
                  style: TextStyle(color: Colors.black54, fontSize: 13)),
              const Text(
                'Pramuditya Uzumaki',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.black45),
                    SizedBox(width: 8),
                    Text('Search', style: TextStyle(color: Colors.black45)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Popular Workouts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _workoutCard(context, 'Lower Body\nTraining', '500 Kcal',
                        '50 Min', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
                    const SizedBox(width: 12),
                    _workoutCard(context, 'Hand\nTraining', '600 Kcal',
                        '40 Min', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Today Plan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _planItem('Push Up', '100 Push up a day', 0.45, 'Intermediate',
                  'https://images.unsplash.com/photo-1598971639058-fab3c3109a04?w=200'),
              _planItem('Sit Up', '20 Sit up a day', 0.75, 'Beginner',
                  'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=200'),
              _planItem('Knee Push Up', '15 Knee push up a day', 0.30, 'Beginner',
                  'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=200'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFFB5E72E),
        unselectedItemColor: Colors.black45,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _workoutCard(BuildContext context, String title, String kcal,
      String min, String imageUrl) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkoutDetailScreen()),
      ),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.35), BlendMode.darken),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Row(
              children: [
                _badge(Icons.local_fire_department_outlined, kcal),
                const SizedBox(width: 8),
                _badge(Icons.timer_outlined, min),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      );

  Widget _planItem(String title, String subtitle, double progress,
      String level, String imageUrl) {
    final isIntermediate = level == 'Intermediate';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl, width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isIntermediate ? Colors.black87 : Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(level,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ),
                Text(subtitle,
                    style: const TextStyle(color: Colors.black45, fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFFB5E72E),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
