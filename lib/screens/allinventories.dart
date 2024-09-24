import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventorytracker/screens/inventory_details.dart';

class AllInventories extends StatefulWidget {
  const AllInventories({super.key});

  @override
  State<AllInventories> createState() => _AllInventoriesState();
}

class _AllInventoriesState extends State<AllInventories> {
  Future<List<Map<String, dynamic>>>? _inventories;

  @override
  void initState() {
    super.initState();
    _inventories = _fetchInventories();
  }

  // Fetch inventories from Firestore
  Future<List<Map<String, dynamic>>> _fetchInventories() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection("inventories").get();

      List<Map<String, dynamic>> inventories = snapshot.docs.map((doc) {
        return {
          "date": doc['date'],
          "items": doc['items'], // You can include items if needed
        };
      }).toList();

      return inventories;
    } catch (e) {
      print("Error fetching inventories: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'List of Inventories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF93C852), // Your primary color
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _inventories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No inventories found.'));
          } else {
            final inventories = snapshot.data!;

            return ListView.builder(
              padding:
                  const EdgeInsets.all(12.0), // Adds padding around the list
              itemCount: inventories.length,
              itemBuilder: (context, index) {
                final inventory = inventories[index];
                final dateStr = inventory['date'] as String;
                final date = DateTime.parse(dateStr);
                final formattedDate =
                    "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}:${date.second}";

                return Card(
                  elevation: 4.0, // Gives a subtle shadow
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0), // Space between cards
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(
                        12.0), // Adds padding inside the card
                    title: Text(
                      'Inventory No ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[600],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InventoryDetails(date: dateStr),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
