import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final String _tag = 'ConnectivityService';

  // Stream to broadcast connectivity changes
  StreamController<bool> connectionStatusController =
      StreamController<bool>.broadcast();

  ConnectivityService() {
    // Initial check
    _checkConnectivity();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      Logger.i(_tag, 'Connectivity changed: $results');
      _checkConnectivity();
    });
  }

  // Check current connectivity status
  Future<void> _checkConnectivity() async {
    bool isConnected = await isInternetAvailable();
    connectionStatusController.add(isConnected);
    Logger.i(_tag, 'Internet connection available: $isConnected');
  }

  // Check if internet is available
  Future<bool> isInternetAvailable() async {
    List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    Logger.d(_tag, 'Connectivity results: $results');
    return !results.contains(ConnectivityResult.none);
  }

  // Clean up when service is no longer needed
  void dispose() {
    connectionStatusController.close();
  }
}
