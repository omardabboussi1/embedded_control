import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gsm_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _brokerController = TextEditingController();
  final _portController = TextEditingController();
  final _intervalController = TextEditingController(text: '30');

  bool _notificationsEnabled = true;
  bool _autoReconnect = true;
  bool _smsAlerts = true;
  bool _gprsReporting = false;

  @override
  void initState() {
    super.initState();
    final mqtt = context.read<GsmService>().mqttService;
    _brokerController.text = mqtt.broker;
    _portController.text = mqtt.port.toString();
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Module configuration
        _buildSectionHeader('Configuration MQTT', Icons.cloud_rounded),
        const SizedBox(height: 12),
        _buildInputTile(
          label: 'Broker MQTT',
          controller: _brokerController,
          icon: Icons.dns_rounded,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 10),
        _buildInputTile(
          label: 'Port',
          controller: _portController,
          icon: Icons.numbers_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        _buildInputTile(
          label: 'Intervalle de reporting (sec)',
          controller: _intervalController,
          icon: Icons.timer_rounded,
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 28),

        // Notifications
        _buildSectionHeader('Notifications', Icons.notifications_rounded),
        const SizedBox(height: 12),
        _buildToggleTile(
          label: 'Notifications push',
          subtitle: 'Recevoir les alertes en temps réel',
          icon: Icons.notifications_active_rounded,
          value: _notificationsEnabled,
          onChanged: (v) => setState(() => _notificationsEnabled = v),
        ),
        _buildToggleTile(
          label: 'Alertes SMS',
          subtitle: 'Envoyer les alarmes par SMS',
          icon: Icons.sms_rounded,
          value: _smsAlerts,
          onChanged: (v) => setState(() => _smsAlerts = v),
        ),

        const SizedBox(height: 28),

        // Connection
        _buildSectionHeader('Connexion', Icons.wifi_rounded),
        const SizedBox(height: 12),
        _buildToggleTile(
          label: 'Reconnexion automatique',
          subtitle: 'Reconnecter automatiquement en cas de perte',
          icon: Icons.autorenew_rounded,
          value: _autoReconnect,
          onChanged: (v) => setState(() => _autoReconnect = v),
        ),
        _buildToggleTile(
          label: 'Reporting GPRS',
          subtitle: 'Envoyer les données en continu via GPRS',
          icon: Icons.cloud_upload_rounded,
          value: _gprsReporting,
          onChanged: (v) => setState(() => _gprsReporting = v),
        ),

        const SizedBox(height: 28),

        // Security
        _buildSectionHeader('Sécurité', Icons.shield_rounded),
        const SizedBox(height: 12),
        _buildActionTile(
          label: 'Changer le code PIN',
          subtitle: 'Modifier le mot de passe d\'accès',
          icon: Icons.lock_rounded,
          color: AppTheme.accentCyan,
          onTap: () => _showChangePinDialog(context),
        ),
        _buildActionTile(
          label: 'Numéros autorisés',
          subtitle: 'Gérer les numéros pouvant envoyer des commandes',
          icon: Icons.phone_locked_rounded,
          color: AppTheme.accentBlue,
          onTap: () => _showAuthorizedNumbers(context),
        ),

        const SizedBox(height: 28),

        // About
        _buildSectionHeader('À propos', Icons.info_outline_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAboutRow('Application', 'EmbedControl v1.0'),
              _buildAboutRow('Firmware', 'v1.0 (Build 2026.03)'),
              _buildAboutRow('Module GSM', 'SIM800L'),
              _buildAboutRow('Protocole', 'AT Commands + SMS'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final gsm = context.read<GsmService>();
                    gsm.mqttService.updateBroker(
                      _brokerController.text.trim(),
                      int.tryParse(_portController.text.trim()) ??
                          (kIsWeb ? 8884 : 1883),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.accentGreen,
                        content: const Text('Paramètres MQTT sauvegardés'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Sauvegarder'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Logout
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            icon: Icon(Icons.logout_rounded, color: AppTheme.accentRed),
            label: Text(
              'Déconnexion',
              style: TextStyle(color: AppTheme.accentRed),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.accentRed.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.accentCyan, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInputTile({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(borderRadius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(borderRadius: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentCyan, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentCyan,
            activeTrackColor: AppTheme.accentCyan.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.glassDecoration(borderRadius: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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

  void _showChangePinDialog(BuildContext context) {
    final currentPin = TextEditingController();
    final newPin = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Changer le PIN',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(hintText: 'PIN actuel'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(hintText: 'Nouveau PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.accentGreen,
                  content: const Text('PIN modifié avec succès'),
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showAuthorizedNumbers(BuildContext context) {
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
            Text(
              'Numéros autorisés',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _buildPhoneNumber('+213 555 123456', 'Administrateur'),
            _buildPhoneNumber('+213 555 789012', 'Opérateur'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add_rounded, color: AppTheme.accentCyan),
                label: Text('Ajouter un numéro',
                    style: TextStyle(color: AppTheme.accentCyan)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppTheme.accentCyan.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumber(String number, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassDecoration(borderRadius: 12),
      child: Row(
        children: [
          Icon(Icons.phone_rounded, color: AppTheme.accentGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number,
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(role,
                    style:
                        TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.delete_rounded,
                color: AppTheme.accentRed, size: 20),
          ),
        ],
      ),
    );
  }
}
