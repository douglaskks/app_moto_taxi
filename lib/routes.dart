// lib/routes.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_bloc.dart';
import 'package:app_moto_taxe/controllers/bloc/auth/auth_state.dart';
import 'package:app_moto_taxe/views/admin/admin_dashboard.dart';
import 'package:app_moto_taxe/views/admin/user_management_screen.dart';
import 'package:app_moto_taxe/views/admin/financial_report_screen.dart';
import 'package:app_moto_taxe/views/admin/admin_home.dart';
import 'package:app_moto_taxe/views/auth/login_screen.dart';
import 'package:app_moto_taxe/views/passenger/passenger_home.dart';
import 'package:app_moto_taxe/views/driver/driver_home.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página Não Encontrada')),
      body: const Center(
        child: Text(
          '404 - Página não encontrada',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acesso Negado')),
      body: const Center(
        child: Text(
          'Você não tem permissão para acessar esta página.',
          style: TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Rotas administrativas
      case '/admin':
        return _buildRoute(
          context: settings.arguments as BuildContext,
          route: const AdminDashboardScreen(),
          isAdmin: true,
        );

      case '/admin/users':
        return _buildRoute(
          context: settings.arguments as BuildContext,
          route: const UserManagementScreen(),
          isAdmin: true,
        );

      case '/admin/financial':
        return _buildRoute(
          context: settings.arguments as BuildContext,
          route: const FinancialReportScreen(),
          isAdmin: true,
        );

      case '/admin/home':
        return _buildRoute(
          context: settings.arguments as BuildContext,
          route: const AdminHome(),
          isAdmin: true,
        );

      // Rotas de passageiro
      case '/passenger/home':
        return MaterialPageRoute(builder: (_) => const PassengerHome());

      // Rotas de motorista
      case '/driver/home':
        return MaterialPageRoute(builder: (_) => const DriverHome());

      // Rota de login
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // Rota não autorizada
      case '/unauthorized':
        return MaterialPageRoute(builder: (_) => const UnauthorizedScreen());

      // Rota padrão ou não encontrada
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }

  static MaterialPageRoute _buildRoute({
    required BuildContext context,
    required Widget route,
    bool isAdmin = false,
  }) {
    final authBloc = context.read<AuthBloc>();
    final isAuthenticated = authBloc.state is Authenticated;

    if (!isAuthenticated) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    if (isAdmin && !_checkIsAdmin(authBloc)) {
      return MaterialPageRoute(builder: (_) => const UnauthorizedScreen());
    }

    return MaterialPageRoute(builder: (_) => route);
  }

  // Método auxiliar para verificar se o usuário é admin
  static bool _checkIsAdmin(AuthBloc authBloc) {
    return authBloc.state is Authenticated &&
        (authBloc.state as Authenticated).userType == 'admin';
  }

  // Método para navegação programática
  static void navigateTo(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName, arguments: context);
  }

  // Método para navegação e substituição de rotas
  static void navigateAndReplace(BuildContext context, String routeName) {
    Navigator.of(context).pushReplacementNamed(routeName, arguments: context);
  }

  // Método para navegação com limpeza da pilha de rotas
  static void navigateAndRemoveUntil(BuildContext context, String routeName) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: context,
    );
  }
}

// Mixin para proteção de rotas administrativas
mixin AdminRouteMixin on StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Verificar se é admin
    final authBloc = context.read<AuthBloc>();
    final isAdmin = authBloc.state is Authenticated &&
        (authBloc.state as Authenticated).userType == 'admin';

    if (!isAdmin) {
      // Redirecionar para tela de não autorizado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/unauthorized');
      });
      return const SizedBox.shrink();
    }

    // Chama o método build da classe que está usando o mixin
    return buildAdminScreen(context);
  }

  // Método abstrato a ser implementado pelas classes que usam o mixin
  Widget buildAdminScreen(BuildContext context);
}