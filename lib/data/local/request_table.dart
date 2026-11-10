import 'package:drift/drift.dart';

@DataClassName('RequestRow')
class Requests extends Table {
  TextColumn get id => text()();
  TextColumn get serviceId => text()();
  TextColumn get requesterId => text()();
  TextColumn get description => text()();

  TextColumn get status => text().withDefault(const Constant('requested'))();
  IntColumn get progress => integer().withDefault(const Constant(0))();

  TextColumn get approverId => text().nullable()();
  TextColumn get executorId => text().nullable()();
  TextColumn get priority => text().nullable()();
  DateTimeColumn get limitDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get lastSyncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
