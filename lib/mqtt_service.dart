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
        print("MQTT Connected doneeeeeeeeee");
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

  void onConnected() => print(" MQTT Connected!"); ///like events
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
  void subscribeToMQTT(String topic) {
    if (mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
      mqttClient.subscribe(topic, MqttQos.atMostOnce);
      mqttClient.updates.listen((List<MqttReceivedMessage<MqttMessage>> messages) {

        ////extract the message and decode it
        final MqttPublishMessage receivedMessage = messages[0].payload as MqttPublishMessage;

        final Uint8Buffer? payloadBuffer = receivedMessage.payload.message;
        if (payloadBuffer == null || payloadBuffer.isEmpty) {
          print(" Received empty payload on [$topic]");
          return;
        }
        final String message = utf8.decode(payloadBuffer.toList());
        print("MQTT Message Received on [$topic]: $message");
      });
      print(" Subscribed to MQTT Topic: $topic");
    } else {
      print(" MQTT Not Connected. Cannot Subscribe.");
    }
  }
}
