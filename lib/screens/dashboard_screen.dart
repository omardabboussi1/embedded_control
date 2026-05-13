import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gsm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/load_card.dart';
import '../widgets/status_indicator.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GsmService>(
      builder: (context, gsm, _) {
        final state = gsm.deviceState;
        return RefreshIndicator(
          color: AppTheme.accentCyan,
          backgroundColor: AppTheme.surfaceDark,
          onRefresh: gsm.refreshState,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Connection status header
              _buildConnectionBanner(state.isConnected),
              const SizedBox(height: 20),

              // Quick stats row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.cell_tower_rounded,
                      label: 'Signal',
                      value: '${state.gsm.signalStrength}%',
                      color: state.gsm.signalColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.cloud_done_rounded,
                      label: 'MQTT',
                      value: state.isConnected ? 'OK' : '---',
                      color: state.isConnected
                          ? AppTheme.accentGreen
                          : AppTheme.accentRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.sim_card_rounded,
                      label: 'Réseau',
                      value: state.gsm.networkType,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Load control cards
              Text(
                'Charges électriques',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              LoadCard(
                loadState: state.load1,
                onToggle: () => gsm.toggleLoad('load_1'),
                isLoading: gsm.isLoading,
              ),
              const SizedBox(height: 14),
              LoadCard(
                loadState: state.load2,
                onToggle: () => gsm.toggleLoad('load_2'),
                isLoading: gsm.isLoading,
              ),

              const SizedBox(height: 24),

              // System info section
              _buildSystemInfo(state, gsm),

              const SizedBox(height: 24),

              // Recent events
              _buildRecentEvents(context, gsm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionBanner(bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: (isConnected ? AppTheme.accentGreen : AppTheme.accentRed)
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isConnected ? AppTheme.accentGreen : AppTheme.accentRed)
              .withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          StatusIndicator(
            isActive: isConnected,
            label: isConnected ? 'Connecté au système' : 'Déconnecté',
            activeColor: AppTheme.accentGreen,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isConnected ? AppTheme.accentGreen : AppTheme.accentRed)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isConnected ? 'EN LIGNE' : 'HORS LIGNE',
              style: TextStyle(
                color: isConnected ? AppTheme.accentGreen : AppTheme.accentRed,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassDecoration(borderRadius: 16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo(dynamic state, GsmService gsm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppTheme.accentCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations système',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Opérateur', state.gsm.operator),
          _buildInfoRow('Réseau', state.gsm.networkType),
          _buildInfoRow('SIM', state.gsm.simStatus),
          _buildInfoRow('GPRS',
              state.gsm.gprsConnected ? 'Connecté' : 'Déconnecté'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEvents(BuildContext context, GsmService gsm) {
    final recentEvents = gsm.events.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Événements récents',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (gsm.unreadEventCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${gsm.unreadEventCount} nouveau(x)',
                  style: TextStyle(
                    color: AppTheme.accentRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ...recentEvents.map((event) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.glassDecoration(borderRadius: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: event.severityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      event.categoryIcon,
                      color: event.severityColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          event.description,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!event.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: event.severityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            )),
      ],
    );
  }
}
