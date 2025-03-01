// Arquivo: lib/core/utils/debug_bloc_observer.dart

import 'package:flutter_bloc/flutter_bloc.dart';

class DebugBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    print('BlocObserver: onCreate -- ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    print('BlocObserver: ${bloc.runtimeType} - Evento: $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('BlocObserver: ${bloc.runtimeType} - Estado atual: ${change.currentState} -> Próximo estado: ${change.nextState}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print('BlocObserver: ${bloc.runtimeType} - Transição: ${transition.event} -> ${transition.currentState} -> ${transition.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('BlocObserver: ERRO no ${bloc.runtimeType} - $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    print('BlocObserver: onClose -- ${bloc.runtimeType}');
  }
}