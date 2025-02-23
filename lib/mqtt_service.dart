import 'dart:async';
import 'dart:convert';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';

class MQTTManager {
  late MqttServerClient mqttClient; ///declare the mqtt clent its late cause we will use it late
  bool _isConnecting = false; ///to preven multi connection

  Future<void> setupMQTT() async {
    if (_isConnecting) return; ///prevent multiple connections
    _isConnecting = true;

    mqttClient = MqttServerClient('broker.emqx.io', 'flutter_client_1234');
    mqttClient.port = 1883; // Default MQTT Port
    mqttClient.logging(on: true);
    mqttClient.keepAlivePeriod = 60;
    mqttClient.onDisconnected = onDisconnected;
    mqttClient.onConnected = onConnected;
    mqttClient.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier("flutter_client_1234")
        .startClean();

    mqttClient.connectionMessage = connMessage;

    try {
      await mqttClient.connect();
      if (mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
        print("✅ MQTT Connected Successfully");
      } else {
        print("❌ MQTT Connection Failed: ${mqttClient.connectionStatus}");
        mqttClient.disconnect();
      }
    } catch (e) {
      print("❌ MQTT Connection Exception: $e");
      mqttClient.disconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void onConnected() => print("✅ MQTT Connected!");
  void onDisconnected() => print("❌ MQTT Disconnected!");

  // ✅ Fix: Change function parameter to `MqttSubscription`
  void onSubscribed(MqttSubscription subscription) {
    print("✅ Subscribed to: ${subscription.topic} with QoS: ${subscription.maximumQos}");
  }

  void publishToMQTT(String topic, String message) {
    if (mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
      Uint8Buffer payload = Uint8Buffer();
      payload.addAll(utf8.encode(message));
      mqttClient.publishMessage(topic, MqttQos.atLeastOnce, payload);
      print("✅ Published to MQTT: $message");
    } else {
      print("⚠️ MQTT Not Connected. Attempting Reconnect...");
      setupMQTT();
    }
  }

  void subscribeToMQTT(String topic) {
    if (mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
      mqttClient.subscribe(topic, MqttQos.atMostOnce);
      mqttClient.updates.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage receivedMessage = messages[0].payload as MqttPublishMessage;

        final Uint8Buffer? payloadBuffer = receivedMessage.payload.message;
        if (payloadBuffer == null || payloadBuffer.isEmpty) {
          print("⚠️ Received empty payload on [$topic]");
          return;
        }

        final String message = utf8.decode(payloadBuffer.toList());
        print("✅ MQTT Message Received on [$topic]: $message");
      });

      print("✅ Subscribed to MQTT Topic: $topic");
    } else {
      print("⚠️ MQTT Not Connected. Cannot Subscribe.");
    }
  }
}
