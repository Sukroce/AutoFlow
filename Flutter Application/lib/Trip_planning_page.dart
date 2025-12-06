import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- CONFIGURATION ---
const int BASE_CAPACITY = 100;
const String CURRENT_PERIOD_DOC_ID = 'A';
const List<String> ROAD_IDS = ['A', 'B', 'C'];
// ---------------------

class TripPlanningPage extends StatefulWidget {
  const TripPlanningPage({super.key});

  @override
  State<TripPlanningPage> createState() => _TripPlanningPageState();
}

class _TripPlanningPageState extends State<TripPlanningPage> {
  final TextEditingController _startController = TextEditingController(text: "Intersection 1");
  final TextEditingController _destinationController = TextEditingController(text: "End Node");
  DateTime _selectedTime = DateTime.now();
  String _rerouteResult = "Enter trip details and click Reroute to find the best path.";

  // --- REROUTING LOGIC (Simplified V/C) ---
  Future<void> _runReroutingLogic() async {
    setState(() {
      _rerouteResult = "Calculating...";
    });

    try {
      // 1. Fetch current predictions (V) and capacity reductions (R)
      final predictionSnapshot = await FirebaseFirestore.instance
          .collection('Predictions')
          .doc(CURRENT_PERIOD_DOC_ID)
          .get();

      final paramsSnapshot = await FirebaseFirestore.instance
          .collection('SystemStatus')
          .doc('TrafficParams')
          .get();

      final predictions = predictionSnapshot.data() ?? {};
      final params = paramsSnapshot.data() ?? {};

      List<Map<String, dynamic>> roadMetrics = [];

      for (String road in ROAD_IDS) {
        final predictedVolume = (predictions[road] as int?) ?? 0;

        // Get capacity reduction factor (R) for this road
        final reductionFactor = (params['road${road}_capacity_reduction'] as double?) ?? 0.0;

        // Calculate adjusted capacity (C_adj)
        final adjustedCapacity = (BASE_CAPACITY * (1.0 - reductionFactor)).round();
        final finalCapacity = adjustedCapacity > 0 ? adjustedCapacity : 1; // Avoid division by zero

        // Calculate V/C Ratio
        final vcRatio = predictedVolume / finalCapacity;

        roadMetrics.add({
          'road': road,
          'vc_ratio': vcRatio,
          'volume': predictedVolume,
          'capacity': finalCapacity,
        });
      }

      // 2. Sort by V/C Ratio (lowest is best/least congested)
      roadMetrics.sort((a, b) => a['vc_ratio'].compareTo(b['vc_ratio']));

      // 3. Determine result
      final bestRoute = roadMetrics.first;
      final bestVC = bestRoute['vc_ratio'].toStringAsFixed(2);

      setState(() {
        _rerouteResult =
        "Recommended: Road ${bestRoute['road']} 🚗\n"
            "V/C Ratio: $bestVC\n"
            "Status: Least congested road for the next 5 minutes.";
      });

    } catch (e) {
      setState(() {
        _rerouteResult = "Error calculating reroute: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Planner"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Trip Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: _startController, decoration: const InputDecoration(labelText: "Start Location")),
            TextField(controller: _destinationController, decoration: const InputDecoration(labelText: "Destination")),

            // Start Time
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Trip Start Time: ${DateFormat('HH:mm').format(_selectedTime)}"),
              trailing: const Icon(Icons.access_time),
              onTap: () {
                setState(() { _selectedTime = DateTime.now(); });
              },
            ),

            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _runReroutingLogic,
              icon: const Icon(Icons.alt_route),
              label: const Text("RUN REROUTING ALGORITHM"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _rerouteResult,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}