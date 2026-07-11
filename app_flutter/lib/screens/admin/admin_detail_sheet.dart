import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AdminDetailRow {
  final String label;
  final String? value;
  final IconData icon;

  const AdminDetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });
}

Future<void> showAdminDetailSheet({
  required BuildContext context,
  required String title,
  required IconData icon,
  required List<AdminDetailRow> rows,
  String? statusLabel,
  Color? statusColor,
}) {
  final visibleRows = rows
      .where((row) => row.value != null && row.value!.trim().isNotEmpty)
      .toList();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (statusLabel != null && statusColor != null)
                    AppStatusChip(
                      label: statusLabel,
                      color: statusColor,
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              for (final row in visibleRows) _DetailRow(row: row),
              if (visibleRows.isEmpty)
                const Text(
                  'No hay detalles disponibles.',
                  style: TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Listo'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  final AdminDetailRow row;

  const _DetailRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(row.icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  row.value!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
