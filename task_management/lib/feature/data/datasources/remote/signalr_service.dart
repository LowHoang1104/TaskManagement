import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/constants/api_endpoints.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final SecureStorage secureStorage;
  
  final _notificationController = StreamController<String>.broadcast();
  Stream<String> get notificationStream => _notificationController.stream;

  final _projectRefreshController = StreamController<String>.broadcast();
  Stream<String> get projectRefreshStream => _projectRefreshController.stream;

  final _workspaceRefreshController = StreamController<String>.broadcast();
  Stream<String> get workspaceRefreshStream => _workspaceRefreshController.stream;
  
  // Construct the SignalR hub URL dynamically based on kBaseUrl
  final String serverUrl = "${kBaseUrl.replaceAll('/api', '')}/hubs/notifications";

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
    _hubConnection?.on("RefreshProject", _handleRefreshProject);
    _hubConnection?.on("RefreshWorkspace", _handleRefreshWorkspace);
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

  void _handleRefreshProject(List<Object?>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      final projectId = arguments[0] as String;
      debugPrint("Received RefreshProject for $projectId");
      _projectRefreshController.add(projectId);
    }
  }

  void _handleRefreshWorkspace(List<Object?>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      final workspaceId = arguments[0] as String;
      debugPrint("Received RefreshWorkspace for $workspaceId");
      _workspaceRefreshController.add(workspaceId);
    }
  }
}
