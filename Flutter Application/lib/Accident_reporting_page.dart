import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- CONFIGURATION ---
const List<String> ROAD_IDS = ['A', 'B', 'C'];
// ---------------------

class AccidentReportingPage extends StatefulWidget {
  const AccidentReportingPage({super.key});

  @override
  State<AccidentReportingPage> createState() => _AccidentReportingPageState();
}

class _AccidentReportingPageState extends State<AccidentReportingPage> {
  // Accident reporting variables
  String? _accidentRoad;
  double _kmLocation = 0.0;
  String? _severity;
  int _lanesAffected = 1;

  // --- CAPACITY CALCULATION LOGIC (Copied from previous file) ---
  double _calculateCapacityReduction(String severity, int lanesAffected) {
    double fs = 0.0; // Base Reduction Factor (Severity)
    double fl = 0.0; // Lane Reduction Factor (Lanes Affected)

    // Set Fs based on severity
    if (severity == 'Minor') fs = 0.10;
    else if (severity == 'Medium') fs = 0.30;
    else if (severity == 'Major') fs = 0.60;

    // Set Fl based on lanes affected
    if (lanesAffected == 1) fl = 0.20;
    else if (lanesAffected == 2) fl = 0.50;
    else if (lanesAffected >= 3) fl = 0.80;

    // Combined reduction formula: R = Fs + Fl - (Fs * Fl)
    return fs + fl - (fs * fl);
  }

  // --- FIREBASE WRITE (ACCIDENT REPORTING) ---
  Future<void> _reportAccident() async {
    if (_accidentRoad == null || _severity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Road and Severity to report.')),
      );
      return;
    }

    final reductionFactor = _calculateCapacityReduction(_severity!, _lanesAffected);

    try {
      // Write the reduction factor directly to the TrafficParams document
      await FirebaseFirestore.instance
          .collection('SystemStatus')
          .doc('TrafficParams')
          .set({
        // Store reduction factor for the affected road
        'road${_accidentRoad!}_capacity_reduction': reductionFactor,
        'accident_road': _accidentRoad,
        'km_location': _kmLocation,
        'severity': _severity,
        'lanes_affected': _lanesAffected,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Accident reported! Road ${_accidentRoad} capacity reduced by ${(reductionFactor * 100).toStringAsFixed(0)}%'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error reporting accident: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accident Reporting"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Report Blockage / Accident",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const Text(
              "This dynamically adjusts road capacity for rerouting calculations.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const Divider(height: 30),

            // Road Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Road Affected"),
              value: _accidentRoad,
              items: ROAD_IDS.map((road) => DropdownMenuItem(value: road, child: Text("Road $road"))).toList(),
              onChanged: (value) => setState(() => _accidentRoad = value),
            ),

            // Severity Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Severity"),
              value: _severity,
              items: ['Minor', 'Medium', 'Major'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) => setState(() => _severity = value),
            ),

            // Lanes Affected (Simple Slider)
            const SizedBox(height: 20),
            Text("Lanes Affected: $_lanesAffected", style: const TextStyle(fontWeight: FontWeight.w500)),
            Slider(
              value: _lanesAffected.toDouble(),
              min: 1,
              max: 3,
              divisions: 2,
              label: _lanesAffected.toString(),
              onChanged: (double value) => setState(() => _lanesAffected = value.round()),
            ),

            // KM Location (Simple Input)
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "KM location from Start (Optional)"),
              onChanged: (value) => _kmLocation = double.tryParse(value) ?? 0.0,
            ),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _reportAccident,
              icon: const Icon(Icons.report_problem),
              label: const Text("SUBMIT ACCIDENT REPORT"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}