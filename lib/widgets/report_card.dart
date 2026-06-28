import 'package:flutter/material.dart';

import '../models/report_model.dart';
import '../services/api_path.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const ReportCard({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLost = report.reportType == 'Lost';
    final typeColor = isLost ? Colors.orange.shade800 : Colors.blue.shade700;
    final typeBackground = isLost ? Colors.orange.shade50 : Colors.blue.shade50;
    final cardColor = report.status == 'Claimed'
        ? const Color(0xFFE4F7E9)
        : isLost
        ? const Color(0xFFFFF0DF)
        : const Color(0xFFE3EEFF);

    return Card(
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 86,
                  height: 86,
                  color: const Color(0xFFEAF1FB),
                  child: report.image.isEmpty
                      ? Icon(
                          isLost
                              ? Icons.search_off_rounded
                              : Icons.inventory_2_outlined,
                          size: 38,
                          color: typeColor,
                        )
                      : Image.network(
                          ApiPath.reportImage(report.image),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.broken_image_outlined,
                            color: typeColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            report.reportType,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _StatusLabel(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${report.category} • ${report.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.reportDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final String status;

  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final isClaimed = status == 'Claimed';
    return Text(
      status,
      style: TextStyle(
        color: isClaimed ? Colors.green.shade700 : Colors.blueGrey.shade700,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
