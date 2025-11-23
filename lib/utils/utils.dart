import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucida_player/models/music_item.dart';

class Debouncer {
  final Duration delay;
  Timer? _timer;
  Function? _callback;

  Debouncer({required this.delay});

  void run(Function callback) {
    _callback = callback;
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
    }
    _timer = Timer(delay, () {
      _callback?.call();
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}


// Initialize a single Dio instance for making HTTP requests
class DioConfig{

  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_URL'] ?? "",
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 15),
    )
  );

}


class APIClient {
  final dio = DioConfig().dio;

  Future<SearchResults?> search(String query) async {
    final response = await dio.get('/qobuz/search', queryParameters: {'query': query});
    if (response.statusCode != 200) {
      log('Search failed: ${response.statusCode}');
      return null;
    }
    if (response.data is Map<String, dynamic>) {
      return SearchResults.fromJson(response.data);
    } else {
      log('Unexpected API response format: ${response.data.runtimeType}');
      return null;
    }
  }


  Future<String?> getStreamUrl(String trackUrl) async {
    final response = await dio.get('/qobuz/stream',queryParameters: {'url': trackUrl});
    if (response.statusCode != 200) {
      log('Stream URL fetch failed: ${response.statusCode}');
      return null;
    }
    if (response.data is String) {
      return response.data;
    } else {
      log('Unexpected API response format: ${response.data.runtimeType}');
      return null;
    }
  }

  Future<List<Track>?> getAlbumTracks(String albumUrl) async {
    final response = await dio.get('/qobuz/album',queryParameters: {'url': albumUrl});
    if (response.statusCode != 200) {
      log('Album fetch failed: ${response.statusCode}');
      return null;
    }
    if (response.data is Map<String, dynamic>) {
      var tracksJson = response.data['tracks'] as List;
      var coverArtworks = response.data['metadata']['coverArtwork'] as List;
      var tracksList = tracksJson.map((track) => Track.fromJson(track, coverArtworks)).toList();
      return tracksList;
    } else {
      log('Unexpected API response format: ${response.data.runtimeType}');
      return null;
    }
  }


}