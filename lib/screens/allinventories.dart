import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
          "inventories").get();

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
        title: Text('List of Inventories'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _inventories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No inventories found.'));
          } else {
            final inventories = snapshot.data!;

            return ListView.builder(
              itemCount: inventories.length,
              itemBuilder: (context, index) {
                final inventory = inventories[index];
                final dateStr = inventory['date'] as String;
                final date = DateTime.parse(dateStr);
                final formattedDate = "${date.day}/${date.month}/${date.year}";

                return ListTile(
                  title: Text('Inventory No ${index + 1} - $formattedDate'),
                );
              },
            );
          }
        },
      ),
    );
  }
}


