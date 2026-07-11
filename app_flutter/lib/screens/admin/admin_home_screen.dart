import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/usuario_admin.dart';
import '../../theme/app_theme.dart';
import 'aeropuertos_screen.dart';
import 'aeronaves_screen.dart';
import 'asignaciones_hangar_screen.dart';
import 'auditoria_screen.dart';
import 'catalogos_screen.dart';
import 'hangares_screen.dart';
import 'liquidaciones_screen.dart';
import 'operaciones_screen.dart';
import 'pagos_screen.dart';
import 'propietarios_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final UsuarioAdmin usuarioAdmin;

  const AdminHomeScreen({super.key, required this.usuarioAdmin});

  String get _nombreVisible {
    final partes = usuarioAdmin.nombre.trim().split(RegExp(r'\s+'));
    final nombre = partes.isEmpty || partes.first.isEmpty
        ? usuarioAdmin.nombre
        : partes.first;
    if (nombre.isEmpty) return nombre;
    return nombre[0].toUpperCase() + nombre.substring(1).toLowerCase();
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel administrativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hola, $_nombreVisible 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            AppStatusChip(
              label: usuarioAdmin.rol,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 28),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columnas = constraints.maxWidth >= 760 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: columnas,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: columnas == 4 ? 1.25 : 1.1,
                    children: [
                      _AdminActionCard(
                        icon: Icons.person_outline,
                        label: 'Propietarios',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PropietariosScreen(),
                          ),
                        ),
                      ),
                      _AdminActionCard(
                        icon: Icons.flight,
                        label: 'Aeronaves',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AeronavesScreen(),
                          ),
                        ),
                      ),
                      _AdminActionCard(
                        icon: Icons.local_airport_outlined,
                        label: 'Aeropuertos',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AeropuertosScreen(),
                          ),
                        ),
                      ),
                      _AdminActionCard(
                        icon: Icons.warehouse_outlined,
                        label: 'Hangares',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HangaresScreen(),
                          ),
                        ),
                      ),
                      _AdminActionCard(
                        icon: Icons.assignment_turned_in_outlined,
                        label: 'Asignaciones',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AsignacionesHangarScreen(),
                          ),
                        ),
                      ),
                      _AdminActionCard(
                        icon: Icons.flight_takeoff,
                        label: 'Operaciones',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OperacionesScreen(),
                          ),
                        ),
                      ),
                      _AdminActionCard(
                        icon: Icons.receipt_long,
                        label: 'Liquidaciones',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LiquidacionesScreen(),
                          ),
                        ),
                      ),
                      _AdminActionCard(
                        icon: Icons.category_outlined,
                        label: 'Catalogos',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CatalogosScreen(),
                          ),
                        ),
                      ),
                      _AdminActionCard(
                        icon: Icons.payments_outlined,
                        label: 'Pagos',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PagosScreen(),
                          ),
                        ),
                      ),
                      _AdminActionCard(
                        icon: Icons.manage_search_outlined,
                        label: 'Auditoria',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AuditoriaScreen(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
