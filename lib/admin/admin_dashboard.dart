import 'package:cow_and_crop/admin/admin_home_page.dart';
import 'package:cow_and_crop/admin/admin_orders_page.dart';
import 'package:cow_and_crop/admin/admin_products_page.dart';
import 'package:cow_and_crop/admin/admin_users_page.dart';
import 'package:cow_and_crop/admin/farmers_page_content.dart';
import 'package:cow_and_crop/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    const AdminHomePage(),
    const AdminUsersPage(),
    const FarmersPageContent(),
    const AdminProductsPage(),
    const AdminOrdersPage(), // New Orders page added here.
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Cancel
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Dismiss dialog
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFFF5E99)),
            child: Text(
              "Admin Menu",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              _onItemTapped(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Users"),
            onTap: () {
              _onItemTapped(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.agriculture),
            title: const Text("Farmers"),
            onTap: () {
              _onItemTapped(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text("Products"),
            onTap: () {
              _onItemTapped(3);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text("Orders"),
            onTap: () {
              _onItemTapped(4);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Logout"),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color(0xFFFF5E99),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: "Farmers",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Products",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Orders"),
        ],
        currentIndex: _selectedIndex,
        backgroundColor: Color(0xFFFF5E99),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}
