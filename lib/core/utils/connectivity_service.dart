import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();

  /// Factory constructor returns the singleton instance
  factory ConnectivityService() => _instance;

  /// Private constructor
  ConnectivityService._internal();

  // Core dependencies
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _internetChecker =
      InternetConnectionChecker();

  // Stream controller for broadcasting connection status
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // Subscriptions
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetConnectionStatus>? _internetSubscription;

  // Current connection status
  bool _isConnected = true;
  bool _isInitialized = false;

  /// Stream of connection status changes
  /// Emits true when connected, false when disconnected
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Current connection status (synchronous)
  /// Returns the last known connection state
  bool get hasConnection => _isConnected;

  /// Check if the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the connectivity service
  /// Call this once in main() or in your app initialization
  void initialize() {
    if (_isInitialized) {
      return; // Already initialized
    }

    _isInitialized = true;

    // Check initial connection status
    checkConnection();

    // Listen to connectivity changes (WiFi, Mobile, None)
    // Note: connectivity_plus now returns List<ConnectivityResult>
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Listen to actual internet connection status
    _internetSubscription = _internetChecker.onStatusChange.listen(
      _onInternetStatusChanged,
    );
  }

  /// Callback when connectivity type changes
  // ignore: unintended_html_in_doc_comment
  /// Now receives List<ConnectivityResult> instead of single result
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // If no connectivity at all
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _updateConnectionStatus(false);
    } else {
      // Has network, but check if there's actual internet
      checkConnection();
    }
  }

  /// Callback when internet connection status changes
  void _onInternetStatusChanged(InternetConnectionStatus status) {
    _updateConnectionStatus(status == InternetConnectionStatus.connected);
  }

  /// Check current connection status (async)
  /// Returns true if connected to internet, false otherwise
  ///
  /// This performs an actual internet connectivity check,
  /// not just network availability check
  Future<bool> checkConnection() async {
    try {
      // First check if device has any network connectivity
      final connectivityResults = await _connectivity.checkConnectivity();

      // Check if there's no connectivity
      if (connectivityResults.isEmpty ||
          connectivityResults.contains(ConnectivityResult.none)) {
        _updateConnectionStatus(false);
        return false;
      }

      // Network is available, now check actual internet connectivity
      final hasInternet = await _internetChecker.hasConnection;
      _updateConnectionStatus(hasInternet);
      return hasInternet;
    } catch (e) {
      // On error, assume no connection
      _updateConnectionStatus(false);
      return false;
    }
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(bool isConnected) {
    // Only notify if status actually changed
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionController.add(isConnected);
    }
  }

  /// Get the current connectivity type(s)
  // ignore: unintended_html_in_doc_comment
  /// Returns List<ConnectivityResult> (can have multiple: wifi, mobile, ethernet, etc.)
  Future<List<ConnectivityResult>> getConnectivityType() async {
    return await _connectivity.checkConnectivity();
  }

  /// Check if connected via WiFi
  Future<bool> isWiFi() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  /// Check if connected via Mobile Data
  Future<bool> isMobileData() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.mobile);
  }

  /// Check if connected via Ethernet
  Future<bool> isEthernet() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.ethernet);
  }

  /// Check if connected via VPN
  Future<bool> isVPN() async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.vpn);
  }

  /// Get all active connection types as a readable string
  Future<String> getConnectionTypesString() async {
    final results = await _connectivity.checkConnectivity();

    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return 'No Connection';
    }

    return results
        .where((result) => result != ConnectivityResult.none)
        .map((result) => result.name.toUpperCase())
        .join(', ');
  }

  /// Dispose the service and clean up resources
  /// Call this when app is closing (usually not needed)
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    _connectionController.close();
    _isInitialized = false;
  }

  /// Reset the service (useful for testing)
  void reset() {
    dispose();
    _isConnected = true;
    _isInitialized = false;
  }
}

/// Extension to get connectivity service easily
extension ConnectivityContext on Object {
  ConnectivityService get connectivity => ConnectivityService();
}
