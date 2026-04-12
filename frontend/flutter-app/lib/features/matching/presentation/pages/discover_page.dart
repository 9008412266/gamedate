import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/matching_bloc.dart';
import '../widgets/profile_card.dart';
import '../widgets/match_overlay.dart';
import '../widgets/swipe_action_buttons.dart';

/// Tinder-style discovery/swiping screen.
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with SingleTickerProviderStateMixin {
  final CardSwiperController _swiperController = CardSwiperController();
  bool _showMatchOverlay = false;
  Map<String, dynamic>? _matchedUser;

  @override
  void initState() {
    super.initState();
    context.read<MatchingBloc>().add(LoadDiscoveryStack());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
          child: const Text('Discover', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () => _showFilters(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<MatchingBloc, MatchingState>(
        listener: (context, state) {
          if (state is MatchCreated) {
            setState(() {
              _showMatchOverlay = true;
              _matchedUser = state.matchedUser;
            });
          }
        },
        builder: (context, state) {
          if (state is MatchingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DiscoveryStackLoaded && state.profiles.isNotEmpty) {
            return Stack(
              children: [
                _buildCardSwiper(state),
                if (_showMatchOverlay) MatchOverlay(
                  matchedUser: _matchedUser!,
                  onClose: () => setState(() {
                    _showMatchOverlay = false;
                    _matchedUser = null;
                  }),
                ),
              ],
            );
          }

          if (state is DiscoveryEmpty) {
            return _buildEmptyState();
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildCardSwiper(DiscoveryStackLoaded state) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: state.profiles.length,
              numberOfCardsDisplayed: 3,
              backCardOffset: const Offset(25, 15),
              padding: const EdgeInsets.all(0),
              onSwipe: (prev, current, direction) {
                final profile = state.profiles[prev];
                switch (direction) {
                  case CardSwiperDirection.right:
                    context.read<MatchingBloc>().add(SwipedRight(profile));
                    break;
                  case CardSwiperDirection.left:
                    context.read<MatchingBloc>().add(SwipedLeft(profile));
                    break;
                  case CardSwiperDirection.top:
                    context.read<MatchingBloc>().add(SuperLiked(profile));
                    break;
                  default:
                    break;
                }
                return true;
              },
              onEnd: () => context.read<MatchingBloc>().add(LoadDiscoveryStack()),
              cardBuilder: (context, index, horizontalOffset, verticalOffset) {
                final profile = state.profiles[index];
                return ProfileCard(
                  profile: profile,
                  isTop: index == 0,
                );
              },
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: SwipeActionButtons(
            onDislike: () => _swiperController.swipeLeft(),
            onSuperLike: () => _swiperController.swipeTop(),
            onLike: () => _swiperController.swipeRight(),
            onRewind: () => _swiperController.undo(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryPink.withOpacity(0.12),
              border: Border.all(color: AppTheme.primaryPink.withOpacity(0.3)),
            ),
            child: const Center(child: Text('🎮', style: TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 24),
          const Text('No more profiles nearby',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Try expanding your search radius',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => context.read<MatchingBloc>().add(LoadDiscoveryStack()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: AppTheme.primaryPink.withOpacity(0.35),
                  blurRadius: 14, offset: const Offset(0, 4),
                )],
              ),
              child: const Text('Refresh', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  double _radius = 50;
  RangeValues _ageRange = const RangeValues(18, 40);
  String _genderPref = 'ALL';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Filters', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Distance
          Text('Distance: ${_radius.toInt()} km'),
          Slider(
            value: _radius,
            min: 5, max: 200,
            activeColor: AppTheme.primaryPink,
            onChanged: (v) => setState(() => _radius = v),
          ),

          const SizedBox(height: 16),

          // Age range
          Text('Age: ${_ageRange.start.toInt()} - ${_ageRange.end.toInt()}'),
          RangeSlider(
            values: _ageRange,
            min: 18, max: 60,
            activeColor: AppTheme.primaryPink,
            onChanged: (v) => setState(() => _ageRange = v),
          ),

          const SizedBox(height: 24),

          // Gender preference
          const Text('Show me'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Men', 'Women', 'Everyone'].map((g) {
              final value = g == 'Everyone' ? 'ALL' :
                            g == 'Men' ? 'MALE' : 'FEMALE';
              return FilterChip(
                label: Text(g),
                selected: _genderPref == value,
                selectedColor: AppTheme.primaryPink,
                onSelected: (_) => setState(() => _genderPref = value),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              context.read<MatchingBloc>().add(UpdateFilters(
                radiusKm: _radius.toInt(),
                minAge: _ageRange.start.toInt(),
                maxAge: _ageRange.end.toInt(),
                genderPreference: _genderPref,
              ));
              Navigator.pop(context);
            },
            child: const Text('Apply Filters'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
