import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dht11_apps/models/dashboard.dart';
import 'package:flutter_dht11_apps/myconfig.dart';

class DHTHistoryScreen extends StatefulWidget {
  const DHTHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DHTHistoryScreen> createState() => _DHTHistoryScreenState();
}

class _DHTHistoryScreenState extends State<DHTHistoryScreen> {
  List<Dashboard> historyData = [];
  bool isLoading = false;
  int currentPage = 1;
  int itemsPerPage = 10;
  bool hasMoreData = true;
  int totalPages = 1;
  final TextEditingController _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchHistoryData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchHistoryData({bool reset = false}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      if (reset) {
        historyData = [];
      }
    });

    try {
      final response = await http.get(
        Uri.parse('${MyConfig.servername}/DHT11/fetch.php?device_id=103&page=$currentPage&limit=$itemsPerPage'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          var data = jsonResponse['data'];
          List<Dashboard> newData = [];

          if (data is List) {
            newData = data.map((item) => Dashboard.fromJson(item)).toList();
          } else if (data is Map) {
            newData = [Dashboard.fromJson(data as Map<String, dynamic>)];
          }

          setState(() {
            historyData = newData;
            hasMoreData = newData.length == itemsPerPage;
          });
        }
      }
    } catch (e) {
      print('Error fetching history: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void goToPage(int page) {
    if (page < 1) return;
    setState(() {
      currentPage = page;
      _pageController.text = page.toString();
    });
    fetchHistoryData(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DHT11 History',
          style: GoogleFonts.righteous(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 211, 50),
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 249, 232, 179), Color.fromARGB(255, 248, 204, 8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: currentPage > 1 ? () => goToPage(currentPage - 1) : null,
                    color: currentPage > 1 ? Colors.black87 : Colors.grey,
                  ),
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _pageController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: currentPage.toString(),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onSubmitted: (value) {
                        int? page = int.tryParse(value);
                        if (page != null && page > 0) {
                          goToPage(page);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: hasMoreData ? () => goToPage(currentPage + 1) : null,
                    color: hasMoreData ? Colors.black87 : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      '(${historyData.length} records)',
                      style: GoogleFonts.righteous(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: isLoading && historyData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: historyData.length,
                      itemBuilder: (context, index) {
                        final data = historyData[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Temperature: ${data.temperature}°C',
                                      style: GoogleFonts.righteous(
                                        fontSize: 16,
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Humidity: ${data.humidity}%',
                                      style: GoogleFonts.righteous(
                                        fontSize: 16,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Relay: ${data.relayStatus}',
                                      style: GoogleFonts.righteous(
                                        fontSize: 16,
                                        color: data.relayStatus == 'On' ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      data.timestamp.toString(),
                                      style: GoogleFonts.righteous(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
  