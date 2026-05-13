import 'package:flutter/material.dart';

enum LoadStatus { on, off, error, unknown }

class LoadState {
  final String name;
  final String id;
  final LoadStatus status;
  final double currentAmps;
  final DateTime? lastToggled;
  final IconData icon;

  const LoadState({
    required this.name,
    required this.id,
    this.status = LoadStatus.off,
    this.currentAmps = 0.0,
    this.lastToggled,
    this.icon = Icons.power,
  });

  LoadState copyWith({
    String? name,
    String? id,
    LoadStatus? status,
    double? currentAmps,
    DateTime? lastToggled,
    IconData? icon,
  }) {
    return LoadState(
      name: name ?? this.name,
      id: id ?? this.id,
      status: status ?? this.status,
      currentAmps: currentAmps ?? this.currentAmps,
      lastToggled: lastToggled ?? this.lastToggled,
      icon: icon ?? this.icon,
    );
  }

  bool get isOn => status == LoadStatus.on;
  bool get isError => status == LoadStatus.error;

  Color get statusColor {
    switch (status) {
      case LoadStatus.on:
        return const Color(0xFF00E676);
      case LoadStatus.off:
        return const Color(0xFF8B92A5);
      case LoadStatus.error:
        return const Color(0xFFFF5252);
      case LoadStatus.unknown:
        return const Color(0xFFFF9800);
    }
  }

  String get statusText {
    switch (status) {
      case LoadStatus.on:
        return 'ACTIF';
      case LoadStatus.off:
        return 'INACTIF';
      case LoadStatus.error:
        return 'ERREUR';
      case LoadStatus.unknown:
        return 'INCONNU';
    }
  }
}

class GsmState {
  final int signalStrength; // 0-100
  final String operator;
  final bool isRegistered;
  final bool gprsConnected;
  final String simStatus;
  final String networkType; // 2G, GPRS, EDGE

  const GsmState({
    this.signalStrength = 0,
    this.operator = 'Inconnu',
    this.isRegistered = false,
    this.gprsConnected = false,
    this.simStatus = 'Non détectée',
    this.networkType = '---',
  });

  GsmState copyWith({
    int? signalStrength,
    String? operator,
    bool? isRegistered,
    bool? gprsConnected,
    String? simStatus,
    String? networkType,
  }) {
    return GsmState(
      signalStrength: signalStrength ?? this.signalStrength,
      operator: operator ?? this.operator,
      isRegistered: isRegistered ?? this.isRegistered,
      gprsConnected: gprsConnected ?? this.gprsConnected,
      simStatus: simStatus ?? this.simStatus,
      networkType: networkType ?? this.networkType,
    );
  }

  Color get signalColor {
    if (signalStrength > 70) return const Color(0xFF00E676);
    if (signalStrength > 40) return const Color(0xFFFF9800);
    return const Color(0xFFFF5252);
  }
}

class DeviceState {
  final LoadState load1;
  final LoadState load2;
  final GsmState gsm;
  final double batteryVoltage;
  final int batteryPercent;
  final double temperature;
  final bool isConnected;
  final DateTime lastUpdate;

  const DeviceState({
    required this.load1,
    required this.load2,
    required this.gsm,
    this.batteryVoltage = 12.0,
    this.batteryPercent = 100,
    this.temperature = 25.0,
    this.isConnected = false,
    required this.lastUpdate,
  });

  DeviceState copyWith({
    LoadState? load1,
    LoadState? load2,
    GsmState? gsm,
    double? batteryVoltage,
    int? batteryPercent,
    double? temperature,
    bool? isConnected,
    DateTime? lastUpdate,
  }) {
    return DeviceState(
      load1: load1 ?? this.load1,
      load2: load2 ?? this.load2,
      gsm: gsm ?? this.gsm,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      temperature: temperature ?? this.temperature,
      isConnected: isConnected ?? this.isConnected,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  // Demo state for UI preview
  factory DeviceState.demo() {
    return DeviceState(
      load1: LoadState(
        name: 'LOAD 1',
        id: 'load_1',
        status: LoadStatus.on,
        currentAmps: 2.4,
        lastToggled: DateTime.now().subtract(const Duration(hours: 2)),
        icon: Icons.lightbulb,
      ),
      load2: LoadState(
        name: 'LOAD 2',
        id: 'load_2',
        status: LoadStatus.off,
        currentAmps: 0.0,
        lastToggled: DateTime.now().subtract(const Duration(hours: 5)),
        icon: Icons.power,
      ),
      gsm: const GsmState(
        signalStrength: 78,
        operator: 'Djezzy',
        isRegistered: true,
        gprsConnected: true,
        simStatus: 'Prête',
        networkType: 'GPRS',
      ),
      batteryVoltage: 12.4,
      batteryPercent: 85,
      temperature: 32.5,
      isConnected: true,
      lastUpdate: DateTime.now(),
    );
  }
}
