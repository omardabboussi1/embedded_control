import 'package:mqtt_client/mqtt_client.dart';

MqttClient createServerClient(
  String host,
  String clientId,
  int port,
  bool secure,
) {
  throw UnsupportedError('Server MQTT client is unavailable on this platform');
}
