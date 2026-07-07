import 'package:flutter/material.dart';

import '../models/comprobante_pago.dart';
import '../theme/app_theme.dart';

class ComprobanteScreen extends StatelessWidget {
  final String matricula;
  final String metodoPagoNombre;
  final List<ComprobantePago> comprobantes;

  const ComprobanteScreen({
    super.key,
    required this.matricula,
    required this.metodoPagoNombre,
    required this.comprobantes,
  });

  double get _total => comprobantes.fold(0, (total, c) => total + c.monto);

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.now();
    final fechaTexto =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Comprobante de pago'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.success, size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pago aprobado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Aeronave $matricula · $metodoPagoNombre',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Fecha', style: TextStyle(color: Colors.grey)),
                              Text(fechaTexto, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Comprobantes generados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  for (final comprobante in comprobantes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.description_outlined, color: AppColors.success, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(comprobante.numeroComprobante, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              Text(
                                'Bs. ${comprobante.monto.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total pagado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text(
                          'Bs. ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
