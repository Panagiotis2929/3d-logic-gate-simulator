import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/simulation_state.dart';

// ─────────────────────────────────────────────
//  WebSocket URL helper
// ─────────────────────────────────────────────
String get _wsUrl {
  // On web: auto-detect host; on mobile: point to local dev server.
  if (kIsWeb) {
    final host = Uri.base.host;
    final port = Uri.base.port == 0 ? 8080 : Uri.base.port;
    return 'ws://$host:$port/ws';
  }
  return 'ws://localhost:8080/ws'; // Android emulator: 10.0.2.2:8080
}

// ─────────────────────────────────────────────
//  Riverpod providers
// ─────────────────────────────────────────────
final websocketServiceProvider =
    Provider<WebSocketService>((ref) => WebSocketService());

final simulationStateProvider =
    StateNotifierProvider<SimulationStateNotifier, SimulationState>(
  (ref) {
    final service = ref.watch(websocketServiceProvider);
    return SimulationStateNotifier(service);
  },
);

// ─────────────────────────────────────────────
//  WebSocketService
// ─────────────────────────────────────────────
class WebSocketService {
  WebSocketChannel? _channel;
  final _stateController = StreamController<SimulationState>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  Stream<SimulationState> get stateStream => _stateController.stream;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  Timer? _reconnectTimer;

  // ── Lifecycle ──────────────────────────────

  void connect() {
    _setStatus(ConnectionStatus.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _setStatus(ConnectionStatus.connected);
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      debugPrint('WebSocket connect error: $e');
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _statusController.close();
  }

  // ── Outbound commands ──────────────────────

  void send(Map<String, dynamic> message) {
    if (_channel == null || _status != ConnectionStatus.connected) {
      debugPrint('Cannot send: not connected');
      return;
    }
    _channel!.sink.add(jsonEncode(message));
  }

  void addGate(String gateType, double x, double y, double z) {
    send({
      'type': 'ADD_GATE',
      'payload': {
        'gateType': gateType,
        'position': {'x': x, 'y': y, 'z': z},
      },
    });
  }

  void removeGate(String gateId) {
    send({'type': 'REMOVE_GATE', 'payload': {'gateId': gateId}});
  }

  void setInput(String gateId, int inputIdx, bool value) {
    send({
      'type': 'SET_INPUT',
      'payload': {
        'gateId': gateId,
        'inputIdx': inputIdx,
        'value': value,
      },
    });
  }

  void addWire(String fromGateId, String toGateId, int toInputIdx) {
    send({
      'type': 'ADD_WIRE',
      'payload': {
        'fromGateId': fromGateId,
        'toGateId': toGateId,
        'toInputIdx': toInputIdx,
      },
    });
  }

  void removeWire(String wireId) {
    send({'type': 'REMOVE_WIRE', 'payload': {'wireId': wireId}});
  }

  void addCube(double x, double y, double z, {String color = '#00E5FF'}) {
    send({
      'type': 'ADD_CUBE',
      'payload': {
        'position': {'x': x, 'y': y, 'z': z},
        'color': color,
      },
    });
  }

  void reset() {
    send({'type': 'RESET', 'payload': null});
  }

  // ── Internal ───────────────────────────────

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['type'] == 'STATE_UPDATE') {
        final state = SimulationState.fromJson(
          json['payload'] as Map<String, dynamic>,
        );
        _stateController.add(state);
      }
    } catch (e) {
      debugPrint('Parse error: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('WebSocket error: $error');
    _setStatus(ConnectionStatus.error);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WebSocket closed');
    _setStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), connect);
  }

  void _setStatus(ConnectionStatus s) {
    _status = s;
    _statusController.add(s);
  }
}

// ─────────────────────────────────────────────
//  State Notifier
// ─────────────────────────────────────────────
class SimulationStateNotifier extends StateNotifier<SimulationState> {
  final WebSocketService _service;
  late final StreamSubscription<SimulationState> _sub;

  SimulationStateNotifier(this._service)
      : super(SimulationState.empty()) {
    _service.connect();
    _sub = _service.stateStream.listen((s) => state = s);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
//  Connection status enum
// ─────────────────────────────────────────────
enum ConnectionStatus { disconnected, connecting, connected, error }
