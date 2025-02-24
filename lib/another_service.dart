import 'dart:convert';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';

class hive_service {
  late MqttServerClient mqttClient; ///declare the mqtt clent its late cause we will use it late
  bool _isConnecting = false; ///to preven multi connection
  Future<void> setupMQTT() async {
    if (_isConnecting) return; ///prevent multiple connections
    _isConnecting = true;
    mqttClient = MqttServerClient('broker.hivemq.com', 'flutter_hivemq_client');
    mqttClient.port = 1883; /// Default MQTT Port
    mqttClient.logging(on: true);
    mqttClient.keepAlivePeriod = 60; ///make it alive every 60sec it open again
    mqttClient.onDisconnected = onDisconnected;
    mqttClient.onConnected = onConnected;
    mqttClient.onSubscribed = onSubscribed;
    final connMessage = MqttConnectMessage() ///create the connection
        .withClientIdentifier("flutter_client_1234")
        .startClean(); ///no session is saved between connections
    mqttClient.connectionMessage = connMessage;
    try {
      await mqttClient.connect();
      if (mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
        print("MQTT Connected doneeeeeeeeee from hiveee hiiiii");
        _autoSubscribe();
      } else {
        print(" MQTT Connection Failed with erroror: ${mqttClient.connectionStatus}");
        mqttClient.disconnect();
      }
    } catch (e) {
      print(" MQTT Connection Exception: $e");
      mqttClient.disconnect();
    } finally {
      _isConnecting = false;
    }
  }
  void onConnected() => print(" MQTT Connected!from hiveeeeee"); ///like events
  void onDisconnected() => print(" MQTT Disconnected!");
  void onSubscribed(MqttSubscription subscription) { ///prints the subscribed topic
    print("Subscribed to: ${subscription.topic} with QoS: ${subscription.maximumQos}");
  }
  void publishToMQTT(String topic, String message) {  ///takes the topic and message as a param
    if (mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
      Uint8Buffer payload = Uint8Buffer(); ///transform the text to into bytes
      ///encode it cause we use binary
      payload.addAll(utf8.encode(message));
      mqttClient.publishMessage(topic, MqttQos.atLeastOnce, payload);
      print(" Published to MQTT: $message");
    } else {
      print(" MQTT Not Connected. Attempting Reconnect...");
      setupMQTT();
    }
  }
  void _autoSubscribe() {
    List<String> topics = ["hive/response","hive/response2","hive/flutter"];
    for (String topic in topics) {
      mqttClient.subscribe(topic, MqttQos.atMostOnce);
    }

    mqttClient.updates.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage receivedMessage = messages[0].payload as MqttPublishMessage;
      final Uint8Buffer? payloadBuffer = receivedMessage.payload.message;
      if (payloadBuffer == null || payloadBuffer.isEmpty) {
        print(" Received empty payload");
        return;
      }
      final String message = utf8.decode(payloadBuffer.toList());
      print("MQTT Message Received on [${messages[0].topic}]: $message");
    });

    print("Subscribed and Listening for Messages...");
  }
}