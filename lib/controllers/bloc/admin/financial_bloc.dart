// lib/controllers/bloc/admin/financial_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/admin/financial_report.dart';
import '../../../core/services/admin/admin_service.dart';

// Events
abstract class FinancialEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFinancialReport extends FinancialEvent {
  final DateTime startDate;
  final DateTime endDate;
  
  LoadFinancialReport({
    required this.startDate,
    required this.endDate,
  });
  
  @override
  List<Object?> get props => [startDate, endDate];
}

class ExportFinancialReport extends FinancialEvent {
  final String format; // 'pdf', 'csv', etc.
  
  ExportFinancialReport({required this.format});
  
  @override
  List<Object?> get props => [format];
}

// States
abstract class FinancialState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FinancialInitial extends FinancialState {}
class FinancialLoading extends FinancialState {}

class FinancialLoaded extends FinancialState {
  final FinancialReport report;
  
  FinancialLoaded(this.report);
  
  @override
  List<Object?> get props => [report];
}

class FinancialError extends FinancialState {
  final String message;
  
  FinancialError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class FinancialExporting extends FinancialState {}
class FinancialExported extends FinancialState {
  final String path;
  
  FinancialExported(this.path);
  
  @override
  List<Object?> get props => [path];
}

// BLoC
class FinancialBloc extends Bloc<FinancialEvent, FinancialState> {
  final AdminService _adminService = AdminService();
  
  FinancialBloc() : super(FinancialInitial()) {
    on<LoadFinancialReport>(_onLoadFinancialReport);
    on<ExportFinancialReport>(_onExportFinancialReport);
  }
  
  Future<void> _onLoadFinancialReport(
    LoadFinancialReport event,
    Emitter<FinancialState> emit,
  ) async {
    emit(FinancialLoading());
    try {
      final report = await _adminService.getFinancialReport(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(FinancialLoaded(report));
    } catch (e) {
      emit(FinancialError(e.toString()));
    }
  }
  
  Future<void> _onExportFinancialReport(
    ExportFinancialReport event,
    Emitter<FinancialState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinancialLoaded) {
      emit(FinancialExporting());
      try {
        // Implementar exportação do relatório
        final path = '/path/to/exported/file'; // Simulação
        emit(FinancialExported(path));
        emit(currentState); // Retornar ao estado anterior
      } catch (e) {
        emit(FinancialError(e.toString()));
      }
    }
  }
}