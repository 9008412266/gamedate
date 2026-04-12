import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class GameEvent extends Equatable {
  @override List<Object?> get props => [];
}

class JoinGameRoom extends GameEvent {
  final String roomId;
  JoinGameRoom(this.roomId);
}

class CreateGameRoom extends GameEvent {
  final String gameType;
  final String? aiDifficulty;
  final int coinsBet;
  CreateGameRoom({required this.gameType, this.aiDifficulty, this.coinsBet = 0});
}

class GameStateReceived extends GameEvent {
  final String rawJson;
  GameStateReceived(this.rawJson);
}

class SendGameAction extends GameEvent {
  final String actionType;
  final Map<String, dynamic> payload;
  SendGameAction(this.actionType, this.payload);
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class GameState extends Equatable {
  @override List<Object?> get props => [];
}

class GameInitial extends GameState {}
class GameLoading extends GameState {}

class GameRoomActive extends GameState {
  final Map<String, dynamic> gameState;
  GameRoomActive(this.gameState);
  @override List<Object?> get props => [gameState];
}

class GameCompleted extends GameState {
  final String? winnerId;
  final int coinsEarned;
  GameCompleted({this.winnerId, this.coinsEarned = 0});
  @override List<Object?> get props => [winnerId, coinsEarned];
}

class GameError extends GameState {
  final String message;
  GameError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc() : super(GameInitial()) {
    on<JoinGameRoom>(_onJoinRoom);
    on<CreateGameRoom>(_onCreateRoom);
    on<GameStateReceived>(_onStateReceived);
    on<SendGameAction>(_onSendAction);
  }

  Future<void> _onJoinRoom(JoinGameRoom event, Emitter<GameState> emit) async {
    emit(GameLoading());
    // WebSocket connection handled in the page widget
    // BLoC just holds state after receiving from WebSocket
  }

  Future<void> _onCreateRoom(CreateGameRoom event, Emitter<GameState> emit) async {
    emit(GameLoading());
    // TODO: Call /api/v1/games/rooms via HTTP
  }

  void _onStateReceived(GameStateReceived event, Emitter<GameState> emit) {
    try {
      final state = jsonDecode(event.rawJson) as Map<String, dynamic>;
      if (state['status'] == 'COMPLETED') {
        emit(GameCompleted(
          winnerId: state['winnerId'],
          coinsEarned: (state['coinsEarned'] ?? 0) as int,
        ));
      } else {
        emit(GameRoomActive(state));
      }
    } catch (e) {
      emit(GameError('Failed to parse game state'));
    }
  }

  void _onSendAction(SendGameAction event, Emitter<GameState> emit) {
    // Action sending handled by WebSocket in the page widget
    // BLoC state will update when server broadcasts new state
  }
}
