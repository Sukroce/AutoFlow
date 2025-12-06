import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Callback for incoming raw data (e.g., A;10)
typedef RawDataCallback = void Function(String data);
// Callback for period-end car count updates (e.g., {"A": 10, "B": 20, "C": 15})
typedef PeriodCountCallback = void Function(Map<String, int> counts);


class TrafficBluetoothService {
  RawDataCallback? onRawDataReceived;
  PeriodCountCallback? onPeriodCountUpdate;

  BluetoothConnection? connection;
  String _buffer = "";

  // --- 3 Roads (A, B, and C) ---
  final List<String> roads = ["A", "B", "C"];

  // Car count per road. This now holds the LATEST count reported by the Arduino
  // for the CURRENT 5-minute period.
  Map<String, int> carCounts = {
    "A": 0,
    "B": 0,
    "C": 0,
  };

  // Removed debounce and threshold logic as the Arduino sends the count, not distance.
  Timer? uploadTimer;

  // ----------------------------------------
  // CONNECT TO HC-05
  // ----------------------------------------
  Future<bool> connectToHC05() async {
    try {
      print("🔍 Scanning for HC-05...");

      FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;

      if (!(await bluetooth.isEnabled ?? false)) {
        await bluetooth.requestEnable();
      }

      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();

      BluetoothDevice? hc05;

      for (var d in devices) {
        if ((d.name ?? "").toUpperCase().contains("HC-05")) {
          hc05 = d;
          break;
        }
      }

      if (hc05 == null) {
        print("❌ HC-05 not paired.");
        return false;
      }

      print("📡 HC-05 found: ${hc05.name}");
      print("🔗 Connecting...");

      connection = await BluetoothConnection.toAddress(hc05.address);

      print("✔ CONNECTED to HC-05");

      connection!.input!.listen(_onData).onDone(() {
        print("⚠ HC-05 disconnected.");
      });

      // Start the synchronous 5-minute timer
      _startSynchronousUploadTimer();

      return true;
    } catch (e) {
      print("❌ Bluetooth Error: $e");
      return false;
    }
  }

  // ----------------------------------------
  // DATA RECEIVING AND PARSING
  // ----------------------------------------
  void _onData(Uint8List data) {
    String incoming = utf8.decode(data);
    _buffer += incoming;
    int newlineIndex = _buffer.indexOf('\n');

    while (newlineIndex != -1) {
      String line = _buffer.substring(0, newlineIndex);
      _buffer = _buffer.substring(newlineIndex + 1);
      String trimmedLine = line.trim();

      if (trimmedLine.isNotEmpty) {
        // 1. Send raw data to the Flutter UI for display in log
        onRawDataReceived?.call(trimmedLine);

        // 2. Pass data to the internal counting logic
        _parseLine(trimmedLine);
      }

      newlineIndex = _buffer.indexOf('\n');
    }
  }

  // ----------------------------------------
  // PARSE "A;num", "B;num", or "C;num" (num is the final count)
  // ----------------------------------------
  void _parseLine(String line) {
    if (line.isEmpty || !line.contains(";")) return;

    List<String> parts = line.split(";");

    if (parts.length != 2) return;

    String road = parts[0].trim().toUpperCase();
    // Parse the second part as the integer car count
    int? count = int.tryParse(parts[1].trim());

    if (count == null || !roads.contains(road)) {
      print("⚠️ Invalid data format or road: $line");
      return;
    }

    // CRITICAL CHANGE: Update the master map with the latest count received.
    // This value is the running count for the current 5-minute period, as determined by the Arduino.
    carCounts[road] = count;
    print("📈 Live count received on $road: $count");
  }


  // ----------------------------------------
  // SYNCHRONOUS 5-MINUTE UPLOAD TIMER
  // ----------------------------------------
  void _startSynchronousUploadTimer() {
    final now = DateTime.now();
    const int fiveMinutesInMs = 5 * 60 * 1000;

    final totalSeconds = now.minute * 60 + now.second;
    final int secondsPassedInInterval = totalSeconds % 300;

    final int msPassedInInterval = secondsPassedInInterval * 1000 + now.millisecond;
    int msUntilNextInterval = fiveMinutesInMs - msPassedInInterval;

    if (msPassedInInterval == 0) {
      msUntilNextInterval = fiveMinutesInMs;
    }

    final Duration timeToWait = Duration(milliseconds: msUntilNextInterval);
    final nextUploadTime = now.add(timeToWait);

    print("⏰ Current time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond}");
    print("⏳ Calculated delay until next upload: ${timeToWait.inMinutes}m ${timeToWait.inSeconds.remainder(60)}s ${timeToWait.inMilliseconds.remainder(1000)}ms");
    print("🎯 First upload target time: ${nextUploadTime.hour.toString().padLeft(2, '0')}:${nextUploadTime.minute.toString().padLeft(2, '0')}:00.000");

    uploadTimer = Timer(timeToWait, () {
      _uploadCarCounts();
      const fiveMinutes = Duration(minutes: 5);
      uploadTimer?.cancel();
      uploadTimer = Timer.periodic(fiveMinutes, (Timer t) {
        _uploadCarCounts();
      });
      print("✅ Synchronized with clock. Repeating upload started every 5 minutes.");
    });
  }


  // ----------------------------------------
  // FIREBASE/FIRESTORE UPLOAD
  // ----------------------------------------
  Future<void> _uploadCarCounts() async {
    final now = DateTime.now();

    // 1. Calculate the 5-minute row index (0-287)
    final totalMinutes = (now.hour * 60) + now.minute;
    final int rowIndexx = (totalMinutes ~/ 5);
    final int rowIndex = rowIndexx - 1;
    final String rowIndexStr = rowIndex.toString();

    if (rowIndex < 0 || rowIndex > 287) {
      print("⚠️ Calculated rowIndex $rowIndex is out of range. Skipping upload.");
      return;
    }

    // Capture the final counts for the period ending now
    final countsToUpload = Map<String, int>.from(carCounts);

    // 2. --- UI UPDATE AND RESET (ENSURED TO RUN) ---
    // Notify the UI so it displays the just-recorded count immediately.
    onPeriodCountUpdate?.call(countsToUpload);

    // Reset the car counts. The Arduino should also be resetting its count roughly now.
    carCounts = { "A": 0, "B": 0, "C": 0 };
    print("🔄 Car counts reset for next interval.");


    // 3. --- FIREBASE WRITE ATTEMPT ---
    // NEW COLLECTION: 'IR_CarCount'
    // Document ID is the 5-minute index (0-287)
    final dataCollection = FirebaseFirestore.instance
        .collection('IR_CarCount');

    final intervalData = {
      'A': countsToUpload['A'],
      'B': countsToUpload['B'],
      'C': countsToUpload['C'],
      'timestamp_log': FieldValue.serverTimestamp(),
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    };

    try {
      // Upload the 5-minute interval data directly to the index document, merging if it exists.
      await dataCollection
          .doc(rowIndexStr) // The document ID is the 5-minute index
          .set(intervalData, SetOptions(merge: true));

      print("⬆️ Logged 5-min data to IR_CarCount/$rowIndexStr: A:${countsToUpload['A']}, B:${countsToUpload['B']}, C:${countsToUpload['C']}");

    } catch (e) {
      print("❌ Firestore Upload Error: $e. The local counts were displayed but failed to persist to the server.");
    }
  }

  // ----------------------------------------
  // CLEANUP
  // ----------------------------------------
  void dispose() {
    uploadTimer?.cancel();
    connection?.dispose();
    print("🧹 TrafficBluetoothService disposed.");
  }
}