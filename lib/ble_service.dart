import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEManager {
  ///this is the instance for the pacakge
  final FlutterBluePlus flutterBlue=FlutterBluePlus();
  BluetoothDevice? connectedDevice; ///to store the connected devices by temporaily
///this is for scan the bluetooth and debug if the bluetooth not enable
  Future<void>scanAndListDevices(Function(BluetoothDevice)onDeviceFoundd)async {
    ///check the bluetooth opened
    BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      print("offfffff eror in the bluetooth ");
      return;
    }
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    StreamSubscription<List<ScanResult>>? subscription;
    subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.remoteId
            .toString()
            .isNotEmpty) {
          onDeviceFoundd(result.device);
        }
      }
    });
    await Future.delayed(Duration(seconds: 10));
    FlutterBluePlus.stopScan();
    subscription.cancel();
  }
  //Connect to a selected ple device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice = device;
      print("Connected to Device: ${device.platformName}");
    } catch (e) {
      print("Faileddddd to connect: $e");
    }
  }
  // Disconnect from ple device
  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      print("Disconnected");
    }
  }
}




