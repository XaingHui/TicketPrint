import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final double price;
  final String unit; // e.g., "斤", "个", "箱"
  final String? imagePath; // NEW: Image Path
  final int stockQuantity; // NEW: Stock Quantity

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    this.imagePath,
    this.stockQuantity = 0,
  });

  @override
  List<Object?> get props => [id, name, price, unit, imagePath, stockQuantity];
  
  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? unit,
    String? imagePath,
    int? stockQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }
}
