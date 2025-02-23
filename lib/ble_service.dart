import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEManager {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  List<BluetoothCharacteristic> notifyCharacteristics = [];

  // ✅ Scan for BLE Devices
  Future<void> scanAndListDevices(Function(BluetoothDevice) onDeviceFound) async {
    BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      print("❌ Bluetooth is off. Please enable it first.");
      return;
    }

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    StreamSubscription<List<ScanResult>>? subscription;
    subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.remoteId.toString().isNotEmpty) {
          onDeviceFound(result.device);
        }
      }
    });

    await Future.delayed(Duration(seconds: 10));
    FlutterBluePlus.stopScan();
    subscription.cancel();
  }

  // ✅ Connect to BLE Device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice = device;
      print("✅ Connected to Device: ${device.platformName}");
      await discoverServices();
    } catch (e) {
      print("❌ Failed to connect: $e");
    }
  }

  // ✅ Discover Services & Characteristics
  Future<void> discoverServices() async {
    if (connectedDevice == null) return;

    List<BluetoothService> services = await connectedDevice!.discoverServices();
    for (var service in services) {
      print("🔵 Service UUID: ${service.uuid}");
      for (var characteristic in service.characteristics) {
        print("🟢 Characteristic UUID: ${characteristic.uuid}");
        print("   🔹 Read: ${characteristic.properties.read}");
        print("   🔹 Write: ${characteristic.properties.write}");
        print("   🔹 Notify: ${characteristic.properties.notify}");

        if (characteristic.properties.write) {
          writeCharacteristic = characteristic;
          print("✅ Found Write Characteristic: ${characteristic.uuid}");
        }

        if (characteristic.properties.notify) {
          notifyCharacteristics.add(characteristic);
          print("🔔 Found Notify Characteristic: ${characteristic.uuid}");
        }
      }
    }

    if (writeCharacteristic == null) {
      print("❌ No writable characteristic found!");
    }

    if (notifyCharacteristics.isNotEmpty) {
      await enableNotifications();
    }
  }

  // ✅ Enable Notifications
  Future<void> enableNotifications() async {
    for (var characteristic in notifyCharacteristics) {
      await characteristic.setNotifyValue(true);
      characteristic.lastValueStream.listen((data) {
        String receivedData = utf8.decode(data);
        print("📥 Data Received from BLE: $receivedData");
      });
      print("🔔 Notifications enabled for ${characteristic.uuid}");
    }
  }

  // ✅ Send JSON Data via BLE
  Future<void> sendJsonData(Map<String, dynamic> jsonData) async {
    if (writeCharacteristic == null) {
      print("❌ Write characteristic not found!");
      return;
    }
    try {
      String jsonString = jsonEncode(jsonData);
      List<int> jsonBytes = utf8.encode(jsonString);
      await writeCharacteristic!.write(jsonBytes, withoutResponse: false);
      print("✅ JSON Data Sent: $jsonString");
    } catch (e) {
      print("❌ Failed to send data: $e");
    }
  }

  // ✅ Disconnect from BLE
  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      print("✅ Disconnected");
    }
  }
}
