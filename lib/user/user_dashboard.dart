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
  int cartCount = 0;
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
            _selectedIndex = 3;
          });
        },
      ),
      const OrdersPage(),
      const UserProfilePage(),
      const ProductsPage(),
      const CartPage(),
    ];
  }

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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
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

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Account"),
            content: const Text(
              "Are you sure you want to permanently delete your account? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _deleteAccount();
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userId");

    if (userId == null || userId.isEmpty) {
      _showError("User ID is missing");
      return;
    }

    final Uri uri = Uri.parse("${baseUrl}api/users/$userId");

    try {
      final response = await http.delete(uri);

      if (response.statusCode == 200 || response.statusCode == 204) {
        await prefs.clear();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        // Error case: print status and body
        String errorMessage = "Failed to delete account";

        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          if (errorData.containsKey("message")) {
            errorMessage = errorData["message"];
          }
        } catch (e) {
          errorMessage = "Unexpected error occurred.";
        }

        _showError(errorMessage);
      }
    } catch (e) {
      _showError("Error occurred while deleting account.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text("Delete Account"),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
