import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y soporte')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HelpHeader(),
                    const SizedBox(height: 24),
                    Text(
                      'Preguntas frecuentes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _HelpTopicCard(
                      icon: Icons.flight_outlined,
                      question: '¿Cómo consulto una aeronave?',
                      answer:
                          'Ingresa la matrícula tal como aparece en el registro de la aeronave. Revisa las letras, los números y el guion antes de buscar.',
                    ),
                    const SizedBox(height: 10),
                    const _HelpTopicCard(
                      icon: Icons.search_off_outlined,
                      question: '¿Qué hago si la aeronave no aparece?',
                      answer:
                          'Verifica la matrícula e inténtalo nuevamente. Si el problema continúa, solicita asistencia a la administración aeroportuaria para confirmar que la aeronave esté registrada.',
                    ),
                    const SizedBox(height: 10),
                    const _HelpTopicCard(
                      icon: Icons.payments_outlined,
                      question: '¿Cómo realizo un pago?',
                      answer:
                          'Consulta la aeronave, revisa las liquidaciones pendientes, selecciona un método de pago y completa los datos solicitados. Confirma el monto antes de continuar.',
                    ),
                    const SizedBox(height: 10),
                    const _HelpTopicCard(
                      icon: Icons.sync_problem_outlined,
                      question: 'No sé si mi pago fue procesado',
                      answer:
                          'No realices otro pago de inmediato. Vuelve a consultar la matrícula y verifica si la obligación continúa pendiente. Si tienes dudas, solicita asistencia antes de repetir la operación.',
                      emphasized: true,
                    ),
                    const SizedBox(height: 10),
                    const _HelpTopicCard(
                      icon: Icons.receipt_long_outlined,
                      question: '¿Dónde encuentro el comprobante?',
                      answer:
                          'La app muestra el comprobante cuando el pago es aprobado. Anota su número y verifica que la matrícula, el monto y el método de pago sean correctos.',
                    ),
                    const SizedBox(height: 24),
                    const _SupportCard(),
                    const SizedBox(height: 14),
                    const _SecurityNotice(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.support_agent,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿En qué podemos ayudarte?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Encuentra respuestas sobre consultas, pagos y comprobantes.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpTopicCard extends StatelessWidget {
  final IconData icon;
  final String question;
  final String answer;
  final bool emphasized;

  const _HelpTopicCard({
    required this.icon,
    required this.question,
    required this.answer,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: emphasized ? AppColors.warning : Colors.grey.shade200,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: emphasized
                ? AppColors.warningBg
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: emphasized ? AppColors.warning : AppColors.primary,
          ),
        ),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        children: [Text(answer, style: const TextStyle(height: 1.45))],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_support_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  '¿Necesitas más ayuda?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Utiliza únicamente los canales oficiales publicados por la administración aeroportuaria o dirígete a la oficina administrativa de la sede.',
              style: TextStyle(height: 1.45),
            ),
            const SizedBox(height: 16),
            Text(
              'Ten a la mano:',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const _SupportDataRow(
              icon: Icons.flight,
              text: 'Matrícula de la aeronave',
            ),
            const _SupportDataRow(
              icon: Icons.schedule,
              text: 'Fecha y hora aproximada de la operación',
            ),
            const _SupportDataRow(
              icon: Icons.tag,
              text: 'Referencia o número de comprobante',
            ),
            const _SupportDataRow(
              icon: Icons.attach_money,
              text: 'Monto y método de pago',
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportDataRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SupportDataRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.warning),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protege tus datos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Nunca compartas contraseñas, códigos de verificación, CVV ni el número completo de tu tarjeta.',
                  style: TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
