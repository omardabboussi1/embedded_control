import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gsm_service.dart';
import '../theme/app_theme.dart';
import '../widgets/load_card.dart';

class LoadControlScreen extends StatelessWidget {
  const LoadControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GsmService>(
      builder: (context, gsm, _) {
        final state = gsm.deviceState;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration(),
              child: Column(
                children: [
                  Icon(
                    Icons.power_settings_new_rounded,
                    color: AppTheme.accentCyan,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pilotage des charges',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contrôle ON/OFF des charges électriques',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Load 1
            _buildSectionLabel('Charge 1'),
            const SizedBox(height: 10),
            LoadCard(
              loadState: state.load1,
              onToggle: () => gsm.toggleLoad('load_1'),
              isLoading: gsm.isLoading,
            ),
            const SizedBox(height: 10),
            _buildLoadDetails(state.load1),

            const SizedBox(height: 28),

            // Load 2
            _buildSectionLabel('Charge 2'),
            const SizedBox(height: 10),
            LoadCard(
              loadState: state.load2,
              onToggle: () => gsm.toggleLoad('load_2'),
              isLoading: gsm.isLoading,
            ),
            const SizedBox(height: 10),
            _buildLoadDetails(state.load2),

            const SizedBox(height: 28),

            // Quick actions
            Text(
              'Actions rapides',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.flash_on_rounded,
                    label: 'Tout activer',
                    color: AppTheme.accentGreen,
                    onTap: () async {
                      if (!state.load1.isOn) await gsm.toggleLoad('load_1');
                      if (!state.load2.isOn) await gsm.toggleLoad('load_2');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.flash_off_rounded,
                    label: 'Tout désactiver',
                    color: AppTheme.accentRed,
                    onTap: () async {
                      if (state.load1.isOn) await gsm.toggleLoad('load_1');
                      if (state.load2.isOn) await gsm.toggleLoad('load_2');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Demander le statut
            _buildQuickAction(
              context,
              icon: Icons.info_outline_rounded,
              label: 'Demander STATUS via MQTT',
              color: AppTheme.accentCyan,
              onTap: () async {
                final sent = await gsm.mqttService.requestStatus();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: sent
                          ? AppTheme.accentGreen
                          : AppTheme.accentRed,
                      content: Text(sent
                          ? 'Demande STATUS envoyée via MQTT'
                          : 'Echec envoi STATUS (vérifier broker/port)'),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 14),

            // Envoyer commande MQTT
            _buildQuickAction(
              context,
              icon: Icons.send_rounded,
              label: 'Envoyer commande MQTT',
              color: AppTheme.accentBlue,
              onTap: () => _showCommandDialog(context, gsm),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadDetails(dynamic load) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(borderRadius: 14),
      child: Column(
        children: [
          _buildDetailRow(
              'État', load.statusText, load.statusColor),
          const SizedBox(height: 8),
          _buildDetailRow(
              'Dernière action',
              load.lastToggled != null
                  ? _formatDateTime(load.lastToggled)
                  : 'N/A',
              AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.glassDecoration(borderRadius: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCommandDialog(BuildContext context, GsmService gsm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.send_rounded, color: AppTheme.accentCyan),
            const SizedBox(width: 10),
            Text('Commande MQTT',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrez la commande à publier sur relay/cmd',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ex: LOAD1_ON',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                gsm.sendSmsCommand(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.accentGreen,
                    content: Text('Commande envoyée: ${controller.text}'),
                  ),
                );
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
