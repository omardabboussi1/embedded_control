import 'package:flutter/material.dart';
import '../models/device_state.dart';
import '../theme/app_theme.dart';

class LoadCard extends StatelessWidget {
  final LoadState loadState;
  final VoidCallback onToggle;
  final bool isLoading;

  const LoadCard({
    super.key,
    required this.loadState,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: AppTheme.glassDecoration(
        glowColor: loadState.isOn ? AppTheme.accentGreen : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLoading ? null : onToggle,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon with glow
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: loadState.statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: loadState.isOn
                            ? [
                                BoxShadow(
                                  color:
                                      AppTheme.accentGreen.withOpacity(0.25),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        loadState.icon,
                        color: loadState.statusColor,
                        size: 28,
                      ),
                    ),
                    // Toggle switch
                    _buildToggle(),
                  ],
                ),
                const SizedBox(height: 16),
                // Load name
                Text(
                  loadState.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: loadState.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loadState.statusText,
                    style: TextStyle(
                      color: loadState.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Last toggle time
                if (loadState.lastToggled != null)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: AppTheme.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(loadState.lastToggled!),
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppTheme.accentCyan,
        ),
      );
    }

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 56,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: loadState.isOn ? AppTheme.greenGradient : null,
          color: loadState.isOn ? null : AppTheme.surfaceDark,
          border: Border.all(
            color: loadState.isOn
                ? Colors.transparent
                : AppTheme.dividerColor,
            width: 1.5,
          ),
          boxShadow: loadState.isOn
              ? [
                  BoxShadow(
                    color: AppTheme.accentGreen.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          alignment:
              loadState.isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}
