import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gsm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/signal_gauge.dart';
import '../widgets/status_indicator.dart';

class GsmStatusScreen extends StatelessWidget {
  const GsmStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GsmService>(
      builder: (context, gsm, _) {
        final state = gsm.deviceState.gsm;
        return RefreshIndicator(
          color: AppTheme.accentCyan,
          backgroundColor: AppTheme.surfaceDark,
          onRefresh: gsm.refreshState,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Signal gauge
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassDecoration(),
                  child: Column(
                    children: [
                      SignalGauge(
                        signalStrength: state.signalStrength,
                        size: 160,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Force du signal',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.signalStrength}% - ${_signalQuality(state.signalStrength)}',
                        style: TextStyle(
                          color: state.signalColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Connection statuses
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      icon: Icons.sim_card_rounded,
                      label: 'Carte SIM',
                      status: state.simStatus,
                      isActive: state.simStatus == 'Prête',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      icon: Icons.cell_tower_rounded,
                      label: 'Réseau',
                      status: state.isRegistered ? 'Enregistré' : 'Non enregistré',
                      isActive: state.isRegistered,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      icon: Icons.language_rounded,
                      label: 'GPRS',
                      status: state.gprsConnected ? 'Connecté' : 'Déconnecté',
                      isActive: state.gprsConnected,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      icon: Icons.network_cell_rounded,
                      label: 'Type réseau',
                      status: state.networkType,
                      isActive: state.networkType != '---',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Operator info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business_rounded,
                            color: AppTheme.accentCyan, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Informations opérateur',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Opérateur', state.operator),
                    _buildInfoRow('Type réseau', state.networkType),
                    _buildInfoRow('État SIM', state.simStatus),
                    _buildInfoRow('Enregistrement',
                        state.isRegistered ? 'Oui' : 'Non'),
                    _buildInfoRow(
                        'Connexion GPRS',
                        state.gprsConnected ? 'Active' : 'Inactive'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Signal bars visualization
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qualité signal',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSignalBars(state.signalStrength),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Refresh button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: gsm.isLoading ? null : gsm.refreshState,
                  icon: gsm.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryDark,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(gsm.isLoading
                      ? 'Actualisation...'
                      : 'Actualiser l\'état'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String status,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        borderRadius: 16,
        glowColor: isActive ? AppTheme.accentGreen : null,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? AppTheme.accentGreen : AppTheme.textMuted,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          StatusIndicator(
            isActive: isActive,
            label: status,
            activeColor: AppTheme.accentGreen,
          ),
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
          Text(label,
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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

  Widget _buildSignalBars(int strength) {
    const barCount = 5;
    final activeBars = (strength / 100 * barCount).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barCount, (index) {
        final isActive = index < activeBars;
        final height = 16.0 + (index * 10.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 20,
            height: height,
            decoration: BoxDecoration(
              gradient: isActive ? AppTheme.primaryGradient : null,
              color: isActive ? null : AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.accentCyan.withOpacity(0.3),
                        blurRadius: 6,
                      ),
                    ]
                  : [],
            ),
          ),
        );
      }),
    );
  }

  String _signalQuality(int strength) {
    if (strength > 80) return 'Excellent';
    if (strength > 60) return 'Bon';
    if (strength > 40) return 'Moyen';
    if (strength > 20) return 'Faible';
    return 'Très faible';
  }
}
