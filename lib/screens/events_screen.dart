import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_log.dart';
import '../services/gsm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/event_tile.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  EventCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<GsmService>(
      builder: (context, gsm, _) {
        final events = _selectedCategory == null
            ? gsm.events
            : gsm.events
                .where((e) => e.category == _selectedCategory)
                .toList();

        return Column(
          children: [
            // Filter chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                        null, 'Tous', Icons.list_rounded, gsm.events.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        EventCategory.command,
                        'Commandes',
                        Icons.touch_app_rounded,
                        gsm.events
                            .where(
                                (e) => e.category == EventCategory.command)
                            .length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        EventCategory.alarm,
                        'Alarmes',
                        Icons.warning_amber_rounded,
                        gsm.events
                            .where((e) => e.category == EventCategory.alarm)
                            .length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        EventCategory.system,
                        'Système',
                        Icons.settings_rounded,
                        gsm.events
                            .where(
                                (e) => e.category == EventCategory.system)
                            .length),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        EventCategory.communication,
                        'Comm.',
                        Icons.cell_tower_rounded,
                        gsm.events
                            .where((e) =>
                                e.category == EventCategory.communication)
                            .length),
                  ],
                ),
              ),
            ),

            // Actions bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${events.length} événement(s)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: gsm.markAllEventsRead,
                        icon: Icon(Icons.done_all_rounded,
                            color: AppTheme.accentCyan, size: 18),
                        label: Text(
                          'Tout lire',
                          style: TextStyle(
                              color: AppTheme.accentCyan, fontSize: 12),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmClear(context, gsm),
                        icon: Icon(Icons.delete_sweep_rounded,
                            color: AppTheme.accentRed, size: 18),
                        label: Text(
                          'Effacer',
                          style: TextStyle(
                              color: AppTheme.accentRed, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Events list
            Expanded(
              child: events.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return EventTile(
                          event: events[index],
                          onTap: () {
                            gsm.markEventRead(events[index].id);
                            _showEventDetail(context, events[index]);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(
      EventCategory? category, String label, IconData icon, int count) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentCyan.withOpacity(0.15)
              : AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentCyan.withOpacity(0.4)
                : AppTheme.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentCyan : AppTheme.textMuted,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentCyan.withOpacity(0.2)
                    : AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.accentCyan
                      : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded,
              color: AppTheme.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'Aucun événement',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Les événements apparaîtront ici',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showEventDetail(BuildContext context, EventLog event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: event.severityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    event.categoryIcon,
                    color: event.severityColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        event.categoryText,
                        style: TextStyle(
                          color: event.severityColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              event.description,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    color: AppTheme.textMuted, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${event.timestamp.day.toString().padLeft(2, '0')}/'
                  '${event.timestamp.month.toString().padLeft(2, '0')}/'
                  '${event.timestamp.year} '
                  '${event.timestamp.hour.toString().padLeft(2, '0')}:'
                  '${event.timestamp.minute.toString().padLeft(2, '0')}:'
                  '${event.timestamp.second.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, GsmService gsm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Effacer le journal',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Supprimer tous les événements ?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              gsm.clearEvents();
              Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Effacer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
