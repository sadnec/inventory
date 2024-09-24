import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class InventoryDetails extends StatelessWidget {
  final String date;

  const InventoryDetails({super.key, required this.date});

  Future<void> _requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        print("Storage permission granted.");
      } else if (await Permission.storage.isPermanentlyDenied) {
        print("Storage permission permanently denied.");
        openAppSettings();
      } else {
        print("Storage permission denied.");
        _showPermissionDeniedDialog(context);
      }

      if (await Permission.manageExternalStorage.request().isGranted) {
        print("Manage External Storage permission granted.");
      } else if (await Permission.manageExternalStorage.isPermanentlyDenied) {
        print("Manage External Storage permission permanently denied.");
        openAppSettings();
      } else {
        print("Manage External Storage permission denied.");
        _showPermissionDeniedDialog(context);
      }
    } else {
      print("Permissions not required on iOS.");
    }
  }

  Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
              'Storage permission is required to save and open PDF files.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToPdf(BuildContext context, List<dynamic> items) async {
    await _requestPermissions(context);

    try {
      // Filter out items with zero quantity
      final filteredItems = items.where((item) {
        return (item['quantity'] is int && item['quantity'] > 0) ||
            (int.tryParse(item['quantity'].toString()) ?? 0) > 0;
      }).toList();

      if (filteredItems.isEmpty) {
        print("No items with quantity greater than zero to export.");
        // Show a message to the user (optional)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No items with quantity greater than zero to export.'),
          ),
        );
        return; // Exit if no valid items are present
      }

      final pdf = pw.Document();
      // Calculate the total quantity
      int totalQuantity = filteredItems.fold(0, (sum, item) {
        int quantity = (item['quantity'] is int)
            ? item['quantity']
            : int.tryParse(item['quantity'].toString()) ?? 0;
        return sum + quantity;
      });

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Text('Inventory Details',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),

                // Date Information
                pw.Text('Date: $date', style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),

                // Total Quantity Information
                pw.Text('Total Quantity: $totalQuantity',
                    style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 20),

                // Table for Inventory Items
                pw.Table(
                  border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                  columnWidths: {
                    0: pw.FlexColumnWidth(2), // Product column width
                    1: pw.FlexColumnWidth(1), // Quantity column width
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Product',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Quantity',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Table Rows for Each Item
                    ...filteredItems.map((item) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item['product'] ?? 'N/A'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              (item['quantity'] is int)
                                  ? item['quantity'].toString()
                                  : '0',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Save the PDF and open it
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/inventory_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Open the PDF file with an external app
      await OpenFile.open(file.path);
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Details'),
        backgroundColor: const Color(0xFF93C852),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("inventories")
            .doc(date)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No details found.'));
          } else {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: DataTable(
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Product',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Quantity',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: items.map<DataRow>((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text(item['product'] ?? 'N/A')),
                            DataCell(Text(item['quantity']?.toString() ?? '0')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await _exportToPdf(context, items);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF93C852),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Export to PDF'),
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

class PDFViewPage extends StatelessWidget {
  final String filePath;

  const PDFViewPage({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        backgroundColor: const Color(0xFF93C852),
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
      ),
    );
  }
}
