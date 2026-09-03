import 'package:flutter/material.dart';

import '../features/learn/learn_screen.dart';
import '../features/more/more_screen.dart';
import '../features/my_health/my_health_screen.dart';
import '../features/nearby/nearby_screen.dart';
import '../widgets/help_now_button.dart';
import '../widgets/link_launcher.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.linkLauncher});

  final LinkLauncher? linkLauncher;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;

  static const _titles = ['Nearby', 'My Health', 'Learn', 'More'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(_titles[_tabIndex]),
        actions: const [HelpNowButton()],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          const NearbyScreen(),
          MyHealthScreen(launcher: widget.linkLauncher),
          const LearnScreen(),
          const MoreScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          setState(() => _tabIndex = index);
        },
        destinations: const [
          NavigationDestination(
            key: ValueKey('tab-nearby'),
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'Nearby',
          ),
          NavigationDestination(
            key: ValueKey('tab-my-health'),
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'My Health',
          ),
          NavigationDestination(
            key: ValueKey('tab-learn'),
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
          NavigationDestination(
            key: ValueKey('tab-more'),
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
