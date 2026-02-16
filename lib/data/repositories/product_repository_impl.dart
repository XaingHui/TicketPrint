import 'package:drift/drift.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../database.dart';

class ProductRepositoryImpl implements IProductRepository {
  final AppDatabase _db;

  ProductRepositoryImpl(this._db);

  @override
  Future<List<Product>> getProducts() async {
    final query = _db.select(_db.productsTable)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
      
    final products = await query.get();
    
    return products.map((p) => Product(
      id: p.id,
      name: p.name,
      price: p.price,
      unit: p.unit,
      imagePath: p.imagePath,
    )).toList();
  }

  @override
  Future<void> addProduct(Product product) async {
    await _db.into(_db.productsTable).insert(
      ProductsTableCompanion.insert(
        id: product.id,
        name: product.name,
        price: product.price,
        unit: product.unit,
        imagePath: Value(product.imagePath),
      ),
    );
  }

  @override
  Future<void> updateProduct(Product product) async {
    await (_db.update(_db.productsTable)..where((t) => t.id.equals(product.id))).write(
      ProductsTableCompanion(
        name: Value(product.name),
        price: Value(product.price),
        unit: Value(product.unit),
        imagePath: Value(product.imagePath),
      ),
    );
  }

  @override
  Future<void> deleteProduct(String id) async {
     await (_db.delete(_db.productsTable)..where((t) => t.id.equals(id))).go();
  }
}
