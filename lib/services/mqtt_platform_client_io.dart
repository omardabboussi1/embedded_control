import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createServerClient(
  String host,
  String clientId,
  int port,
  bool secure,
) {
  final serverClient = MqttServerClient(host, clientId);
  serverClient.port = port;
  serverClient.secure = secure;
  return serverClient;
}
