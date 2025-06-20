import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../services/api_client.dart';
import '../utils/logger.dart';

/// Simple in-memory cache for authenticated images
class _ImageCache {
  static final Map<String, Uint8List> _cache = {};
  static const int maxCacheSize =
      50; // Limit cache size to prevent memory issues

  static Uint8List? get(String url) {
    return _cache[url];
  }

  static void set(String url, Uint8List data) {
    // Simple LRU-like behavior: remove oldest entries if cache is full
    if (_cache.length >= maxCacheSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    _cache[url] = data;
  }

  static void clear() {
    _cache.clear();
  }

  static int get size => _cache.length;
}

/// Custom widget for loading images with authentication headers
class AuthenticatedImage extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final Widget placeholder;
  final Widget errorWidget;
  final VoidCallback? onImageLoaded;
  final Function(String)? onImageError;
  final bool enableCache;

  const AuthenticatedImage({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.width,
    required this.fit,
    required this.placeholder,
    required this.errorWidget,
    this.onImageLoaded,
    this.onImageError,
    this.enableCache = true,
  });

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  late Future<Uint8List> _imageFuture;
  final String _tag = 'AuthenticatedImage';

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImageData();
  }

  Future<Uint8List> _loadImageData() async {
    // Check cache first if enabled
    if (widget.enableCache) {
      final cachedData = _ImageCache.get(widget.imageUrl);
      if (cachedData != null) {
        widget.onImageLoaded?.call();
        return cachedData;
      }
    }

    try {
      final response = await ApiClient.instance.get(widget.imageUrl);

      if (response.statusCode == 200) {
        final responseBody = response.body;
        Uint8List imageBytes;

        // Try to decode as base64 first (backend returns base64-encoded data)
        try {
          imageBytes = base64Decode(responseBody);
        } catch (base64Error) {
          // If base64 decoding fails, try using raw bytes
          Logger.w(
            _tag,
            'Base64 decoding failed, using raw bytes: $base64Error',
          );
          imageBytes = response.bodyBytes;
        }

        if (imageBytes.isEmpty) {
          throw Exception('Received empty image data');
        }

        // Cache the successful result if enabled
        if (widget.enableCache) {
          _ImageCache.set(widget.imageUrl, imageBytes);
        }

        widget.onImageLoaded?.call();
        return imageBytes;
      } else {
        final errorMsg =
            'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        Logger.e(_tag, 'Failed to load image: $errorMsg');
        widget.onImageError?.call(errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading authenticated image', error: e);
      widget.onImageError?.call(e.toString());
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: FutureBuilder<Uint8List>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return widget.placeholder;
          } else if (snapshot.hasError) {
            return widget.errorWidget;
          } else if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              height: widget.height,
              width: widget.width,
              fit: widget.fit,
              errorBuilder: (context, error, stackTrace) {
                Logger.e(
                  _tag,
                  'Error displaying image from memory',
                  error: error,
                );
                widget.onImageError?.call(error.toString());
                return widget.errorWidget;
              },
            );
          } else {
            return widget.errorWidget;
          }
        },
      ),
    );
  }
}
