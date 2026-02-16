import 'package:drift/drift.dart';

class InvoicesTable extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get targetName => text().nullable()(); // NEW: Customer Name
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))(); // NEW: Discount
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

class InvoiceItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceId => text().references(InvoicesTable, #id)(); // Foreign Key
  TextColumn get productName => text()();
  RealColumn get price => real()();
  TextColumn get unit => text()();
  RealColumn get quantity => real()();
}

class CustomersTable extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

class ProductsTable extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get name => text()();
  RealColumn get price => real()();
  TextColumn get unit => text()();
  TextColumn get imagePath => text().nullable()(); // NEW: Image Path
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))(); // NEW: Stock Quantity
  TextColumn get category => text().nullable()(); // Optional category
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}
