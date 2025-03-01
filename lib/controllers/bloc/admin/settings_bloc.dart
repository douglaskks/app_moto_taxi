// lib/controllers/bloc/admin/settings_bloc.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/admin/admin_service.dart';

// Events
abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class SaveSettings extends SettingsEvent {
  final Map<String, dynamic> settings;
  
  SaveSettings(this.settings);
  
  @override
  List<Object?> get props => [settings];
}

// States
abstract class SettingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}
class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final Map<String, dynamic> settings;
  
  SettingsLoaded(this.settings);
  
  @override
  List<Object?> get props => [settings];
}

class SettingsSaved extends SettingsState {}

class SettingsError extends SettingsState {
  final String message;
  
  SettingsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final AdminService _adminService = AdminService();
  
  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveSettings>(_onSaveSettings);
  }
  
  Future<void> _onLoadSettings(
  LoadSettings event,
  Emitter<SettingsState> emit,
) async {
  emit(SettingsLoading());
  try {
    // Obter usuário atual
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Log de depuração
    print('User ID: ${user.uid}');

    // Buscar documento do usuário
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    print('User Role: ${userDoc.data()?['role']}');

    final settings = await _adminService.getAppSettings();
    emit(SettingsLoaded(settings));
  } catch (e) {
    print('Erro ao carregar configurações: $e');
    emit(SettingsError(e.toString()));
  }
}
  
  Future<void> _onSaveSettings(
    SaveSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      emit(SettingsLoading());
      try {
        await _adminService.updateAppSettings(event.settings);
        emit(SettingsLoaded(event.settings));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }
}