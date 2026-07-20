import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/storage/secure_storage.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final SecureStorage secureStorage;
  
  final _notificationController = StreamController<String>.broadcast();
  Stream<String> get notificationStream => _notificationController.stream;
  
  // Update this to your actual backend URL when testing on a real device
  final String serverUrl = "https://taskapi20260720153803-b0dwbgggbebrcwg9.eastasia-01.azurewebsites.net/hubs/notifications";

  SignalRService(this.secureStorage) {
    _initConnection();
  }

  void _initConnection() {
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, options: HttpConnectionOptions(
          accessTokenFactory: () async {
            final token = await secureStorage.getAccessToken();
            return token ?? "";
          },
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
      debugPrint("Received Notification via SignalR: $message");
      _notificationController.add(message);
    }
  }
}
