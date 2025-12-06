import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'connect_bluetooth_page.dart';
import 'predictions_page.dart';
import 'Trip_planning_page.dart';
import 'Accident_reporting_page.dart';

// Define the name of the prediction document for the current period
const String CURRENT_PERIOD_DOC_ID = 'A';

// Firestore collection references
final CollectionReference predictionsCollection = FirebaseFirestore.instance.collection('Predictions');
final DocumentReference currentPredictionDoc = predictionsCollection.doc(CURRENT_PERIOD_DOC_ID);
final DocumentReference capacitiesDoc = FirebaseFirestore.instance.collection('RoadCapacities').doc('Capacities');

// The main entry point is now a StatefulWidget to manage the collapse/expand state
class Home_page extends StatelessWidget {
  Home_page({super.key});

  // Renaming to match typical Flutter naming convention, but keeping the original class name Home_page
  @override
  Widget build(BuildContext context) {
    return const HomePageStateful();
  }
}

class HomePageStateful extends StatefulWidget {
  const HomePageStateful({super.key});

  @override
  State<HomePageStateful> createState() => _HomePageStatefulState();
}

class _HomePageStatefulState extends State<HomePageStateful> {
  // State variable to manage map visibility. True means map is visible (default).
  bool _showMap = true;

  void _toggleView() {
    setState(() {
      _showMap = !_showMap;
    });
  }

  static const String MAPTILER_KEY = "GVivRYVzrpiflMtsbOYN";

  final LatLng topLeft     = LatLng(30.08197836, 30.93529686);
  final LatLng topRight    = LatLng(30.08162732, 31.28093256);
  final LatLng bottomLeft  = LatLng(29.93513705, 30.93570254);
  final LatLng bottomRight = LatLng(29.93513705, 31.28052688);


  @override
  Widget build(BuildContext context) {
    final bounds = LatLngBounds.fromPoints([
      topLeft,
      topRight,
      bottomRight,
      bottomLeft,
    ]);

    // Determine the map height based on the state
    final double mapHeight = _showMap ? 500.0 : 0.0;

    // Determine the icon direction
    final IconData toggleIcon = _showMap
        ? Icons.keyboard_arrow_up_sharp
        : Icons.keyboard_arrow_down_sharp;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AutoFlow"),
        backgroundColor: Colors.blue,
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Navigation Menu",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Home / Map"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  // Use the stateless wrapper Home_page to restart the state
                  MaterialPageRoute(builder: (_) => Home_page()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text("Bluetooth"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ConnectBluetoothPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.model_training),
              title: const Text("Predictions"),
              onTap: () {
                Navigator.pop(context);
                // Assuming ModelResultsPage is the class name
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ModelResultsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.alt_route),
              title: const Text("Trip Planner"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TripPlanningPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.red),
              title: const Text("Report Accident"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AccidentReportingPage()),
                );
              },
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ANIMATED CONTAINER FOR MAP
          AnimatedContainer(
            duration: const Duration(milliseconds: 300), // Smooth animation
            height: mapHeight,
            curve: Curves.easeInOut,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: bounds.center,
                initialZoom: 12,
                maxZoom: 18,
                minZoom: 10,
                cameraConstraint: CameraConstraint.contain(
                  bounds: bounds,
                ),
              ),
              children: [
                // BASE MAP TILE LAYER
                TileLayer(
                  urlTemplate:
                  "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$MAPTILER_KEY",
                  userAgentPackageName: 'com.example.smart_traffic',
                ),

                // TRAFFIC LAYER TILE LAYER
                TileLayer(
                  urlTemplate:
                  "https://api/maptiler.com/tiles/traffic/{z}/{x}/{y}.png?key=$MAPTILER_KEY",
                  userAgentPackageName: 'com.example.smart_traffic',
                ),

                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: [topLeft, topRight, bottomRight, bottomLeft],
                      borderStrokeWidth: 3,
                      borderColor: Colors.red,
                      color: Colors.transparent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- TOGGLE BUTTON AND DIVIDER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(toggleIcon, size: 30, color: Colors.blue.shade700),
                onPressed: _toggleView,
                tooltip: _showMap ? "Collapse Map" : "Show Map",
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: Colors.grey),

          // --- CONTENT AREA BELOW THE MAP ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. OBVIOUS REROUTING BOX
                  const ReroutingBox(),

                  const SizedBox(height: 16),

                  // 2. ACCIDENT REPORTING BOX
                  const AccidentReportingBox(),

                  const SizedBox(height: 16),

                  // 3. TRAFFIC STATUS BOXES (Current Prediction - Document 'A')
                  const Text(
                    "Current 5-min Predicted Traffic (Period A)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // StreamBuilder for Predictions and Capacities
                  StreamBuilder<DocumentSnapshot>(
                    stream: currentPredictionDoc.snapshots(),
                    builder: (context, predSnapshot) {
                      if (predSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: LinearProgressIndicator());
                      }
                      if (predSnapshot.hasError) {
                        return Center(child: Text('Error: ${predSnapshot.error}'));
                      }
                      if (!predSnapshot.hasData || !predSnapshot.data!.exists) {
                        return const Center(child: Text('No current prediction data (Doc A).'));
                      }

                      final predData = predSnapshot.data!.data() as Map<String, dynamic>;

                      return StreamBuilder<DocumentSnapshot>(
                        stream: capacitiesDoc.snapshots(),
                        builder: (context, capSnapshot) {
                          if (capSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Text('Loading Capacities...'));
                          }
                          if (capSnapshot.hasError) {
                            return Center(child: Text('Error loading capacities: ${capSnapshot.error}'));
                          }

                          // Default capacities in case Firestore document doesn't exist
                          final Map<String, dynamic> capacities =
                          (capSnapshot.hasData && capSnapshot.data!.exists)
                              ? capSnapshot.data!.data() as Map<String, dynamic>
                              : {'A': 338, 'B': 506, 'C': 405};

                          // Get predictions (ensuring they are numbers, default to 0 if missing)
                          final int roadA_pred = (predData['A'] as num?)?.toInt() ?? 0;
                          final int roadB_pred = (predData['B'] as num?)?.toInt() ?? 0;
                          final int roadC_pred = (predData['C'] as num?)?.toInt() ?? 0;

                          // Get capacities (ensuring they are numbers, default to a safe non-zero value)
                          final int capA = (capacities['A'] as num?)?.toInt() ?? 1;
                          final int capB = (capacities['B'] as num?)?.toInt() ?? 1;
                          final int capC = (capacities['C'] as num?)?.toInt() ?? 1;

                          // Display the three road boxes in a COLUMN
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              TrafficInfoBox(
                                roadName: "A",
                                predictedCars: roadA_pred,
                                capacity: capA,
                              ),
                              TrafficInfoBox(
                                roadName: "B",
                                predictedCars: roadB_pred,
                                capacity: capB,
                              ),
                              TrafficInfoBox(
                                roadName: "C",
                                predictedCars: roadC_pred,
                                capacity: capC,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Widgets (ReroutingBox, AccidentReportingBox, TrafficInfoBox remain unchanged) ---

class ReroutingBox extends StatelessWidget {
  const ReroutingBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade400, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "REROUTING RECOMMENDATION",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Planning to drive from October to Cairo?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TripPlanningPage()),
                );
              },
              child: const Text("GET THE BEST ROUTE"),
            ),
          ),
        ],
      ),
    );
  }
}

class AccidentReportingBox extends StatelessWidget {
  const AccidentReportingBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade400, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ACCIDENT REPORTING",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Help us keep the roads safe by reporting a new accident.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AccidentReportingPage()),
                );
              },
              icon: const Icon(Icons.warning_amber),
              label: const Text("REPORT NOW"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ... [Existing imports and Home_page/HomePageStateful class code] ...

class TrafficInfoBox extends StatelessWidget {
  // ... [Existing properties] ...
  final String roadName;
  final int predictedCars;
  final int capacity;

  const TrafficInfoBox({
    super.key,
    required this.roadName,
    required this.predictedCars,
    required this.capacity,
  });

  // ... [Existing _getFullnessColor and _calculateRerouting methods] ...

  Color _getFullnessColor(double fullness) {
    if (fullness > 1.0) return Colors.red;
    if (fullness >= 0.9) return Colors.orange;
    if (fullness >= 0.7) return Colors.amber;
    return Colors.green;
  }

  Map<String, dynamic> _calculateRerouting() {
    const double thresholdFactor = 0.9;
    final double threshold = thresholdFactor * capacity;
    final int rerouteCount;
    final String rerouteMessage;
    final Color color;

    if (predictedCars > threshold) {
      rerouteCount = (predictedCars - threshold).ceil();
      rerouteMessage = "Reroute **$rerouteCount** cars **AWAY**";
      color = Colors.red.shade900;
    } else {
      rerouteCount = (threshold - predictedCars).floor();
      rerouteMessage = "Can reroute **$rerouteCount** cars **TO** this road";
      color = Colors.green.shade900;
    }
    return {'message': rerouteMessage, 'color': color};
  }


  @override
  Widget build(BuildContext context) {
    final double fullness = capacity > 0 ? predictedCars / capacity : 0.0;
    final String fullnessPercentage = "${(fullness * 100).toStringAsFixed(1)}%";
    final Color fullnessColor = _getFullnessColor(fullness);
    final reroutingInfo = _calculateRerouting();

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Road Name
            Text(
              "🛣️ Road $roadName",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(),

            // 1. Predicted Cars / Capacity (FIXED: Use Flexible to allow wrapping)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start, // Align to the top if it wraps
              children: [
                const Text(
                  "Predicted/Capacity:",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Flexible( // <-- Use Flexible here
                  child: Text(
                    "**$predictedCars** cars / **$capacity** capacity",
                    textAlign: TextAlign.right, // Keep the value aligned right
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Percentage of Fullness (No change needed, values are short)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Fullness:",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  fullnessPercentage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: fullnessColor,
                  ),
                ),
              ],
            ),

            // Fullness Progress Bar
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: fullness.clamp(0.0, 1.0),
              color: fullnessColor,
              backgroundColor: Colors.grey.shade200,
              minHeight: 8,
            ),

            // 2. Rerouting Recommendation (FIXED: The Container is now wrapped in Flexible)
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: reroutingInfo['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: reroutingInfo['color'], width: 1),
              ),
              // Use Text.rich to ensure bold text is handled, and let the Container size itself
              child: Center(
                child: Text(
                  reroutingInfo['message'].replaceAll('**', ''), // Remove Markdown bold for display
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: reroutingInfo['color'],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

