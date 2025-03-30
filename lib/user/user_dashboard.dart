import 'dart:convert';
import 'package:cow_and_crop/login_screen.dart';
import 'package:cow_and_crop/user/cart_page.dart';
import 'package:cow_and_crop/user/orders_page.dart';
import 'package:cow_and_crop/user/products_page.dart';
import 'package:cow_and_crop/user/user_profile_page.dart';
import 'package:cow_and_crop/user/home_content.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'about_us_page.dart';
import 'package:cow_and_crop/constants.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;
  int cartCount = 0; // Total number of products in the cart
  final String baseUrl = BASE_URL;
  @override
  void initState() {
    super.initState();
    _fetchCartCount();
  }

  List<Widget> get _pages {
    return [
      HomeContent(
        onViewAll: () {
          setState(() {
            _selectedIndex = 3; // Products page index
          });
        },
      ),
      const OrdersPage(),
      const UserProfilePage(),
      const ProductsPage(),
      const CartPage(),
    ];
  }

  // Fetch cart count from API based on userId
  Future<void> _fetchCartCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userId");
    if (userId == null || userId.isEmpty) {
      setState(() {
        cartCount = 0;
      });
      return;
    }
    final Uri uri = Uri.parse("${baseUrl}api/cart/$userId");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        // Assume API returns an array with one cart object having a 'products' field.
        List<dynamic> cartData = jsonDecode(response.body);
        int count = 0;
        if (cartData.isNotEmpty) {
          final cart = cartData[0];
          if (cart["products"] != null && cart["products"] is List) {
            for (var item in cart["products"]) {
              count += int.tryParse(item["quantity"].toString()) ?? 0;
            }
          }
        }
        setState(() {
          cartCount = count;
        });
      } else {
        setState(() {
          cartCount = 0;
        });
      }
    } catch (e) {
      setState(() {
        cartCount = 0;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Refresh cart count when navigating to Cart page (index 4)
    if (index == 4) {
      _fetchCartCount();
    }
  }

  void _logout() async {
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

  void _gotocart() {
    setState(() {
      _selectedIndex = 4;
    });
    _fetchCartCount();
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Text(
              "User Menu",
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
            leading: const Icon(Icons.list),
            title: const Text("Orders"),
            onTap: () {
              _onItemTapped(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              _onItemTapped(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text("Products"),
            onTap: () {
              _onItemTapped(3);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart),
                const SizedBox(width: 4),
                if (cartCount > 0)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cartCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            title: const Text("Cart"),
            onTap: () {
              _onItemTapped(4);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About Us"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsPage()),
              );
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
    // Build bottom nav items with a badge for the Cart option
    final bottomNavItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      const BottomNavigationBarItem(icon: Icon(Icons.list), label: "Orders"),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_bag_outlined),
        label: "Products",
      ),
      BottomNavigationBarItem(
        icon: badges.Badge(
          badgeContent: Text(
            cartCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          child: const Icon(Icons.shopping_cart),
        ),
        label: "Cart",
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: badges.Badge(
              badgeContent: Text(
                cartCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: _gotocart,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: bottomNavItems,
        currentIndex: _selectedIndex,
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}
