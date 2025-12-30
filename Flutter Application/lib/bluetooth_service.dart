import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef RawDataCallback = void Function(String data);
typedef PeriodCountCallback = void Function(Map<String, int> counts);

class TrafficBluetoothService {
  RawDataCallback? onRawDataReceived;
  PeriodCountCallback? onPeriodCountUpdate;

  BluetoothConnection? connection;
  String _buffer = "";

  final List<String> roads = ["A", "B", "C"];

  Map<String, int> carCounts = {
    "A": 0,
    "B": 0,
    "C": 0,
  };

  Timer? uploadTimer;

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

      _startSynchronousUploadTimer();

      return true;
    } catch (e) {
      print("❌ Bluetooth Error: $e");
      return false;
    }
  }

  void _onData(Uint8List data) {
    String incoming = utf8.decode(data);
    _buffer += incoming;
    int newlineIndex = _buffer.indexOf('\n');

    while (newlineIndex != -1) {
      String line = _buffer.substring(0, newlineIndex);
      _buffer = _buffer.substring(newlineIndex + 1);
      String trimmedLine = line.trim();

      if (trimmedLine.isNotEmpty) {
        onRawDataReceived?.call(trimmedLine);
        _parseLine(trimmedLine);
      }

      newlineIndex = _buffer.indexOf('\n');
    }
  }

  void _parseLine(String line) {
    if (line.isEmpty || !line.contains(";")) return;

    List<String> parts = line.split(";");

    if (parts.length != 2) return;

    String road = parts[0].trim().toUpperCase();
    int? count = int.tryParse(parts[1].trim());

    if (count == null || !roads.contains(road)) {
      print("⚠️ Invalid data format or road: $line");
      return;
    }

    carCounts[road] = count;
    print("📈 Live count received on $road: $count");
  }

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

  Future<void> _uploadCarCounts() async {
    final now = DateTime.now();

    final totalMinutes = (now.hour * 60) + now.minute;
    final int rowIndexx = (totalMinutes ~/ 5);
    final int rowIndex = rowIndexx - 1;
    final String rowIndexStr = rowIndex.toString();

    if (rowIndex < 0 || rowIndex > 287) {
      print("⚠️ Calculated rowIndex $rowIndex is out of range. Skipping upload.");
      return;
    }

    final countsToUpload = Map<String, int>.from(carCounts);

    onPeriodCountUpdate?.call(countsToUpload);

    carCounts = { "A": 0, "B": 0, "C": 0 };
    print("🔄 Car counts reset for next interval.");

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
      await dataCollection
          .doc(rowIndexStr)
          .set(intervalData, SetOptions(merge: true));

      print("⬆️ Logged 5-min data to IR_CarCount/$rowIndexStr: A:${countsToUpload['A']}, B:${countsToUpload['B']}, C:${countsToUpload['C']}");
    } catch (e) {
      print("❌ Firestore Upload Error: $e. The local counts were displayed but failed to persist to the server.");
    }
  }

  void dispose() {
    uploadTimer?.cancel();
    connection?.dispose();
    print("🧹 TrafficBluetoothService disposed.");
  }
}
