import 'package:drift/drift.dart';
import 'package:electric_client/drivers/drift.dart';
import 'package:electric_client/electric_client.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todos_electrified/generated/electric_migrations.dart';

final Provider<ElectricClient> electricClientProvider =
    Provider((ref) => throw UnimplementedError());

final connectivityStateControllerProvider =
    ChangeNotifierProvider<ConnectivityStateController>(
        (ref) => throw UnimplementedError());

Future<ElectricClient> startElectricDrift(
  String dbName,
  DatabaseConnectionUser db,
) async {
  final namespace = await electrify(
    dbName: dbName,
    db: db,
    migrations: kElectricMigrations,
    config: ElectricConfig(
      auth: AuthConfig(
        //token:
        //    'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJsb2NhbC1kZXZlbG9wbWVudCIsInR5cGUiOiJhY2Nlc3MiLCJ1c2VyX2lkIjoidGVzdC11c2VyIiwiaWF0IjoxNjg3ODc3OTQ1LCJleHAiOjE2OTc4ODE1NDV9.L5Ui2sA9o5MeYDuy67u9lBV-2FzpOWL9dKcitRvgorg',
        token: await authToken(iss: 'local-development', key: 'local-development-key-minimum-32-symbols'),
      ),
      debug: true,
    ),
  );

  return namespace;
}

class ConnectivityStateController with ChangeNotifier {
  final ElectricClient electric;

  ConnectivityState _connectivityState = ConnectivityState.disconnected;
  ConnectivityState get connectivityState => _connectivityState;

  String? _connectivityChangeSubscriptionId;

  ConnectivityStateController(this.electric);

  void init() {
    setConnectivityState(electric.isConnected
        ? ConnectivityState.connected
        : ConnectivityState.disconnected);

    void handler(ConnectivityStateChangeNotification notification) {
      final state = notification.connectivityState;

      // externally map states to disconnected/connected
      final found = <ConnectivityState?>[
        ConnectivityState.available,
        ConnectivityState.error,
        ConnectivityState.disconnected
      ].firstWhere(
        (x) => x == state,
        orElse: () => null,
      );
      final nextState = found != null
          ? ConnectivityState.disconnected
          : ConnectivityState.connected;
      setConnectivityState(nextState);
    }

    _connectivityChangeSubscriptionId =
        electric.notifier.subscribeToConnectivityStateChanges(handler);
  }

  @override
  void dispose() {
    if (_connectivityChangeSubscriptionId != null) {
      electric.notifier.unsubscribeFromConnectivityStateChanges(
        _connectivityChangeSubscriptionId!,
      );
    }
    super.dispose();
  }

  void toggleConnectivityState() {
    final ConnectivityState nextState =
        _connectivityState == ConnectivityState.connected
            ? ConnectivityState.disconnected
            : ConnectivityState.available;
    final dbName = electric.notifier.dbName;
    electric.notifier.connectivityStateChanged(dbName, nextState);

    setConnectivityState(nextState);
  }

  void setConnectivityState(ConnectivityState state) {
    _connectivityState = state;
    notifyListeners();
  }
}
