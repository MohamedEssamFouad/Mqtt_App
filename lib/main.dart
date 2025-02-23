import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_service.dart';
import 'mqtt_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends HookWidget {
  final BLEManager bleManager = BLEManager();
  final MQTTManager mqttManager = MQTTManager();

  Future<void> requestLocationPermission() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = useState<List<BluetoothDevice>>([]);

    useEffect(() {
      mqttManager.setupMQTT();
      return null;
    }, []);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('BLE & MQTT5 App')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Scan for BLE Devices
              ElevatedButton(
                onPressed: () async {
                  await requestLocationPermission();
                  devices.value = [];

                  bleManager.scanAndListDevices((device) {
                    if (!devices.value.contains(device)) {
                      devices.value = [...devices.value, device]; // Updating state with a new list
                    }
                  });
                },
                child: Text("Scan for BLE Devices"),
              ),
              SizedBox(height: 10),

              // List of Available BLE Devices
              Expanded(
                child: ListView.builder(
                  itemCount: devices.value.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device = devices.value[index];
                    return ListTile(
                      title: Text(device.platformName.isNotEmpty ? device.platformName : "Unknown Device"),
                      subtitle: Text(device.remoteId.toString()),
                      onTap: () {
                        bleManager.connectToDevice(device);
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: 10),

              // Send JSON Data via BLE
              ElevatedButton(
                onPressed: () {
                  Map<String, dynamic> jsonData = {
                    "configure_relay": 2,
                    "temperature_setting": 25
                  };
                  bleManager.sendJsonData(jsonData);
                },
                child: Text("Send JSON via BLE"),
              ),

              SizedBox(height: 10),
              // Send MQTT Message
              ElevatedButton(
                onPressed: () {
                  String jsonString = '{"relayNo": 2, "state": 1}';
                  mqttManager.publishToMQTT("okta_t/relay",jsonString);
                },
                child: Text("Send MQTT Message"),
              ),

              // Subscribe to MQTT Topic
              ElevatedButton(
                onPressed: () {
                  mqttManager.subscribeToMQTT("okta_t/light");
                  //mqttManager.subscribeToMQTT("okta_t/temp");
                  //mqttManager.subscribeToMQTT("okta_t/temp");

                },
                child: Text("Subscribe to MQTT"),
              ),

              SizedBox(height: 10),

              // Disconnect BLE
              ElevatedButton(
                onPressed: () => bleManager.disconnect(),
                child: Text("Disconnect BLE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
