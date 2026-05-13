import 'package:flutter/material.dart';
import '../models/device_state.dart';
import '../models/event_log.dart';
import 'mqtt_service.dart';

/// Service principal — relie le MqttService à l'état de l'interface.
class GsmService extends ChangeNotifier {
  DeviceState _deviceState = DeviceState.demo();
  List<EventLog> _events = EventLog.demoEvents();
  bool _isLoading = false;

  final MqttService mqttService = MqttService();

  DeviceState get deviceState => _deviceState;
  List<EventLog> get events => _events;
  bool get isLoading => _isLoading;

  int get unreadEventCount => _events.where((e) => !e.isRead).length;

  GsmService() {
    // Écouter les changements MQTT pour mettre à jour l'UI
    mqttService.addListener(_onMqttUpdate);
    // Se connecter au broker
    _connectMqtt();
  }

  Future<void> _connectMqtt() async {
    _isLoading = true;
    notifyListeners();

    final success = await mqttService.connect();

    _addEvent(
      title: success ? 'MQTT Connecté' : 'MQTT Échec connexion',
      description: success
          ? 'Connecté à ${mqttService.broker}:${mqttService.port}'
          : 'Impossible de se connecter au broker',
      category: EventCategory.communication,
      severity: success ? EventSeverity.info : EventSeverity.warning,
    );

    // Demander le statut initial
    if (success) {
      await mqttService.requestStatus();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Appelé quand le MqttService reçoit une mise à jour
  void _onMqttUpdate() {
    // Only broker status messages should rewrite both load states.
    // Other MQTT notifications like connect/disconnect/publish should
    // only update connection metadata and keep the optimistic UI state.
    if (mqttService.lastUpdate != null) {
      final load1On = mqttService.load1Status == 'ON';
      final load2On = mqttService.load2Status == 'ON';

      _deviceState = _deviceState.copyWith(
        load1: _deviceState.load1.copyWith(
          status: load1On ? LoadStatus.on : LoadStatus.off,
          currentAmps: load1On ? 2.4 : 0.0,
          lastToggled: mqttService.lastUpdate ?? _deviceState.load1.lastToggled,
        ),
        load2: _deviceState.load2.copyWith(
          status: load2On ? LoadStatus.on : LoadStatus.off,
          currentAmps: load2On ? 1.8 : 0.0,
          lastToggled: mqttService.lastUpdate ?? _deviceState.load2.lastToggled,
        ),
        isConnected: mqttService.isConnected,
        lastUpdate: mqttService.lastUpdate ?? _deviceState.lastUpdate,
      );
    } else {
      _deviceState = _deviceState.copyWith(
        isConnected: mqttService.isConnected,
        lastUpdate: _deviceState.lastUpdate,
      );
    }

    notifyListeners();
  }

  // ─── Toggle Load via MQTT ───
  Future<void> toggleLoad(String loadId) async {
    _isLoading = true;
    notifyListeners();

    bool turnOn;
    if (loadId == 'load_1') {
      turnOn = !_deviceState.load1.isOn;
    } else if (loadId == 'load_2') {
      turnOn = !_deviceState.load2.isOn;
    } else {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Envoyer via MQTT
    final sent = await mqttService.toggleLoad(loadId, turnOn);

    _addEvent(
      title: '${loadId == "load_1" ? "LOAD 1" : "LOAD 2"} ${turnOn ? "activée" : "désactivée"}',
      description: sent
          ? 'Commande MQTT envoyée'
          : 'Echec envoi MQTT (vérifier broker/port)',
      category: EventCategory.command,
      severity: sent ? EventSeverity.info : EventSeverity.warning,
    );

    if (sent) {
      // Mise à jour locale optimiste uniquement si la commande est publiée.
      if (loadId == 'load_1') {
        _deviceState = _deviceState.copyWith(
          load1: _deviceState.load1.copyWith(
            status: turnOn ? LoadStatus.on : LoadStatus.off,
            currentAmps: turnOn ? 2.4 : 0.0,
            lastToggled: DateTime.now(),
          ),
        );
      } else {
        _deviceState = _deviceState.copyWith(
          load2: _deviceState.load2.copyWith(
            status: turnOn ? LoadStatus.on : LoadStatus.off,
            currentAmps: turnOn ? 1.8 : 0.0,
            lastToggled: DateTime.now(),
          ),
        );
      }

      _deviceState = _deviceState.copyWith(lastUpdate: DateTime.now());
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Refresh ───
  Future<void> refreshState() async {
    _isLoading = true;
    notifyListeners();

    if (mqttService.isConnected) {
      await mqttService.requestStatus();
      await Future.delayed(const Duration(seconds: 2));
    } else {
      await _connectMqtt();
    }

    _deviceState = _deviceState.copyWith(
      gsm: _deviceState.gsm.copyWith(
        signalStrength: 65 + (DateTime.now().second % 30),
      ),
      lastUpdate: DateTime.now(),
    );

    _isLoading = false;
    notifyListeners();
  }

  // ─── Send Raw Command ───
  Future<bool> sendSmsCommand(String command) async {
    _isLoading = true;
    notifyListeners();

    final sent = await mqttService.sendCommand(command);

    _addEvent(
      title: sent ? 'Commande MQTT envoyée' : 'Commande MQTT non envoyée',
      description: sent
          ? 'Topic: relay/cmd → $command'
          : 'Echec envoi MQTT (vérifier broker/port)',
      category: EventCategory.communication,
      severity: sent ? EventSeverity.info : EventSeverity.warning,
    );

    _isLoading = false;
    notifyListeners();
    return sent;
  }

  // ─── Mark Event Read ───
  void markEventRead(String eventId) {
    _events = _events.map((e) {
      if (e.id == eventId) return e.copyWith(isRead: true);
      return e;
    }).toList();
    notifyListeners();
  }

  void markAllEventsRead() {
    _events = _events.map((e) => e.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  void clearEvents() {
    _events = [];
    notifyListeners();
  }

  void _addEvent({
    required String title,
    required String description,
    EventCategory category = EventCategory.system,
    EventSeverity severity = EventSeverity.info,
  }) {
    _events.insert(
      0,
      EventLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        timestamp: DateTime.now(),
        category: category,
        severity: severity,
      ),
    );
  }

  @override
  void dispose() {
    mqttService.removeListener(_onMqttUpdate);
    mqttService.disconnect();
    super.dispose();
  }
}
