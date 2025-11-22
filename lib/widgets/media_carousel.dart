import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MediaCarousel extends StatefulWidget {
  final List<String> photos;
  final List<String> videos;
  final double height;
  final bool showIndicator;

  const MediaCarousel({
    super.key,
    required this.photos,
    required this.videos,
    this.height = 300,
    this.showIndicator = true,
  });

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _videoControllers = {};
  int _currentPage = 0;

  List<MediaItem> get _allMedia {
    final List<MediaItem> items = [];

    // Ajouter les photos
    for (var photo in widget.photos) {
      items.add(MediaItem(url: photo, type: MediaType.image));
    }

    // Ajouter les vidéos
    for (var video in widget.videos) {
      items.add(MediaItem(url: video, type: MediaType.video));
    }

    return items;
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  VideoPlayerController _getVideoController(int index, String url) {
    if (!_videoControllers.containsKey(index)) {
      _videoControllers[index] =
          VideoPlayerController.networkUrl(Uri.parse(url))
            ..initialize().then((_) {
              if (mounted && _currentPage == index) {
                setState(() {});
              }
            });
    }
    return _videoControllers[index]!;
  }

  @override
  Widget build(BuildContext context) {
    final media = _allMedia;

    if (media.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.agriculture, size: 60, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: media.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });

              // Pause toutes les vidéos sauf celle affichée
              for (var entry in _videoControllers.entries) {
                if (entry.key != index && entry.value.value.isPlaying) {
                  entry.value.pause();
                }
              }
            },
            itemBuilder: (context, index) {
              final item = media[index];

              if (item.type == MediaType.image) {
                return _buildImageWidget(item.url);
              } else {
                return _buildVideoWidget(index, item.url);
              }
            },
          ),
        ),

        // Indicateur de page
        if (widget.showIndicator && media.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: media.length,
                  effect: const WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: Colors.white,
                    dotColor: Colors.white54,
                  ),
                ),
              ),
            ),
          ),

        // Compteur photos/vidéos
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.photos.isNotEmpty) ...[
                  const Icon(Icons.image, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (widget.photos.isNotEmpty && widget.videos.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('|', style: TextStyle(color: Colors.white54)),
                  ),
                if (widget.videos.isNotEmpty) ...[
                  const Icon(Icons.videocam, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.videos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.error, size: 50, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildVideoWidget(int index, String url) {
    final controller = _getVideoController(index, url);

    if (!controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),

        // Contrôles vidéo
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ),

        // Barre de progression
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Theme.of(context).primaryColor,
              bufferedColor: Colors.white.withValues(alpha: 0.5),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      ],
    );
  }
}

enum MediaType { image, video }

class MediaItem {
  final String url;
  final MediaType type;

  MediaItem({required this.url, required this.type});
}
