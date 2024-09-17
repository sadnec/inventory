import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class InventoryDetails extends StatelessWidget {
  final String date;

  const InventoryDetails({super.key, required this.date});

  Future<void> _requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        // Permission granted for older Android versions
        print("Storage permission granted.");
      } else if (await Permission.storage.isPermanentlyDenied) {
        // If the permission is permanently denied, direct the user to settings
        print("Storage permission permanently denied.");
        openAppSettings();
      } else {
        // Permission is denied
        print("Storage permission denied.");
        _showPermissionDeniedDialog(context);
      }

      // For Android 11+ (API level 30), we need to check for MANAGE_EXTERNAL_STORAGE
      if (await Permission.manageExternalStorage.request().isGranted) {
        // Manage External Storage permission granted
        print("Manage External Storage permission granted.");
      } else if (await Permission.manageExternalStorage.isPermanentlyDenied) {
        // If the permission is permanently denied, direct the user to settings
        print("Manage External Storage permission permanently denied.");
        openAppSettings();
      } else {
        // Permission is denied
        print("Manage External Storage permission denied.");
        _showPermissionDeniedDialog(context);
      }
    } else {
      // iOS does not require these permissions
      print("Permissions are not required on iOS.");
    }
  }


  Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Denied'),
          content: Text('Storage permission is required to save and open PDF files.'),
          actions: <Widget>[
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



  Future<void> _exportToPdf(BuildContext context, List<dynamic> items) async {
    // Print items to debug
    await _requestPermissions(context);

    try {
      final pdf = pw.Document();

      // Add a page to the PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Inventory Details', style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                  columnWidths: {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Product', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...items.map((item) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(item['product'] ?? 'N/A'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(item['quantity']?.toString() ?? '0'),
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

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/inventory_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Open the PDF file with an external app
      final result = await OpenFile.open(file.path);
      // if (result.message != null && result.message!.isNotEmpty) {
      //   // Optionally show an error message if the file cannot be opened
      //   showDialog(
      //     context: context,
      //     builder: (BuildContext context) {
      //       return AlertDialog(
      //         title: Text('Error'),
      //         content: Text('Unable to open the PDF file: ${result.message}'),
      //         actions: [
      //           TextButton(
      //             child: Text('OK'),
      //             onPressed: () {
      //               Navigator.of(context).pop();
      //             },
      //           ),
      //         ],
      //       );
      //     },
      //   );
      // }
    } catch (e) {
      print('Error generating PDF: $e');
      // Optionally show an error message to the user
    }
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
                    onPressed: () async {
                      await _exportToPdf(context, items);
                    },
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

class PDFViewPage extends StatelessWidget {
  final String filePath;

  const PDFViewPage({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
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
