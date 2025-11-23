import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucida_player/models/music_item.dart';
import 'package:lucida_player/utils/utils.dart';
import 'package:lucida_player/providers/player_provider.dart';

final _api = APIClient();
final _debouncer = Debouncer(delay: Duration(milliseconds: 500));

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  SearchResults? _searchResults;
  String _selectedFilter = 'All';
  bool _isLoading = false;

  // Function to fetch search results
  void _fetchSearchResults(String query) {
    if (query.trim().isEmpty) {
      _debouncer.dispose();
      setState(() {
        _searchResults = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debouncer.run(() async {
      try {
        final result = await _api.search(query);
        if (mounted) {
          setState(() {
            _searchResults = result;
            _isLoading = false;
          });
        }
      } catch (e) {
        log('Error fetching search results: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _onFilterSelected(String filter) {
    setState(() {
      if (_selectedFilter == filter) {
        _selectedFilter = 'All';
      } else {
        _selectedFilter = filter;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 15.0),
          SearchBar(onSearch: _fetchSearchResults),
          const SizedBox(height: 15.0),
          SearchFilterBar(
            selectedFilter: _selectedFilter,
            onFilterSelected: _onFilterSelected,
          ),
          const SizedBox(height: 10.0),
          Expanded(child: _buildResults()),
        ],
      ),
      appBar: AppBar(
        toolbarHeight: 60.0,
        title: Padding(
          padding: const EdgeInsets.only(top: 45.0),
          child: const Text(
            'Search',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.black,
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_searchResults == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'Start searching...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      );
    }

    if (_searchResults!.isEmpty ?? false) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text(
              'Nothing found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      );
    }

    if (_selectedFilter == 'Tracks') {
      return TracksResult(tracks: _searchResults!.tracks);
    } else if (_selectedFilter == 'Albums') {
      return AlbumsResult(albums: _searchResults!.albums);
    } else if (_selectedFilter == 'Artists') {
      return ArtistsResult(artists: _searchResults!.artists);
    } else {
      // All
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchResults!.artists.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                child: Text(
                  'Artists',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 150,
                child: HorizontalArtistsResult(
                  artists: _searchResults!.artists,
                ),
              ),
            ],
            if (_searchResults!.albums.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                child: Text(
                  'Albums',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 180,
                child: HorizontalAlbumsResult(albums: _searchResults!.albums),
              ),
            ],
            if (_searchResults!.tracks.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                child: Text(
                  'Tracks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TracksResult(tracks: _searchResults!.tracks, shrinkWrap: true),
            ],
            SizedBox(
              height: ref.watch(playerProvider).currentTrack != null ? 100 : 20,
            ),
          ],
        ),
      );
    }
  }
}

class SearchBar extends StatelessWidget {
  final Function(String) onSearch;
  const SearchBar({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: TextField(
        onTapOutside: (event) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onChanged: (value) {
          onSearch(value);
        },
        style: TextStyle(fontSize: 16.0, color: Colors.black),
        maxLines: 1,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
          hintText: 'What do you want to listen to?',
          hintStyle: const TextStyle(letterSpacing: -0.5, fontSize: 16.0),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.black,
              weight: 15.0,
              fontWeight: FontWeight.normal,
              size: 23.0,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
    );
  }
}

class SearchFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const SearchFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          _chip('All'),
          _chip('Tracks'),
          _chip('Albums'),
          _chip('Artists'),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onFilterSelected(label),
        selectedColor: Colors.white,
        backgroundColor: Colors.black,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: Colors.white24),
        ),
        showCheckmark: false,
      ),
    );
  }
}

class TracksResult extends ConsumerWidget {
  final List<Track> tracks;
  final bool shrinkWrap;
  const TracksResult({
    super.key,
    required this.tracks,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tracks.isEmpty) {
      return const Center(
        child: Text('No tracks found', style: TextStyle(color: Colors.white)),
      );
    }

    final playerState = ref.watch(playerProvider);
    final isMiniPlayerVisible = playerState.currentTrack != null;

    return ListView.builder(
      padding: shrinkWrap
          ? EdgeInsets.zero
          : EdgeInsets.only(bottom: isMiniPlayerVisible ? 100 : 20),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final coverUrl = track.coverArtworks.isNotEmpty
            ? track.coverArtworks.first
            : "";
        return ListTile(
          onTap: () {
            ref.read(playerProvider.notifier).play([track], 0);
          },
          textColor: Colors.white,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Image.network(
              coverUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 50,
                height: 50,
                color: Colors.grey,
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track.artists.join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              ref.read(playerProvider.notifier).addToQueue(track);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${track.title} added to queue'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AlbumsResult extends ConsumerWidget {
  final List<Album> albums;
  final bool shrinkWrap;
  const AlbumsResult({
    super.key,
    required this.albums,
    this.shrinkWrap = false,
  });

  void playAlbum(Album album, WidgetRef ref) async {
    var response = await _api.getAlbumTracks(album.url);
    log(response.toString());
    if (response != null) {
      ref.read(playerProvider.notifier).play(response, 0);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (albums.isEmpty) {
      return const Center(
        child: Text('No albums found', style: TextStyle(color: Colors.white)),
      );
    }
    final playerState = ref.watch(playerProvider);
    final isMiniPlayerVisible = playerState.currentTrack != null;

    return ListView.builder(
      padding: shrinkWrap
          ? EdgeInsets.zero
          : EdgeInsets.only(bottom: isMiniPlayerVisible ? 100 : 20),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final coverUrl = album.coverArtworks.isNotEmpty
            ? album.coverArtworks.first
            : "";
        final artistName = album.artists.isNotEmpty
            ? album.artists.join(', ')
            : "Unknown Artist";

        return ListTile(
          onTap: () {
            playAlbum(album, ref);
          },
          textColor: Colors.white,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Image.network(
              coverUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.album, color: Colors.white),
            ),
          ),
          title: Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              ref.read(playerProvider.notifier).addAlbumToQueue(album);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${album.title} added to queue'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ArtistsResult extends ConsumerWidget {
  final List<Artist> artists;
  final bool shrinkWrap;
  const ArtistsResult({
    super.key,
    required this.artists,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (artists.isEmpty) {
      return const Center(
        child: Text('No artists found', style: TextStyle(color: Colors.white)),
      );
    }
    final playerState = ref.watch(playerProvider);
    final isMiniPlayerVisible = playerState.currentTrack != null;

    return ListView.builder(
      padding: shrinkWrap
          ? EdgeInsets.zero
          : EdgeInsets.only(bottom: isMiniPlayerVisible ? 100 : 20),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final pictureUrl = artist.pictures.isNotEmpty
            ? artist.pictures.first
            : "";

        return ListTile(
          textColor: Colors.white,
          leading: ClipOval(
            child: Image.network(
              pictureUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 50,
                height: 50,
                color: Colors.grey,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
          title: Text(
            artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

class HorizontalArtistsResult extends StatelessWidget {
  final List<Artist> artists;
  const HorizontalArtistsResult({super.key, required this.artists});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final pictureUrl = artist.pictures.isNotEmpty
            ? artist.pictures.first
            : "";

        return Padding(
          padding: const EdgeInsets.only(right: 15.0),
          child: Column(
            children: [
              ClipOval(
                child: Image.network(
                  pictureUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              SizedBox(
                width: 100,
                child: Text(
                  artist.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HorizontalAlbumsResult extends ConsumerWidget {
  final List<Album> albums;
  const HorizontalAlbumsResult({super.key, required this.albums});

  void playAlbum(Album album, WidgetRef ref) async {
    var response = await _api.getAlbumTracks(album.url);
    if (response != null) {
      ref.read(playerProvider.notifier).play(response, 0);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final coverUrl = album.coverArtworks.isNotEmpty
            ? album.coverArtworks[1]
            : "";
        final artistName = album.artists.isNotEmpty
            ? album.artists.join(', ')
            : "Unknown Artist";

        return GestureDetector(
          onTap: () => playAlbum(album, ref),
          child: Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    coverUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.album,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                SizedBox(
                  width: 120,
                  child: Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
