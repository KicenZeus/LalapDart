import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'DRAFT':
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        label = 'Draf';
        icon = Icons.edit_note;
        break;
      case 'MENUNGGU_VERIFIKASI':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        label = 'Menunggu Verifikasi';
        icon = Icons.hourglass_top;
        break;
      case 'PERLU_PERBAIKAN':
        bgColor = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        label = 'Perlu Perbaikan';
        icon = Icons.warning_amber_rounded;
        break;
      case 'DISETUJUI':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        label = 'Disetujui';
        icon = Icons.check_circle;
        break;
      case 'DITOLAK':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        label = 'Ditolak';
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withAlpha(76), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
