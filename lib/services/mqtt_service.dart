import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'mqtt_platform_client_stub.dart'
    if (dart.library.io) 'mqtt_platform_client_io.dart'
    as mqtt_platform;

class MqttService extends ChangeNotifier {
  String broker;
  int port;
  String? username;
  String? password;

  static const String topicCmd = 'relay/cmd';
  static const String topicStatus = 'relay/status';

  MqttClient? client;

  bool isConnected = false;

  String load1Status = 'OFF';
  String load2Status = 'OFF';

  String lastMessage = '';
  DateTime? lastUpdate;
  Future<bool>? _connectFuture;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
      _updatesSubscription;
  Timer? _statusPollTimer;
  static const Duration _statusPollInterval = Duration(seconds: 30);
  static const bool _enableStatusPolling = false;
  static const Duration _minStatusInterval = Duration(seconds: 8);
  DateTime? _lastStatusRequestAt;

  MqttService({
    String? broker,
    int? port,
    String? username,
    String? password,
  })  : broker = broker ?? 'mountainroarer689.cloud.shiftr.io',
        port = port ?? (kIsWeb ? 443 : 1883),
        username = username ?? 'mountainroarer689',
        password = password ?? 'Lu0mBA93WrwJwQzS';

  /// CONNECT
  Future<bool> connect() async {
    if (isConnected) {
      return true;
    }
    if (_connectFuture != null) {
      return _connectFuture!;
    }

    _connectFuture = _connectInternal();
    final result = await _connectFuture!;
    _connectFuture = null;
    return result;
  }

  Future<bool> _connectInternal() async {
    try {
      _safeDisconnectCurrentClient();
      final clientId = _buildClientId();
      client = _createClient(clientId);
      client!.keepAlivePeriod = 60;
      client!.autoReconnect = !kIsWeb;
      client!.resubscribeOnAutoReconnect = true;
      client!.onConnected = _onConnected;
      client!.onDisconnected = _onDisconnected;
      client!.logging(on: true);
      if (kIsWeb) {
        client!.websocketProtocols = MqttClientConstants.protocolsMultipleDefault;
      }

      final connMsgBuilder = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();

      if (username != null && password != null) {
        connMsgBuilder.authenticateAs(username!, password!);
      }

      client!.connectionMessage = connMsgBuilder;
      debugPrint(
        'ℹ️ MQTT CONNECT ATTEMPT endpoint=${_endpointLabel()} '
        'clientId=$clientId mode=${kIsWeb ? "WebSocket" : "TCP"}',
      );

      await client!.connect();

      final status = client!.connectionStatus;
      if (status?.state == MqttConnectionState.connected) {
        isConnected = true;

        _subscribeToStatusTopic();
        _attachUpdatesListener();

        notifyListeners();
        return true;
      }

      debugPrint(
        '❌ MQTT ERROR: Connect failed: state=${status?.state} '
        'returnCode=${status?.returnCode}',
      );
    } catch (e) {
      debugPrint('❌ MQTT ERROR: $e');
      debugPrint(
        'ℹ️ Broker=$broker Port=$port Mode=${kIsWeb ? "WebSocket" : "TCP"}',
      );
    }

    isConnected = false;
    notifyListeners();
    return false;
  }

  /// DISCONNECT
  void disconnect() {
    _connectFuture = null;
    _stopStatusPolling();
    _safeDisconnectCurrentClient();
    isConnected = false;
    notifyListeners();
  }

  /// SEND COMMAND
  Future<bool> sendCommand(String cmd) async {
    if (cmd.trim().isEmpty) {
      return false;
    }

    if (!isConnected || client == null) {
      final connected = await connect();
      if (!connected || client == null) {
        debugPrint('❌ MQTT SEND FAILED: not connected');
        return false;
      }
    }

    final status = client!.connectionStatus;
    if (status?.state != MqttConnectionState.connected) {
      debugPrint(
        '❌ MQTT SEND FAILED: state=${status?.state} '
        'returnCode=${status?.returnCode}',
      );
      return false;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(cmd);

    try {
      client!.publishMessage(
        topicCmd,
        MqttQos.atMostOnce,
        builder.payload!,
      );
    } catch (e) {
      debugPrint('❌ MQTT PUBLISH FAILED: $e');
      return false;
    }

    lastMessage = cmd;
    notifyListeners();

    debugPrint('📤 MQTT PUBLISH topic=$topicCmd payload=$cmd');
    return true;
  }

  /// TOGGLE LOAD
  Future<bool> toggleLoad(String loadId, bool turnOn) async {
    String cmd = '';

    if (loadId == 'load_1') {
      cmd = turnOn ? 'ON1' : 'OFF1';
    } else if (loadId == 'load_2') {
      cmd = turnOn ? 'ON2' : 'OFF2';
    }

    return sendCommand(cmd);
  }

  /// REQUEST STATUS
  Future<bool> requestStatus() async {
    final now = DateTime.now();
    final last = _lastStatusRequestAt;
    if (last != null && now.difference(last) < _minStatusInterval) {
      debugPrint('ℹ️ MQTT STATUS skipped (throttled)');
      return true;
    }
    _lastStatusRequestAt = now;
    return sendCommand("STATUS");
  }

  /// UPDATE BROKER
  void updateBroker(String newBroker, int newPort, {String? newUsername, String? newPassword}) {
    broker = newBroker;
    port = newPort;
    username = newUsername ?? username;
    password = newPassword ?? password;
    if (isConnected) {
      disconnect();
    }
  }

  /// RECEIVE MESSAGE
  void _onMessage(List<MqttReceivedMessage<MqttMessage>> events) {
    if (events.isEmpty) {
      return;
    }

    final recMess = events[0].payload as MqttPublishMessage;

    final payload = MqttPublishPayload.bytesToStringAsString(
      recMess.payload.message,
    );

    debugPrint("📥 $payload");

    if (events[0].topic == topicStatus) {
      _parseStatus(payload);
    }
  }

  MqttClient _createClient(String clientId) {
    if (kIsWeb) {
      final wsBase = _resolveWebSocketBase();
      debugPrint('ℹ️ MQTT WS ENDPOINT: $wsBase:$port');
      return MqttBrowserClient.withPort(wsBase, clientId, port);
    }

    final host = _normalizeHost();
    return mqtt_platform.createServerClient(
      host,
      clientId,
      port,
      _isSecurePort(port),
    );
  }

  String _buildClientId() {
    return 'flutter_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _normalizeHost() {
    final uri = Uri.tryParse(broker);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host;
    }
    return broker;
  }

  String _resolveWebSocketBase() {
    final trimmed = broker.trim();
    final parsed = Uri.tryParse(trimmed);
    final host = parsed != null && parsed.host.isNotEmpty ? parsed.host : trimmed;
    final scheme = _isSecurePort(port) ? 'wss' : 'ws';
    // shiftr.io doesn't use /mqtt path, just the host
    if (host.contains('shiftr.io')) {
      return '$scheme://$host';
    }
    return '$scheme://$host/mqtt';
  }

  bool _isSecurePort(int brokerPort) {
    return brokerPort == 443 || brokerPort == 8883 || brokerPort == 8884;
  }

  String _endpointLabel() {
    if (kIsWeb) {
      return '${_resolveWebSocketBase()}:$port';
    }
    return '${_normalizeHost()}:$port';
  }

  void _onConnected() {
    isConnected = true;
    _subscribeToStatusTopic();
    _attachUpdatesListener();
    _startStatusPolling();
    requestStatus();
    notifyListeners();
    debugPrint('✅ MQTT CONNECTED: $broker:$port');
  }

  void _onDisconnected() {
    _stopStatusPolling();
    isConnected = false;
    notifyListeners();
    debugPrint('⚠️ MQTT DISCONNECTED: $broker:$port');
  }

  void _safeDisconnectCurrentClient() {
    final currentClient = client;
    if (currentClient == null) {
      return;
    }

    try {
      currentClient.disconnect();
    } catch (e) {
      debugPrint('⚠️ MQTT DISCONNECT IGNORE: $e');
    }

    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _stopStatusPolling();
    client = null;
  }

  void _startStatusPolling() {
    if (!_enableStatusPolling) {
      return;
    }
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(_statusPollInterval, (_) {
      if (!isConnected) {
        return;
      }
      requestStatus();
    });
  }

  void _stopStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
  }

  void _subscribeToStatusTopic() {
    final currentClient = client;
    if (currentClient == null) {
      return;
    }

    currentClient.subscribe(topicStatus, MqttQos.atMostOnce);
  }

  void _attachUpdatesListener() {
    final updates = client?.updates;
    if (updates == null) {
      return;
    }

    _updatesSubscription?.cancel();
    _updatesSubscription = updates.listen(_onMessage);
  }

  /// PARSE STATUS — supports JSON {"load1":"ON",...} and simple ON1/OFF1/ON2/OFF2
  void _parseStatus(String msg) {
    final trimmed = msg.trim().toUpperCase();
    debugPrint('📥 _parseStatus RAW: "$msg" (${msg.length} chars)');
    debugPrint('📥 _parseStatus TRIMMED: "$trimmed" (${trimmed.length} chars)');
    debugPrint('📥 _parseStatus BYTES: ${msg.codeUnits}');

    // Simple text commands
    switch (trimmed) {
      case 'ON1':
        load1Status = 'ON';
        lastUpdate = DateTime.now();
        notifyListeners();
        return;
      case 'OFF1':
        load1Status = 'OFF';
        lastUpdate = DateTime.now();
        notifyListeners();
        return;
      case 'ON2':
        load2Status = 'ON';
        lastUpdate = DateTime.now();
        notifyListeners();
        return;
      case 'OFF2':
        load2Status = 'OFF';
        lastUpdate = DateTime.now();
        notifyListeners();
        return;
    }

    // JSON format fallback
    try {
      final data = jsonDecode(msg);

      load1Status = data['load1'] ?? load1Status;
      load2Status = data['load2'] ?? load2Status;

      lastUpdate = DateTime.now();

      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ PARSE ERROR: unrecognized message '$msg'");
    }
  }
}
