import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';

class SignalRService {
  HubConnection? _hubConnection;
  
  // Update this to your actual backend URL when testing on a real device
  final String serverUrl = "http://localhost:5058/hubs/notifications"; // Web / localhost

  SignalRService() {
    _initConnection();
  }

  void _initConnection() {
    // TODO: Add JWT Token to options once Auth is implemented in Frontend
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, options: HttpConnectionOptions(
          // accessTokenFactory: () async => await secureStorage.getToken(),
        ))
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose(({error}) {
      debugPrint("SignalR Connection Closed: $error");
    });

    _hubConnection?.on("ReceiveNotification", _handleIncomingNotification);
  }

  Future<void> startConnection() async {
    if (_hubConnection?.state == HubConnectionState.Disconnected) {
      try {
        await _hubConnection?.start();
        debugPrint("SignalR Connected!");
      } catch (e) {
        debugPrint("Error starting SignalR: $e");
      }
    }
  }

  Future<void> stopConnection() async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.stop();
    }
  }

  void _handleIncomingNotification(List<Object?>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      final message = arguments[0] as String;
      debugPrint("Received Notification: $message");
      // TODO: Use Riverpod or local notifications to display this to the user
    }
  }
}
