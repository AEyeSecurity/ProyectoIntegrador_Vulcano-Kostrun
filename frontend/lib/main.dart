//lib/main.dart
// ✅ FINAL - Con todas las rutas de configuración + CHAT + CALIFICACIONES

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/supabase_client.dart';
import 'services/menu_perfil/trabajo_service.dart';
import 'models/menu_perfil/trabajo_model.dart';
import 'screens/sign_in/login_screen.dart';
import 'screens/sign_in/account_type_selection_screen.dart';
import 'screens/sign_in/register_personal_screen.dart';
import 'screens/sign_in/register_empresarial_screen.dart';
import 'screens/sign_in/rubros_bubbles_screen.dart';
import 'screens/sign_in/role_selection_screen.dart';
import 'screens/sign_in/forgot_password_screen.dart';
import 'screens/menu_perfil/user_menu_screen.dart';
import 'screens/menu_perfil/trabajos/trabajos_screen.dart';
import 'screens/user/perfil_privado_screen.dart';
import 'screens/user/perfil_publico_screen.dart';
import 'screens/menu_perfil/ubicaciones/ubicaciones_screen.dart';
import 'screens/user/crear_ubicaciones_screen.dart';
import 'screens/menu_perfil/rubros/mis_rubros_screen.dart';
import 'screens/menu_perfil/calendario/calendar_screen.dart';
import 'screens/menu_perfil/agenda/agenda_lista_screen.dart';
import 'screens/menu_perfil/configuracion/configuracion_screen.dart';
import 'screens/menu_perfil/configuracion/editar_nombre_screen.dart';
import 'screens/menu_perfil/configuracion/cambiar_contrasena_screen.dart';
import 'screens/menu_perfil/configuracion/editar_email_screen.dart';
import 'screens/menu_perfil/configuracion/editar_telefono_screen.dart';
import 'screens/menu_perfil/configuracion/editar_foto_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/jobs/editar_trabajo_screen.dart';
import 'screens/empresa/editar_empleado_screen.dart';
import 'screens/empresa/mis_empleados_screen.dart';
import 'screens/empresa/agregar_empleado_screen.dart';
import 'models/empleado_empresa_model.dart';

import 'screens/jobs/postulaciones_trabajo_screen.dart';
import 'screens/jobs/mis_postulaciones_screen.dart';

import 'screens/jobs/gestionar_fotos_trabajo_screen.dart';
import 'screens/jobs/create_trabajo_screen.dart';
import 'screens/jobs/detalle_trabajo_screen.dart';
import 'screens/jobs/detalle_trabajo_propio_screen.dart';
import 'screens/user/unirse_empleadores_screen.dart';
import 'screens/user/unirse_empleados_screen.dart';

import 'screens/menu_perfil/chat/conversaciones_screen.dart';
import 'screens/menu_perfil/chat/chat_screen.dart';
import 'models/chat/conversacion_model.dart';

// ✅ NUEVO: Importar pantalla de calificaciones pendientes
import 'screens/menu_perfil/calificaciones_pendientes_screen.dart';
import 'screens/jobs/calificar_trabajo_screen.dart';
import 'screens/menu_perfil/reputacion/reputacion_detalle_screen.dart'; // ✅ NUEVO
import 'screens/sign_in/cuenta_suspendida_screen.dart';
import 'models/menu_perfil/baja_cuenta_model.dart';
import 'screens/menu_perfil/admin_solicitudes_screen.dart';

import 'screens/menu_perfil/recomendados/agregar_recomendado_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  try {
    final trabajoService = TrabajoService();
    await trabajoService.actualizarEstadosTrabajos();
    print('✅ Estados de trabajos actualizados al iniciar app');
  } catch (e) {
    print('⚠️ Error actualizando estados al iniciar: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChangApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversacion: args['conversacion'] as Conversacion,
                usuarioId: args['usuarioId'] as int,
              ),
            );

          case '/main-nav':
            final args = settings.arguments as Map<String, dynamic>?;
            final initialTab = args?['initialTab'] as int? ?? 0;
            return MaterialPageRoute(
              builder: (context) => MainNavScreen(initialTab: initialTab),
            );

          case '/postulaciones-trabajo':
            final trabajoId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) =>
                  PostulacionesTrabajoScreen(trabajoId: trabajoId),
            );

          case '/perfil-publico':
            final args = settings.arguments;
            final int userId;
            if (args is int) {
              userId = args;
            } else if (args is Map) {
              userId = args['usuarioId'] as int;
            } else {
              return MaterialPageRoute(
                  builder: (context) => const LoginScreen());
            }
            return MaterialPageRoute(
              builder: (context) => PerfilCompartidoScreen(userId: userId),
            );

          case '/gestionar-fotos-trabajo':
            final idTrabajo = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) =>
                  GestionarFotosTrabajoScreen(idTrabajo: idTrabajo),
            );

          case '/detalle-trabajo':
            final trabajoId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<TrabajoModel?>(
                future: TrabajoService().getTrabajoById(trabajoId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      appBar: AppBar(
                        backgroundColor: const Color(0xFFC5414B),
                        title: const Text('Error'),
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al cargar el trabajo'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return DetalleTrabajoScreen(trabajo: snapshot.data!);
                },
              ),
            );
          case '/editar-trabajo':
            final trabajo = settings.arguments as TrabajoModel;
            return MaterialPageRoute(
              builder: (context) => EditarTrabajoScreen(trabajo: trabajo),
            );
          case '/detalle-trabajo-propio':
            final trabajoId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<TrabajoModel?>(
                future: TrabajoService().getTrabajoById(trabajoId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return Scaffold(
                      appBar: AppBar(
                        backgroundColor: const Color(0xFFC5414B),
                        title: const Text('Error'),
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Error al cargar el trabajo'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return DetalleTrabajoPropio(trabajo: snapshot.data!);
                },
              ),
            );
          case '/cuenta-suspendida':
            final args = settings.arguments as BajaCuentaInfo?;
            return MaterialPageRoute(
              builder: (context) => CuentaSuspendidaScreen(bajaCuentaInfo: args),
            );
          default:
            return null;
        }
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/account-type-selection': (context) =>
            const AccountTypeSelectionScreen(),
        '/register-personal': (context) => const RegisterPersonalScreen(),
        '/register-empresarial': (context) => const RegisterEmpresarialScreen(),
        '/rubros-bubbles': (context) => const RubrosBubblesScreen(),
        '/user_menu': (context) => const UserMenuScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/trabajos': (context) => TrabajosScreen(),
        '/ubicaciones': (context) => UbicacionesScreen(),
        '/perfil': (context) => const PerfilPrivadoScreen(),
        '/agenda': (context) => const AgendaListaScreen(),
        '/mis-postulaciones': (context) => const MisPostulacionesScreen(),

        // ✅ RUTAS DE CONFIGURACIÓN (TODAS)
        '/configuracion': (context) => const ConfiguracionScreen(),
        '/editar-nombre': (context) => const EditarNombreScreen(),
        '/editar-email': (context) => const EditarEmailScreen(),
        '/editar-telefono': (context) => const EditarTelefonoScreen(),
        '/editar-foto': (context) => const EditarFotoScreen(),
        '/cambiar-contrasena': (context) => const CambiarContrasenaScreen(),

        '/crear-trabajo': (context) => const CrearTrabajoScreen(),
        '/unirse-empleadores': (context) => const UnirseEmpleadoresScreen(),
        '/unirse-empleados': (context) => const UnirseEmpleadosScreen(),
        '/crear-ubicacion': (context) => const CrearUbicacionScreen(),
        '/mis-rubros': (context) => const MisRubrosScreen(),
        '/calendario': (context) => const CalendarScreen(),
        
        // Ruta de recomendados
        '/agregar-recomendado': (context) => const AgregarRecomendadoScreen(),

        // ✅ RUTAS DE CHAT
        '/conversaciones': (context) => const ConversacionesScreen(),

        // ✅ NUEVA RUTA: Calificaciones Pendientes
        '/calificaciones-pendientes': (context) =>
            const CalificacionesPendientesScreen(),
        '/reputacion-detalle': (context) {
          final rol = ModalRoute.of(context)!.settings.arguments as String;
          return ReputacionDetalleScreen(rol: rol);
        },
        // Ruta Administrador
        '/admin-solicitudes': (context) => const AdminSolicitudesScreen(),
        // En la sección de rutas de main.dart, agrega:

        '/mis-empleados': (context) => const MisEmpleadosScreen(),
        '/agregar-empleado': (context) => const AgregarEmpleadoScreen(),
        '/editar-empleado': (context) {
          final empleado = ModalRoute.of(context)!.settings.arguments
              as EmpleadoEmpresaModel;
          return EditarEmpleadoScreen(empleado: empleado);
        },
      },
    );
  }
}
