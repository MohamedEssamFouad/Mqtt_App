import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEManager {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  List<BluetoothCharacteristic> notifyCharacteristics = [];
  // Scan and list all available BLE devices
  Future<void> scanAndListDevices(Function(BluetoothDevice) onDeviceFound) async {
    BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      print(" Bluetooth is off. Please enable it first.");
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

    await Future.delayed(Duration(seconds: 10)); ///will wait the 10scond
    FlutterBluePlus.stopScan(); ///then stop
    subscription.cancel(); ///close the streamm
  }

  // Connect to a selected BLE device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice = device;
      print(" Connected to Device: ${device.platformName}");
      await discoverServices();
    } catch (e) {
      print(" Failed to connect: $e");
    }
  }

  // Discover services and find the characteristics
  Future<void> discoverServices() async {
    if (connectedDevice == null) return;

    List<BluetoothService> services = await connectedDevice!.discoverServices();
    for (var service in services) {
      print("Service UUID: ${service.uuid}");

      for (var characteristic in service.characteristics) {
        print(" Characteristic UUID: ${characteristic.uuid}");
        print("${characteristic.properties.read}");
        print("  Write: ${characteristic.properties.write}");
        print("  read: ${characteristic.properties.read}");

        if (characteristic.properties.write) {
          writeCharacteristic = characteristic;
          print(" Found Write Characteristic: ${characteristic.uuid}");
        }

        if (characteristic.properties.read) {
          notifyCharacteristics.add(characteristic);
          print(" Found read Characteristic: ${characteristic.uuid}");
        }
      }
    }

    if (writeCharacteristic == null) {
      print(" No writable characteristic found!");
    }

    if (notifyCharacteristics.isNotEmpty) {
      await enableNotifications();
    }
  }

  // Enable notifications to receive real-time data
  Future<void> enableNotifications() async {
    for (var characteristic in notifyCharacteristics) {
      await characteristic.setNotifyValue(true);

      characteristic.lastValueStream.listen((data) {
        String receivedData = utf8.decode(data);
        print(" Data Received: $receivedData");
      });
      print("read charsss for ${characteristic.uuid}");
    }
  }

  // Send JSON Data to the Kittt
  Future<void> sendJsonData(Map<String, dynamic> jsonData) async {
    if (writeCharacteristic == null) {
      print(" Write characteristic not found!");
      return;
    }

    try {
      String jsonString = jsonEncode(jsonData);
      List<int> jsonBytes = utf8.encode(jsonString);
      await writeCharacteristic!.write(jsonBytes, withoutResponse: false);
      print(" JSON Data Sent: $jsonString");
      if (notifyCharacteristics.isNotEmpty) {
        print(" Waiting for responses");
      }
    } catch (e) {
      print(" Failed to send data: $e");
    }
  }

  // Disconnect from BLE device
  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      print("Disconnected");
    }
  }
}
