//lib/main.dart
// ✅ FINAL - Con todas las rutas de configuración

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/supabase_client.dart';
import 'services/trabajo_service.dart';
import 'models/trabajo_model.dart';
import 'screens/sign_in/login_screen.dart';
import 'screens/sign_in/account_type_selection_screen.dart';
import 'screens/sign_in/register_personal_screen.dart';
import 'screens/sign_in/register_empresarial_screen.dart';
import 'screens/sign_in/rubros_bubbles_screen.dart';
import 'screens/sign_in/role_selection_screen.dart';
import 'screens/sign_in/forgot_password_screen.dart';
import 'screens/user/menu_perfil/user_menu_screen.dart';
import 'screens/user/menu_perfil/trabajos_screen.dart';
import 'screens/user/menu_perfil/perfil_privado_screen.dart';
import 'screens/user/perfil_publico_screen.dart';
import 'screens/user/menu_perfil/ubicaciones_screen.dart';
import 'screens/user/crear_ubicaciones_screen.dart';
import 'screens/user/menu_perfil/mis_rubros_screen.dart';
import 'screens/user/menu_perfil/calendar_screen.dart';
import 'screens/user/menu_perfil/agenda_lista_screen.dart';
import 'screens/user/menu_perfil/configuracion/configuracion_screen.dart';
import 'screens/user/menu_perfil/configuracion/editar_nombre_screen.dart';
import 'screens/user/menu_perfil/configuracion/cambiar_contrasena_screen.dart';
import 'screens/user/menu_perfil/configuracion/editar_email_screen.dart';
import 'screens/user/menu_perfil/configuracion/editar_telefono_screen.dart';
import 'screens/user/menu_perfil/configuracion/editar_foto_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/jobs/postulaciones_trabajo_screen.dart';
import 'screens/jobs/gestionar_fotos_trabajo_screen.dart';
import 'screens/jobs/create_trabajo_screen.dart';
import 'screens/jobs/detalle_trabajo_screen.dart';
import 'screens/jobs/detalle_trabajo_propio_screen.dart';
import 'screens/user/unirse_empleadores_screen.dart';
import 'screens/user/unirse_empleados_screen.dart';

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
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/account-type-selection': (context) => const AccountTypeSelectionScreen(),
        '/register-personal': (context) => const RegisterPersonalScreen(),
        '/register-empresarial': (context) => const RegisterEmpresarialScreen(),
        '/rubros-bubbles': (context) => const RubrosBubblesScreen(),
        '/user_menu': (context) => const UserMenuScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/trabajos': (context) => TrabajosScreen(),
        '/ubicaciones': (context) => UbicacionesScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/agenda': (context) => const AgendaListaScreen(),
        
        // ✅ RUTAS DE CONFIGURACIÓN (TODAS)
        '/configuracion': (context) => const ConfiguracionScreen(),
        '/editar-nombre': (context) => const EditarNombreScreen(),
        '/editar-email': (context) => const EditarEmailScreen(),
        '/editar-telefono': (context) => const EditarTelefonoScreen(),
        '/editar-foto': (context) => const EditarFotoScreen(),
        '/cambiar-contrasena': (context) => const CambiarContrasenaScreen(),
        
        '/main-nav': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final initialTab = args?['initialTab'] as int? ?? 0;
          return MainNavScreen(initialTab: initialTab);
        },
        '/postulaciones-trabajo': (context) {
          final trabajoId = ModalRoute.of(context)?.settings.arguments as int;
          return PostulacionesTrabajoScreen(trabajoId: trabajoId);
        },
        '/crear-trabajo': (context) => const CrearTrabajoScreen(),
        '/unirse-empleadores': (context) => const UnirseEmpleadoresScreen(),
        '/unirse-empleados': (context) => const UnirseEmpleadosScreen(),
        '/perfil-compartido': (context) {
          final userId = ModalRoute.of(context)?.settings.arguments as int;
          return PerfilCompartidoScreen(userId: userId);
        },
        '/crear-ubicacion': (context) => const CrearUbicacionScreen(),
        '/mis-rubros': (context) => const MisRubrosScreen(),
        '/calendario': (context) => const CalendarScreen(),
        '/gestionar-fotos-trabajo': (context) {
          final idTrabajo = ModalRoute.of(context)?.settings.arguments as int;
          return GestionarFotosTrabajoScreen(idTrabajo: idTrabajo);
          },
        '/detalle-trabajo': (context) {
          final trabajoId = ModalRoute.of(context)?.settings.arguments as int;
          return FutureBuilder<TrabajoModel?>(
            future: TrabajoService().getTrabajoById(trabajoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
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
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error al cargar el trabajo'),
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
          );
        },
        '/detalle-trabajo-propio': (context) {
          final trabajoId = ModalRoute.of(context)?.settings.arguments as int;
          return FutureBuilder<TrabajoModel?>(
            future: TrabajoService().getTrabajoById(trabajoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
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
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error al cargar el trabajo'),
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
          );
        },
      },
    );
  }
}