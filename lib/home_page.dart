import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  static const List<Widget> _pages = <Widget>[CowsPage(), CropsPage()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cow and Crop")),
      body: Center(child: _pages.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Cows'),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: 'Crops',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}

class CowsPage extends StatelessWidget {
  const CowsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Cows Page", style: TextStyle(fontSize: 24)),
    );
  }
}

class CropsPage extends StatelessWidget {
  const CropsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Crops Page", style: TextStyle(fontSize: 24)),
    );
  }
}
