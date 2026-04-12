import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class WalletEvent extends Equatable {
  @override List<Object?> get props => [];
}
class LoadWallet extends WalletEvent {}

abstract class WalletState extends Equatable {
  @override List<Object?> get props => [];
}
class WalletInitial extends WalletState {}
class WalletLoaded extends WalletState {
  final int coinBalance;
  WalletLoaded(this.coinBalance);
  @override List<Object?> get props => [coinBalance];
}

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc() : super(WalletInitial()) {
    on<LoadWallet>((event, emit) => emit(WalletLoaded(0)));
  }
}