import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class InventoryDetails extends StatelessWidget {
  final String date;

  const InventoryDetails({super.key, required this.date});

  // Generate PDF and save to device
  Future<void> _exportToPdf(BuildContext context, List<dynamic> items) async {
    final pdf = pw.Document();

    // Load the DejaVuSans font
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Inventory Details', style: pw.TextStyle(fontSize: 24, font: font)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Product', 'Quantity'],
                data: items.map((item) {
                  return [item['product'], item['quantity'].toString()];
                }).toList(),
                headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(font: font),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/inventory_${DateTime.now().toIso8601String()}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Optionally, show a dialog or notification to indicate the file has been saved
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('PDF Exported'),
          content: Text('Your inventory list has been exported to PDF.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("inventories").doc(date).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No details found.'));
          } else {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>;

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index] as Map<String, dynamic>;
                      final product = item['product'];
                      final quantity = item['quantity'];

                      return ListTile(
                        title: Text('$product'),
                        subtitle: Text('Quantity: $quantity'),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _exportToPdf(context, items),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Customize as needed
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Text('Export to PDF'),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
