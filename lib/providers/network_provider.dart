import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provider to manage network connectivity status
class NetworkProvider extends ChangeNotifier {
  bool _isOnline = true;
  
  NetworkProvider() {
    // Initialize connectivity check
    checkConnectivity();
    
    // Listen to connectivity changes (may not work reliably on web)
    if (!kIsWeb) {
      Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    } else {
      // For web, always assume online since browser handles network status
      _isOnline = true;
    }
  }
  
  bool get isOnline => _isOnline;
  
  Future<void> checkConnectivity() async {
    try {
      // For web, always assume online since browser handles network
      if (kIsWeb) {
        _isOnline = true;
        notifyListeners();
        return;
      }
      
      final ConnectivityResult result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = true; // Default to online if we can't check
      notifyListeners();
    }
  }
  
  void _updateConnectionStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      _isOnline = false;
    } else {
      _isOnline = true;
    }
    notifyListeners();
  }

  /// Manually check connectivity status
  Future<void> checkConnection() async {
    await checkConnectivity();
  }
} 