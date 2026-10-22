import 'package:flutter/material.dart';
import '../services/auth_controller.dart';
import '../widgets/smartcoco_hero.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.user.value;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image only (no logo / feature widgets).
          const SmartCocoHero(),

          // ---------------------------------------------------------------
          // TOP-RIGHT: Register button + short caption underneath it.
          // ---------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user == null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: SmartCocoColors.leafGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(160, 48),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 12),
                              textStyle: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
                            icon: const Icon(Icons.person_add, size: 20),
                            label: const Text('Register'),
                          ),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 330),
                            child: const Text(
                              'Click Register to start classifying coconut variety',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: SmartCocoColors.darkGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: SmartCocoColors.leafGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(40, 38),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          AuthController.instance.logout();
                          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                        },
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Log out'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
