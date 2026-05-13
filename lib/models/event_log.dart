import 'package:flutter/material.dart';

enum EventCategory { command, alarm, system, communication }

enum EventSeverity { info, warning, error, critical }

class EventLog {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final EventCategory category;
  final EventSeverity severity;
  final bool isRead;

  const EventLog({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.category = EventCategory.system,
    this.severity = EventSeverity.info,
    this.isRead = false,
  });

  EventLog copyWith({bool? isRead}) {
    return EventLog(
      id: id,
      title: title,
      description: description,
      timestamp: timestamp,
      category: category,
      severity: severity,
      isRead: isRead ?? this.isRead,
    );
  }

  IconData get categoryIcon {
    switch (category) {
      case EventCategory.command:
        return Icons.touch_app_rounded;
      case EventCategory.alarm:
        return Icons.warning_amber_rounded;
      case EventCategory.system:
        return Icons.settings_rounded;
      case EventCategory.communication:
        return Icons.cell_tower_rounded;
    }
  }

  Color get severityColor {
    switch (severity) {
      case EventSeverity.info:
        return const Color(0xFF00D4FF);
      case EventSeverity.warning:
        return const Color(0xFFFF9800);
      case EventSeverity.error:
        return const Color(0xFFFF5252);
      case EventSeverity.critical:
        return const Color(0xFFD50000);
    }
  }

  String get categoryText {
    switch (category) {
      case EventCategory.command:
        return 'Commande';
      case EventCategory.alarm:
        return 'Alarme';
      case EventCategory.system:
        return 'Système';
      case EventCategory.communication:
        return 'Communication';
    }
  }

  // Demo events
  static List<EventLog> demoEvents() {
    final now = DateTime.now();
    return [
      EventLog(
        id: '1',
        title: 'LOAD 1 activée',
        description: 'Charge 1 mise en marche via commande SMS',
        timestamp: now.subtract(const Duration(minutes: 5)),
        category: EventCategory.command,
        severity: EventSeverity.info,
      ),
      EventLog(
        id: '2',
        title: 'Perte signal GSM',
        description: 'Signal GSM perdu pendant 30 secondes',
        timestamp: now.subtract(const Duration(minutes: 15)),
        category: EventCategory.communication,
        severity: EventSeverity.warning,
      ),
      EventLog(
        id: '3',
        title: 'Surintensité LOAD 2',
        description: 'Courant mesuré: 5.2A (seuil: 5.0A)',
        timestamp: now.subtract(const Duration(hours: 1)),
        category: EventCategory.alarm,
        severity: EventSeverity.error,
      ),
      EventLog(
        id: '4',
        title: 'Système démarré',
        description: 'Initialisation complète du firmware v1.0',
        timestamp: now.subtract(const Duration(hours: 2)),
        category: EventCategory.system,
        severity: EventSeverity.info,
      ),
      EventLog(
        id: '5',
        title: 'Connexion GPRS établie',
        description: 'Connexion au serveur distant réussie',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 5)),
        category: EventCategory.communication,
        severity: EventSeverity.info,
      ),
      EventLog(
        id: '6',
        title: 'LOAD 2 désactivée',
        description: 'Charge 2 arrêtée suite à alarme surintensité',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 2)),
        category: EventCategory.command,
        severity: EventSeverity.warning,
      ),
      EventLog(
        id: '7',
        title: 'Batterie faible',
        description: 'Tension batterie: 11.2V (seuil: 11.5V)',
        timestamp: now.subtract(const Duration(hours: 3)),
        category: EventCategory.alarm,
        severity: EventSeverity.critical,
      ),
      EventLog(
        id: '8',
        title: 'SMS reçu',
        description: 'Commande reçue du numéro +213 555 123456',
        timestamp: now.subtract(const Duration(hours: 4)),
        category: EventCategory.communication,
        severity: EventSeverity.info,
      ),
    ];
  }
}
