import 'package:flutter/material.dart';
import 'package:inventorytracker/screens/addinventory.dart';
import 'package:inventorytracker/screens/allinventories.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Text(
                'Inventory Tracker',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF93C852),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40), // Space below the header
              // "Add Inventory" button
              ElevatedButton(
                onPressed: () {
                  // Navigate to AddInventory page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddInventory()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF93C852), // Primary color
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10, // Adds a shadow to the button
                ),
                child: const Text(
                  'Add Inventory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20), // Space between buttons
              // "See All Inventories" button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFE0E0E0), // Light grey for a subtle gradient
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to AddInventory page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AllInventories()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(
                        color: Color(0xFF93C852),
                        width: 2, // Border color and width
                      ),
                    ),
                    shadowColor:
                        Colors.transparent, // Remove button's default shadow
                  ),
                  child: const Text(
                    'See All Inventories',
                    style: TextStyle(
                      color: Color(0xFF93C852), // Primary color
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
