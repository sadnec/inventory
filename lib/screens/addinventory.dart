import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class AddInventory extends StatefulWidget {
  const AddInventory({super.key});

  @override
  _AddInventoryState createState() => _AddInventoryState();
}

class _AddInventoryState extends State<AddInventory> {
  // List to store the quantity for each product
  late List<TextEditingController> quantityControllers;
  late List<String> productNames;

  @override
  void initState() {
    super.initState();
    // Initialize quantityControllers list and productNames
    quantityControllers = [];
    productNames = [];
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    for (var controller in quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Function to load and parse the CSV file from assets
  Future<List<String>> loadColumnFromCSV() async {
    try {
      final rawData = await rootBundle.loadString('assets/produit.csv');
      print("Raw Data: $rawData"); // Debug log

      // Parse CSV
      final List<List<dynamic>> csvTable =
          CsvToListConverter().convert(rawData, eol: '\n', fieldDelimiter: ',');
      print("Parsed Data: $csvTable"); // Debug log

      // Skip the header rows
      int headerRows = 6; // Number of header rows to skip
      if (csvTable.length <= headerRows) {
        print("Not enough data to skip the header rows.");
        return [];
      }

      // Extract data rows
      final List<List<dynamic>> dataRows = csvTable.skip(headerRows).toList();

      // Specify the second column (index 1) you want to extract
      int columnIndex = 1; // Second column
      List<String> columnData = [];
      for (var row in dataRows) {
        if (row.length > columnIndex) {
          String productName = row[columnIndex].toString();
          // Filter out rows that contain the word "gamme"
          if (!productName.toLowerCase().contains('gamme')) {
            columnData.add(productName);
            productNames.add(productName); // Save product names
            // Initialize a controller for each product
            quantityControllers.add(TextEditingController());
          }
        } else {
          print("Row does not contain enough columns: $row"); // Debug log
        }
      }

      print("Filtered Column Data: $columnData"); // Debug log
      return columnData;
    } catch (e) {
      print("Error loading CSV: $e"); // Debug log
      return [];
    }
  }

  // Function to handle form submission
  void _submitInventory() {
    List<Map<String, dynamic>> inventory = [];
    for (int i = 0; i < productNames.length; i++) {
      String productName = productNames[i];
      String? quantityText = quantityControllers[i].text;
      int quantity = int.tryParse(quantityText ?? '') ?? 0;

      inventory.add({
        'product': productName,
        'quantity': quantity,
      });
    }

    // Process the inventory list (e.g., send to server or store locally)
    print("Submitted Inventory: $inventory"); // Debug log

    // Show a confirmation message
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Inventory Submitted'),
          content: Text('Your inventory has been successfully submitted.'),
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
      backgroundColor: Colors.grey[200], // Light grey background
      body: FutureBuilder<List<String>>(
        future: loadColumnFromCSV(),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data found.'));
          } else {
            final columnData = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Color(0xFF93C852)), // Primary color
                          columnSpacing: 20.0, // Space between columns
                          columns: [
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
                          rows: List<DataRow>.generate(
                            columnData.length,
                            (index) => DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black38),
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${index + 1}. ${columnData[index]}',
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black38),
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    alignment: Alignment.center,
                                    child: TextField(
                                      controller: quantityControllers[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Qty',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _submitInventory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF93C852), // Primary color
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Text('Submit Inventory'),
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
