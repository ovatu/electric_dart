import 'package:electricsql/src/auth/auth.dart';
import 'package:electricsql/src/client/model/schema.dart';
import 'package:electricsql/src/config/config.dart';
import 'package:electricsql/src/electric/adapter.dart' hide Transaction;
import 'package:electricsql/src/migrators/migrators.dart';
import 'package:electricsql/src/notifiers/notifiers.dart';
import 'package:electricsql/src/satellite/process.dart';
import 'package:electricsql/src/satellite/shapes/types.dart';
import 'package:electricsql/src/sockets/sockets.dart';
import 'package:electricsql/src/util/types.dart';
import 'package:events_emitter/events_emitter.dart';

export 'package:electricsql/src/satellite/process.dart' show ShapeSubscription;

abstract class Registry {
  Map<DbName, Satellite> get satellites;

  Future<Satellite> ensureStarted({
    required DbName dbName,
    required DBSchema dbDescription,
    required DatabaseAdapter adapter,
    required Migrator migrator,
    required Notifier notifier,
    required SocketFactory socketFactory,
    required HydratedConfig config,
  });

  Future<Satellite> ensureAlreadyStarted(DbName dbName);

  Future<void> stop(DbName dbName);

  Future<void> stopAll();
}

class ConnectionWrapper {
  final Future<void> connectionFuture;

  ConnectionWrapper({
    required this.connectionFuture,
  });
}

abstract class Satellite {
  DbName get dbName;
  DatabaseAdapter get adapter;
  Migrator get migrator;
  Notifier get notifier;

  ConnectivityState? connectivityState;

  Future<ConnectionWrapper> start(AuthConfig authConfig);
  Future<void> stop({bool? shutdown});
  Future<ShapeSubscription> subscribe(
    List<ClientShapeDefinition> shapeDefinitions,
  );
  Future<void> unsubscribe(String shapeUuid);
}

abstract class Client {
  Future<void> connect();
  void disconnect();
  void shutdown();
  Future<AuthResponse> authenticate(
    AuthState authState,
  );
  bool isConnected();
  Future<StartReplicationResponse> startReplication(
    LSN? lsn,
    String? schemaVersion,
    List<String>? subscriptionIds,
  );
  Future<StopReplicationResponse> stopReplication();
  void subscribeToRelations(RelationCallback callback);
  void unsubscribeToRelations(EventListener<Relation> eventListener);
  void subscribeToTransactions(TransactionCallback callback);
  void unsubscribeToTransactions(EventListener<TransactionEvent> eventListener);
  void enqueueTransaction(
    DataTransaction transaction,
  );
  LSN getLastSentLsn();
  EventListener<void> subscribeToOutboundStarted(
    OutboundStartedCallback callback,
  );
  void unsubscribeToOutboundStarted(EventListener<LSN> eventListener);
  EventListener<SatelliteException> subscribeToError(ErrorCallback callback);
  void unsubscribeToError(EventListener<SatelliteException> eventListener);

  Future<SubscribeResponse> subscribe(
    String subscriptionId,
    List<ShapeRequest> shapes,
  );
  Future<UnsubscribeResponse> unsubscribe(List<String> subIds);

  SubscriptionEventListeners subscribeToSubscriptionEvents(
    SubscriptionDeliveredCallback successCallback,
    SubscriptionErrorCallback errorCallback,
  );
  void unsubscribeToSubscriptionEvents(SubscriptionEventListeners listeners);
}

class SubscriptionEventListeners {
  final EventListener<SubscriptionData> successEventListener;
  final EventListener<SubscriptionErrorData> errorEventListener;

  SubscriptionEventListeners({
    required this.successEventListener,
    required this.errorEventListener,
  });
}
