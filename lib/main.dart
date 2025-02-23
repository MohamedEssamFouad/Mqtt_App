import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BLEManager bleManager = BLEManager();
  List<BluetoothDevice> devices = [];

  // Request location permission (needed for BLE scanning on Android 10)
  Future<void> requestLocationPermission() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Scan & Connect to Devices')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Scan for Devices Button
              ElevatedButton(
                onPressed: () async {
                  await requestLocationPermission();  // ✅ Ensure location permission is granted

                  setState(() {
                    devices.clear();
                  });

                  bleManager.scanAndListDevices((device) {
                    setState(() {
                      if (!devices.contains(device)) {
                        devices.add(device);
                      }
                    });
                  });
                },
                child: Text("Scan for Devices"),
              ),
              SizedBox(height: 10),

              // List of Available Devices
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device = devices[index];
                    return ListTile(
                      title: Text(device.name.isNotEmpty ? device.name : "Unknown Device"),
                      subtitle: Text(device.id.toString()),
                      onTap: () {
                        bleManager.connectToDevice(device);
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: 10),

              // Disconnect Button
              ElevatedButton(
                onPressed: () => bleManager.disconnect(),
                child: Text("Disconnect"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
