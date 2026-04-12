import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Swipeable profile card for the discover screen.
class ProfileCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final bool isTop;

  const ProfileCard({super.key, required this.profile, this.isTop = false});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final photos = (widget.profile['photos'] as List?)?.cast<String>() ?? [];
    final allPhotos = [
      if (widget.profile['profilePhotoUrl'] != null) widget.profile['profilePhotoUrl'] as String,
      ...photos,
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Photo
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) {
                  final width = MediaQuery.of(context).size.width;
                  setState(() {
                    if (details.globalPosition.dx > width / 2) {
                      _currentPhotoIndex = (_currentPhotoIndex + 1).clamp(0, allPhotos.length - 1);
                    } else {
                      _currentPhotoIndex = (_currentPhotoIndex - 1).clamp(0, allPhotos.length - 1);
                    }
                  });
                },
                child: allPhotos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: allPhotos[_currentPhotoIndex],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppTheme.darkCard),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.darkCard,
                          child: const Icon(Icons.person, size: 80, color: Colors.white30),
                        ),
                      )
                    : Container(
                        color: AppTheme.darkCard,
                        child: const Icon(Icons.person, size: 80, color: Colors.white30),
                      ),
              ),
            ),

            // Photo progress indicators
            if (allPhotos.length > 1)
              Positioned(
                top: 12, left: 12, right: 12,
                child: Row(
                  children: List.generate(allPhotos.length, (i) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _currentPhotoIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // Profile info
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Age
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.profile['displayName']}, ${widget.profile['age']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.profile['isOnline'] == true)
                          Container(
                            width: 12, height: 12,
                            decoration: const BoxDecoration(
                              color: AppTheme.online,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    // City
                    if (widget.profile['city'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(widget.profile['city'],
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),

                    // Bio
                    if (widget.profile['bio'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.profile['bio'],
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Interests chips
                    if ((widget.profile['interests'] as List?)?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 6,
                          children: ((widget.profile['interests'] as List)
                                  .take(3)
                                  .cast<String>())
                              .map((interest) => _InterestChip(interest))
                              .toList(),
                        ),
                      ),

                    // Stats row
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          _StatBadge(
                              icon: Icons.gamepad,
                              label: '${widget.profile['totalGamesPlayed']} games'),
                          const SizedBox(width: 8),
                          _StatBadge(
                              icon: Icons.star,
                              label: '${widget.profile['rating']} ELO'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  const _InterestChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.accentGold, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
