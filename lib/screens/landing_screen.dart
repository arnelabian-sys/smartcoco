import 'package:flutter/material.dart';
import '../theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/smartcoco_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black45,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.eco, color: Colors.white, size: 26),
                        SizedBox(width: 6),
                        Text('SmartCoco', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        minimumSize: const Size(40, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Register', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(40, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('Log in'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.eco, size: 72, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'SmartCoco',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'A Web-Based Coconut Variety Classification System Using Image Recognition',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: const [
                              _InfoCard(title: 'Upload a photo', body: 'Take or select a coconut photo to classify its variety.'),
                              _InfoCard(title: 'Instant result', body: 'Get variety name and confidence percentage in seconds.'),
                              _InfoCard(title: 'Track history', body: 'Review your past classifications anytime.'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        color: Colors.white.withOpacity(0.92),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.grey800)),
            ],
          ),
        ),
      ),
    );
  }
}
