import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/driver_management_service.dart';
import '../../../models/admin/user_management.dart';

// Events
abstract class DriverManagementEvent extends Equatable {
  const DriverManagementEvent();

  @override
  List<Object> get props => [];
}

class LoadDriversList extends DriverManagementEvent {}

class FilterDrivers extends DriverManagementEvent {
  final bool? activeOnly;
  final bool? documentsVerified;

  const FilterDrivers({this.activeOnly, this.documentsVerified});

  @override
  List<Object> get props => [
    activeOnly ?? false, 
    documentsVerified ?? false
  ];
}

// States
abstract class DriverManagementState extends Equatable {
  const DriverManagementState();
  
  @override
  List<Object> get props => [];
}

class DriverManagementInitial extends DriverManagementState {}

class DriverManagementLoading extends DriverManagementState {}

class DriverManagementLoaded extends DriverManagementState {
  final List<UserDetails> drivers;

  const DriverManagementLoaded(this.drivers);

  @override
  List<Object> get props => [drivers];
}

class DriverManagementError extends DriverManagementState {
  final String message;

  const DriverManagementError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class DriverManagementBloc extends Bloc<DriverManagementEvent, DriverManagementState> {
  final DriverManagementService _driverService = DriverManagementService();

  DriverManagementBloc() : super(DriverManagementInitial()) {
    on<LoadDriversList>(_onLoadDriversList);
    on<FilterDrivers>(_onFilterDrivers);
  }

  void _onLoadDriversList(LoadDriversList event, Emitter<DriverManagementState> emit) async {
    emit(DriverManagementLoading());

    try {
      final drivers = await _driverService.getAllDrivers();
      emit(DriverManagementLoaded(drivers));
    } catch (e) {
      emit(DriverManagementError('Erro ao carregar motoristas: ${e.toString()}'));
    }
  }

  void _onFilterDrivers(FilterDrivers event, Emitter<DriverManagementState> emit) async {
    emit(DriverManagementLoading());

    try {
      final drivers = await _driverService.getAllDrivers(
        activeOnly: event.activeOnly,
        documentsVerified: event.documentsVerified,
      );
      emit(DriverManagementLoaded(drivers));
    } catch (e) {
      emit(DriverManagementError('Erro ao filtrar motoristas: ${e.toString()}'));
    }
  }
}