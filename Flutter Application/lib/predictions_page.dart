import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PredictionResult {
  final String period;
  final int roadA;
  final int roadB;
  final int roadC;

  PredictionResult({
    required this.period,
    required this.roadA,
    required this.roadB,
    required this.roadC,
  });

  factory PredictionResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PredictionResult(
      period: doc.id,
      roadA: data['A'] ?? 0,
      roadB: data['B'] ?? 0,
      roadC: data['C'] ?? 0,
    );
  }
}

class ModelResultsPage extends StatelessWidget {
  final List<String> periodIds =
  List.generate(12, (index) => String.fromCharCode('A'.codeUnitAt(0) + index));

  final CollectionReference predictionsCollection =
  FirebaseFirestore.instance.collection('Predictions');

  ModelResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Model Predictions'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => print('Firebase listener handles refresh every 5 min.'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: predictionsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No prediction data available.'));
          }

          List<PredictionResult> results = snapshot.data!.docs
              .map((doc) => PredictionResult.fromFirestore(doc))
              .toList();

          results.sort((a, b) => periodIds.indexOf(a.period).compareTo(periodIds.indexOf(b.period)));

          Timestamp? lastUpdateTimeStamp;

          final docA = snapshot.data!.docs.cast<DocumentSnapshot?>().firstWhere(
                (doc) => doc?.id == 'A',
            orElse: () => null,
          );

          if (docA != null && docA.data() is Map<String, dynamic>) {
            final data = docA.data() as Map<String, dynamic>;
            lastUpdateTimeStamp = data['timestamp'] as Timestamp?;
          }

          final formattedTime = lastUpdateTimeStamp != null
              ? DateFormat('HH:mm:ss').format(lastUpdateTimeStamp.toDate())
              : 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Model Run Time:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Predictions generated at: $formattedTime',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.grey[700]),
                ),
                const Divider(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columnSpacing: 10,
                    horizontalMargin: 5,
                    headingRowColor: MaterialStateProperty.all(Colors.indigo.shade100),
                    columns: const [
                      DataColumn(label: Text('Period')),
                      DataColumn(label: Text('Road A (Cars)')),
                      DataColumn(label: Text('Road B (Cars)')),
                      DataColumn(label: Text('Road C (Cars)')),
                    ],
                    rows: results.map((result) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            result.period,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(result.roadA.toString())),
                          DataCell(Text(result.roadB.toString())),
                          DataCell(Text(result.roadC.toString())),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Note: Periods A-L represent the next 12 consecutive 5-minute intervals (1 hour total).',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
