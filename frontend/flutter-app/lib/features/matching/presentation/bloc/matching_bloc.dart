import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class MatchingEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadDiscoveryStack extends MatchingEvent {}

class SwipedRight extends MatchingEvent {
  final Map<String, dynamic> profile;
  SwipedRight(this.profile);
}

class SwipedLeft extends MatchingEvent {
  final Map<String, dynamic> profile;
  SwipedLeft(this.profile);
}

class SuperLiked extends MatchingEvent {
  final Map<String, dynamic> profile;
  SuperLiked(this.profile);
}

class UpdateFilters extends MatchingEvent {
  final int radiusKm;
  final int minAge;
  final int maxAge;
  final String genderPreference;
  UpdateFilters({
    required this.radiusKm,
    required this.minAge,
    required this.maxAge,
    required this.genderPreference,
  });
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class MatchingState extends Equatable {
  @override List<Object?> get props => [];
}

class MatchingInitial extends MatchingState {}
class MatchingLoading extends MatchingState {}

class DiscoveryStackLoaded extends MatchingState {
  final List<Map<String, dynamic>> profiles;
  DiscoveryStackLoaded(this.profiles);
  @override List<Object?> get props => [profiles];
}

class DiscoveryEmpty extends MatchingState {}

class MatchCreated extends MatchingState {
  final Map<String, dynamic> matchedUser;
  MatchCreated(this.matchedUser);
  @override List<Object?> get props => [matchedUser];
}

class MatchingError extends MatchingState {
  final String message;
  MatchingError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class MatchingBloc extends Bloc<MatchingEvent, MatchingState> {
  MatchingBloc() : super(MatchingInitial()) {
    on<LoadDiscoveryStack>(_onLoad);
    on<SwipedRight>(_onSwipedRight);
    on<SwipedLeft>(_onSwipedLeft);
    on<SuperLiked>(_onSuperLiked);
    on<UpdateFilters>(_onUpdateFilters);
  }

  Future<void> _onLoad(LoadDiscoveryStack event, Emitter<MatchingState> emit) async {
    emit(MatchingLoading());
    try {
      // TODO: Call user-service API /api/v1/users/discover
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
      // Mock data for development
      emit(DiscoveryStackLoaded(_mockProfiles()));
    } catch (e) {
      emit(MatchingError(e.toString()));
    }
  }

  Future<void> _onSwipedRight(SwipedRight event, Emitter<MatchingState> emit) async {
    try {
      // TODO: Call /api/v1/users/swipe with LIKE
      // If match returned, emit MatchCreated
      // For demo, simulate occasional match
      if (DateTime.now().millisecond % 3 == 0) {
        emit(MatchCreated({...event.profile, 'chatRoomId': 'demo-room'}));
      }
    } catch (e) {
      // Non-critical — swipe recorded locally
    }
  }

  Future<void> _onSwipedLeft(SwipedLeft event, Emitter<MatchingState> emit) async {
    // TODO: Call /api/v1/users/swipe with DISLIKE
  }

  Future<void> _onSuperLiked(SuperLiked event, Emitter<MatchingState> emit) async {
    // TODO: Call /api/v1/users/swipe with SUPER_LIKE
    // Deduct coins
  }

  Future<void> _onUpdateFilters(UpdateFilters event, Emitter<MatchingState> emit) async {
    // TODO: Update filter preferences and reload stack
    add(LoadDiscoveryStack());
  }

  List<Map<String, dynamic>> _mockProfiles() {
    return [
      {
        'userId': 'user-1',
        'displayName': 'Alice',
        'age': 25,
        'bio': 'Chess enthusiast & Ludo champion 🎮',
        'city': 'New York',
        'rating': 1450,
        'totalGamesPlayed': 42,
        'isOnline': true,
        'interests': ['Chess', 'Movies', 'Hiking'],
        'gamePreferences': ['CHESS', 'LUDO'],
        'profilePhotoUrl': null,
        'photos': [],
      },
      {
        'userId': 'user-2',
        'displayName': 'Diana',
        'age': 26,
        'bio': 'Ludo expert. Challenge me! 👑',
        'city': 'Paris',
        'rating': 1390,
        'totalGamesPlayed': 55,
        'isOnline': false,
        'interests': ['Ludo', 'Cooking', 'Yoga'],
        'gamePreferences': ['LUDO', 'CARROM'],
        'profilePhotoUrl': null,
        'photos': [],
      },
    ];
  }
}
