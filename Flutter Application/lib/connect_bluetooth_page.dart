import 'package:flutter/material.dart';
import 'bluetooth_service.dart';

class ConnectBluetoothPage extends StatefulWidget {
  const ConnectBluetoothPage({super.key});

  @override
  State<ConnectBluetoothPage> createState() => _ConnectBluetoothPageState();
}

class _ConnectBluetoothPageState extends State<ConnectBluetoothPage> {
  final TrafficBluetoothService bt = TrafficBluetoothService();

  String status = "Not connected";
  bool isConnecting = false;

  Map<String, int> lastPeriodCounts = {
    "A": 0,
    "B": 0,
    "C": 0,
  };

  final List<String> messages = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    bt.onRawDataReceived = (String data) {
      setState(() {
        messages.add(data.trim());
        if (messages.length > 300) {
          messages.removeAt(0);
        }
      });

      Future.delayed(const Duration(milliseconds: 10), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 60),
            curve: Curves.linear,
          );
        }
      });
    };

    bt.onPeriodCountUpdate = (Map<String, int> counts) {
      setState(() {
        lastPeriodCounts = counts;
      });
    };
  }

  @override
  void dispose() {
    bt.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> connect() async {
    if (isConnecting) return;

    setState(() {
      isConnecting = true;
      status = "Connecting...";
    });

    final bool ok = await bt.connectToHC05();

    setState(() {
      isConnecting = false;
      status = ok ? "Connected ✔" : "Connection failed ❌";
    });
  }

  Widget _buildCountPill(String road, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        children: [
          Text(
            road,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Traffic Data Logger"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: status.contains("✔")
                    ? Colors.green.withOpacity(0.18)
                    : status.contains("❌")
                    ? Colors.red.withOpacity(0.18)
                    : Colors.blueGrey.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: status.contains("✔")
                      ? Colors.green[900]
                      : status.contains("❌")
                      ? Colors.red[900]
                      : Colors.blueGrey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCountPill("Road A", lastPeriodCounts["A"] ?? 0),
                _buildCountPill("Road B", lastPeriodCounts["B"] ?? 0),
                _buildCountPill("Road C", lastPeriodCounts["C"] ?? 0),
              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isConnecting ? null : connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isConnecting
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                )
                    : const Text("Connect", style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Incoming Raw Data Log (Live):",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.5),
                            child: Text(
                              messages[index],
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
