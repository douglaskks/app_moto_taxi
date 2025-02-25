// lib/main.dart
import 'package:app_moto_taxe/controllers/bloc/auth/auth_bloc.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_event.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_state.dart';
import 'package:app_moto_taxe/core/services/auth_service.dart';
import 'package:app_moto_taxe/firebase_options.dart';
import 'package:app_moto_taxe/routes.dart';
import 'package:app_moto_taxe/views/admin/admin_home.dart';
import 'package:app_moto_taxe/views/auth/login_screen.dart';
import 'package:app_moto_taxe/views/driver/driver_home.dart';
import 'package:app_moto_taxe/views/passenger/passenger_home.dart';
import 'package:app_moto_taxe/views/splash_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_moto_taxe/core/services/notification_service.dart';
import 'package:app_moto_taxe/core/managers/notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialize o Firebase primeiro
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Depois inicialize o App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final NotificationManager _notificationManager = NotificationManager();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Inicializar após o build estar completo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.initialize(context);
      _notificationManager.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(_authService)..add(AppStarted()),
        ),
        // Outros BLoCs podem ser adicionados aqui
      ],
      child: MaterialApp(
        title: 'MotoApp',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // Usar o novo sistema de rotas
        onGenerateRoute: AppRouter.generateRoute,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial || state is AuthLoading) {
              return const SplashScreen();
            } else if (state is Authenticated) {
              // Direcionar para a tela correta baseado no tipo de usuário
              switch (state.userType) {
                case 'passenger':
                  return const PassengerHome();
                case 'driver':
                  return const DriverHome();
                case 'admin':
                  return const AdminHome();
                default:
                  return const LoginScreen();
              }
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}