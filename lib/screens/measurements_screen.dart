import 'package:flutter/material.dart';

import '../models/location_sample.dart';
import '../services/tracking_controller.dart';

class MeasurementsScreen extends StatefulWidget {
  final TrackingController trackingController;

  const MeasurementsScreen({super.key, required this.trackingController});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  bool _isUpdatingCollection = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesures de position')),
      body: AnimatedBuilder(
        animation: widget.trackingController,
        builder: (context, _) {
          final samples = widget.trackingController.samples.reversed.toList();
          final isCollecting = widget.trackingController.isCollecting;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Card(
                  elevation: 1,
                  child: SwitchListTile(
                    title: const Text('Localisation active'),
                    subtitle: Text(
                      isCollecting
                          ? 'Collecte GPS en cours'
                          : 'Collecte GPS arrêtée',
                    ),
                    value: isCollecting,
                    onChanged: _isUpdatingCollection
                        ? null
                        : (value) async {
                            setState(() => _isUpdatingCollection = true);
                            await widget.trackingController.setCollecting(value);
                            if (!mounted) return;
                            setState(() => _isUpdatingCollection = false);
                          },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    elevation: 1,
                    child: samples.isEmpty
                        ? const Center(
                            child: Text('Aucune mesure disponible pour le moment'),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Position')),
                                  DataColumn(label: Text('Heure')),
                                  DataColumn(label: Text('Précision')),
                                ],
                                rows: samples.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final sample = entry.value;
                                  return DataRow.byIndex(
                                    index: index,
                                    onSelectChanged: (_) =>
                                        Navigator.of(context).pop(sample),
                                    cells: [
                                      DataCell(
                                        Text(
                                          '${sample.latitude.toStringAsFixed(6)}, ${sample.longitude.toStringAsFixed(6)}',
                                        ),
                                      ),
                                      DataCell(Text(_formatLocalTime(sample))),
                                      DataCell(
                                        Text(
                                          '±${sample.accuracyMeters.toStringAsFixed(1)} m',
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatLocalTime(LocationSample sample) {
    final d = sample.measuredAtUtc.toLocal();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    final second = d.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
