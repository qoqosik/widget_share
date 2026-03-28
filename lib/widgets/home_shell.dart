import 'package:flutter/material.dart';

import '../screens/add_widget_screen.dart';
import '../screens/create_screen.dart';
import '../screens/notes_screen.dart';

/// Main scaffold: [BottomNavigationBar] with three tabs.
///
/// Uses [IndexedStack] so each tab keeps its state when switching.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    AddWidgetScreen(),
    CreateScreen(),
    NotesScreen(),
  ];

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onDestinationSelected,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.widgets_outlined),
            activeIcon: Icon(Icons.widgets),
            label: 'Add Widget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_outlined),
            activeIcon: Icon(Icons.edit),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}
