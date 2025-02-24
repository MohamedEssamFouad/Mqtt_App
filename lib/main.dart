import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:se_things_demo/another_service.dart';
import 'ble_service.dart';
import 'mqtt_service.dart';

void main() {
  runApp(MyApp());
}
class MyApp extends HookWidget {
  final BLEManager bleManager = BLEManager();
  final MQTTManager mqttEMQX = MQTTManager(); /// MQTT Client for EMQX
  final hive_service mqttHiveMQ = hive_service(); /// MQTT Client for HiveMQ

  Future<void> requestLocationPermission() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = useState<List<BluetoothDevice>>([]);

    useEffect(() {
      mqttEMQX.setupMQTT(); /// Connect to EMQX
      mqttHiveMQ.setupMQTT(); /// Connect to HiveMQ
      return null;
    }, []);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('BLE & Dual MQTT5 Clients')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              /// Scan for BLE Devices
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

              /// List of Available BLE Devices
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

              /// Send JSON Data via BLE
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

              /// Send MQTT Message to EMQX
              ElevatedButton(
                onPressed: () {
                  String jsonString = '{"relayNo": 2, "state": 1}';
                  mqttEMQX.publishToMQTT("okta_t/relay", jsonString);
                },
                child: Text("Send MQTT Message to EMQX"),
              ),

              /// Send MQTT Message to HiveMQ
              ElevatedButton(
                onPressed: () {
                  String jsonString = '{"relayNo": 3, "state": 1}';
                  mqttHiveMQ.publishToMQTT("hive/control", jsonString);
                },
                child: Text("Send MQTT Message to HiveMQ"),
              ),

              /// Disconnect BLE & MQTT
              ElevatedButton(
                onPressed: () {
                  bleManager.disconnect();
                  mqttEMQX.onDisconnected();
                  mqttHiveMQ.onDisconnected();
                },
                child: Text("Disconnect BLE & MQTT"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
