
class SearchResults {
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final bool? isEmpty;
  SearchResults({
    required this.tracks,
    required this.albums,
    required this.artists,
    this.isEmpty,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    var tracksJson = json['tracks'] as List;
    var albumsJson = json['albums'] as List;
    var artistsJson = json['artists'] as List;

    List<Track> tracksList =
        tracksJson.map((track) => Track.fromJson(track)).toList();
    List<Album> albumsList =
        albumsJson.map((album) => Album.fromJson(album)).toList();
    List<Artist> artistsList =
        artistsJson.map((artist) => Artist.fromJson(artist)).toList();

    return SearchResults(
      tracks: tracksList,
      albums: albumsList,
      artists: artistsList,
      isEmpty: tracksList.isEmpty && albumsList.isEmpty && artistsList.isEmpty,
    );
  }
}


class Track {
  final String title;
  final String id;
  final String url;
  final List<String> artists;
  final Duration? duration;
  final List<String> coverArtworks;

  Track({
    required this.title,
    required this.id,
    required this.url,
    required this.artists,
    this.duration,
    required this.coverArtworks
  });

  factory Track.fromJson(Map<String, dynamic> json, [List<dynamic>? coverArtworks]) {
    coverArtworks = coverArtworks ?? json['album']['coverArtwork'];

    return Track(
      title: json['title'],
      id: json['id'],
      url: json['url'],
      duration: json['durationMs'] != null
          ? Duration(milliseconds: (json['durationMs'] as num).toInt())
          : null,
      coverArtworks: ((coverArtworks != null && coverArtworks.isNotEmpty)
          ? coverArtworks.map<String>((x) => x['url'] as String).toList()
          : []),
      artists: (json['artists'] != null && (json['artists'] as List).isNotEmpty)
          ? json['artists'].map<String>((x) => x['name'] as String).toList()
          : [],
    );
  }

}

class Album {
  final String title;
  final String id;
  final String url;
  final List<String> coverArtworks;
  final List<String> artists;
  final List<Track>? tracks;

  Album({
    required this.title,
    required this.id,
    required this.url,
    required this.coverArtworks,
    required this.artists,
    this.tracks,
  });

  factory Album.fromJson(Map<String, dynamic> json, [List<Track>? tracks]) { 
    return Album(
      title: json['title'] ?? '',
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      coverArtworks: (json['coverArtwork'] != null && (json['coverArtwork'] as List).isNotEmpty)
          ? json['coverArtwork'].map<String>((x) => x['url'] as String).toList()
          : [],
      artists: (json['artists'] != null && (json['artists'] as List).isNotEmpty)
          ? json['artists'].map<String>((x) => x['name'] as String).toList()
          : [],
      tracks: tracks,
    );
  }
}


class Artist {
  final String name;
  final String id;
  final String url;
  final List<String> pictures;

  Artist({
    required this.name,
    required this.id,
    required this.url,
    required this.pictures,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      pictures: (json['pictures'] != null && (json['pictures'] as List).isNotEmpty)
          ? json['pictures'].map<String>((x) => x as String).toList()
          : [],
    );
  }
}